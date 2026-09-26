import http from 'k6/http';
import {check, fail} from 'k6';
import exec from 'k6/execution';
import {Counter, Trend} from 'k6/metrics';
import {SharedArray} from 'k6/data';
import crypto from 'k6/crypto';
import * as c from './contracts.mjs';

const profile = JSON.parse(open(__ENV.SOAK_PROFILE));
const w = profile.workload;
const coverageRepeats = w.coverageRepeats ?? 1;
c.invariant(Number.isInteger(coverageRepeats) && coverageRepeats >= 1 && coverageRepeats <= 4, 'coverage repeats must be an integer from 1 through 4');
const reportSizes = w.reportSizes ?? [100, 500, 1000];
c.invariant(Array.isArray(reportSizes) && reportSizes.length === 3 && reportSizes.every((size, i) =>
    Number.isInteger(size) && [25, 50, 100, 250, 500, 1000].includes(size) && (i === 0 || size > reportSizes[i - 1])),
    'report sizes must be three distinct ascending supported row limits');
const fixtureRows = new SharedArray('post-fixtures', () => {
    const f = JSON.parse(open(__ENV.SOAK_FIXTURES));
    return Array.from({length: 10000}, (_, i) => ({comments: f.postCommentCounts[String(i+1)], tags: f.postTags[String(i+1)]}));
});
const fixtureMeta = new SharedArray('fixture-checksums', () => [JSON.parse(open(__ENV.SOAK_FIXTURES)).reportChecksums])[0];
const started = new Counter('journey_started');
const completed = new Counter('journey_completed');
const unexpected = new Counter('unexpected_errors');
const attempted = new Counter('expected_failure_attempted');
const verified = new Counter('expected_failure_verified');
const recovered = new Counter('followup_succeeded');
const successfulLatency = new Trend('successful_latency', true);
const expectedLatency = new Trend('expected_failure_latency', true);
const duration = new Trend('journey_duration', true);
const operation = new Counter('operation_completed');
const samples = new Counter('bucket_completed');
const cases = ['missing_pk', 'empty_lookup', 'relationship', 'invalid_write', 'rollback'];

const base = {exec: 'mixedJourney', preAllocatedVUs: w.vus, maxVUs: w.vus, gracefulStop: `${w.drainSeconds}s`};
export const options = {
    discardResponseBodies: false,
    maxRedirects: 0,
    noCookiesReset: false,
    systemTags: ['status', 'method', 'name', 'scenario', 'expected_response', 'error_code'],
    scenarios: {
        warmup: {...base, executor: 'constant-arrival-rate', rate: w.rate, timeUnit: '10s', duration: `${w.warmupSeconds}s`},
        ramp: {...base, executor: 'ramping-arrival-rate', startTime: `${w.warmupSeconds}s`, startRate: w.rate, timeUnit: '10s',
            stages: [{duration: `${w.rampSeconds}s`, target: w.rate * 10}]},
        plateau: {...base, executor: 'constant-arrival-rate', startTime: `${w.warmupSeconds+w.rampSeconds}s`,
            rate: w.rate, timeUnit: '1s', duration: `${w.plateauSeconds}s`},
        recovery: {...base, executor: 'constant-arrival-rate', startTime: `${w.warmupSeconds+w.rampSeconds+w.plateauSeconds}s`,
            rate: w.rate, timeUnit: '10s', duration: `${w.recoverySeconds}s`},
    },
    thresholds: {
        checks: [{threshold: 'rate==1', abortOnFail: true}],
        http_req_failed: [{threshold: 'rate==0', abortOnFail: true}],
        unexpected_errors: [{threshold: 'count==0', abortOnFail: true}],
        'dropped_iterations{scenario:plateau}': ['count==0'],
    },
    summaryTrendStats: ['count', 'avg', 'min', 'max', 'p(95)', 'p(99)'],
};
// Capacity probes keep the application/collector alive between stages while
// using one bounded arrival-rate generator invocation for each rate decision.
if (profile.mode === 'capacity-warmup') {
    options.scenarios = {warmup: options.scenarios.warmup};
    delete options.thresholds['dropped_iterations{scenario:plateau}'];
    options.thresholds['dropped_iterations{scenario:warmup}'] = ['count==0'];
} else if (profile.mode === 'capacity-step') {
    options.scenarios = {plateau: {...options.scenarios.plateau, startTime: '0s'}};
}
if (!w.shortDevelopment && profile.mode !== 'capacity-warmup') {
    for (const name of cases) options.thresholds[`expected_failure_verified{case:${name},scenario:plateau}`] = [`count>=${w.minimumFailuresPerCase}`];
}

let errorSamples = 0;
function bad(message, tags) {
    unexpected.add(1, tags);
    check(false, {'contract correct': v => v}, tags);
    if (errorSamples++ < 2) console.error(JSON.stringify({message: String(message).slice(0, 500), operation: tags.operation,
        scenario: exec.scenario.name, iteration: exec.scenario.iterationInTest}));
    fail(String(message));
}
function request(method, path, name, validate, status = 200, body = null, failureCase = '') {
    const tags = {name, operation: name, case: failureCase || 'success'};
    const response = http.request(method, __ENV.SOAK_URL + path, body === null ? null : JSON.stringify(body), {
        headers: {'X-Soak-Token': __ENV.SOAK_TOKEN, 'Content-Type': 'application/json'},
        timeout: `${w.requestTimeoutSeconds}s`, redirects: 0, tags,
        // Classification is local to this one request. Body assertions remain independent.
        responseCallback: http.expectedStatuses(status),
    });
    try {
        const value = c.response(response, name, status, validate);
        check(true, {'contract correct': v => v}, tags);
        operation.add(1, tags);
        (failureCase ? expectedLatency : successfulLatency).add(response.timings.duration, tags);
        return value;
    } catch (error) { bad(error.message, tags); }
}
function detail(id) { return request('GET', `/api/users/${id}`, 'user_detail', b => c.detail(b, id)); }
function missing(path, name, caseName, method = 'GET', body = null) {
    attempted.add(1, {case: caseName});
    return request(method, path, name, (b, r) => c.missing(r.status, b), 404, body, caseName);
}
function scratch(token, expected = 0) {
    return request('GET', `/api/scratch/${token}`, 'scratch_verify', b => c.scratch(b, expected));
}
function write(token) {
    const body = {ownerToken: token, title: 'created'};
    const created = request('POST', '/api/posts', 'post_create', b => c.written(b, token, 'created', 1), 201, body).data;
    const path = `/api/posts/${created.id}?token=${token}`;
    const stored = request('GET', path, 'post_read', b => {
        c.written(b, token, 'created', 1, created.id);
        c.invariant(c.equal(b.data.tags.map(t => t.id).sort((a,b) => a-b), [1,2]), 'committed pivot values');
    }).data;
    request('PATCH', path, 'post_update', b => c.written(b, token, 'updated', 2, created.id), 200, {...body, title: 'updated'});
    request('GET', path, 'post_read_updated', b => {
        c.written(b, token, 'updated', 2, created.id);
        c.invariant(b.data.createdAt === stored.createdAt && b.data.updatedAt >= stored.updatedAt, 'timestamp lifecycle');
    });
    request('DELETE', path, 'post_delete', b => c.invariant(c.keys(b, ['deleted']) && b.deleted === true, 'delete contract'));
    request('GET', path, 'post_deleted', (b, r) => c.missing(r.status, b), 404, null, 'post_delete');
    scratch(token);
}

export function setup() {
    unexpected.add(0);
    const ready = http.get(__ENV.SOAK_URL + '/health/ready', {headers: {'X-Soak-Token': __ENV.SOAK_TOKEN},
        timeout: `${w.requestTimeoutSeconds}s`, tags: {name: 'ready'}, responseCallback: http.expectedStatuses(200)});
    c.invariant(ready.status === 200 && ready.json().ready === true, 'application not ready');
    return {bootId: ready.json().bootId};
}

export function mixedJourney() {
    const n = exec.scenario.iterationInTest;
    // Bijective permutation guarantees the declared mix in each complete block of 100 starts.
    const slot = (n * 37 + w.seed) % 100;
    let state = (Math.imul(n + w.seed, 1664525) + 1013904223) >>> 0;
    function pick(max) { state = (Math.imul(state, 1664525) + 1013904223) >>> 0; return Math.floor(state / 4294967296 * max); }
    const token = `${__ENV.SOAK_RUN_ID}_${exec.scenario.name}_${n}`;
    const journey = slot < 25 ? 'browse' : slot < 40 ? 'detail' : slot < 55 ? 'graph' : slot < 65 ? 'write'
        : slot < 75 ? 'report' : slot < 80 ? 'variant' : cases[Math.floor((slot - 80) / 4)];
    // Four bounded epoch values let the analyzer use actual scenario clocks,
    // independent of image pulls, setup, and container launch delays.
    started.add(1, {journey, phaseStart: String(exec.scenario.startTime)});
    const begin = Date.now();
    if (journey === 'browse') {
        const input = {team: pick(21), limit: pick(2) ? 100 : 25, page: 1 + pick(2), nullable: pick(2) === 1, descending: pick(2) === 1};
        request('GET', `/api/users?team=${input.team}&limit=${input.limit}&page=${input.page}&nullable=${input.nullable}&descending=${input.descending}`,
            'browse', b => c.browse(b, input));
        samples.add(1, {bucket: `browse_${input.limit}`});
    } else if (journey === 'detail') {
        detail([1, 3, 28, 117, 524, 999, 1000][pick(7)]);
    } else if (journey === 'graph') {
        const start = [1, 199, 503, 1298, 9996][pick(5)];
        const f = {postCommentCounts: {}, postTags: {}};
        for (let id = start; id < start + 5; id++) {
            const row = fixtureRows[id - 1]; f.postCommentCounts[String(id)] = row.comments; f.postTags[String(id)] = row.tags;
        }
        request('GET', `/api/posts?start=${start}`, 'graph', b => c.graph(b, start, f));
    } else if (journey === 'write') {
        write(token);
    } else if (journey === 'report') {
        const limit = reportSizes[(Math.floor(n / 100) * 10 + slot - 65) % reportSizes.length];
        for (let repeat = 0; repeat < coverageRepeats; repeat++) {
            request('GET', `/api/reports/posts?limit=${limit}`, `report_${limit}`,
                (b, r) => c.report(b, limit, r.body.length, {reportChecksums: fixtureMeta}, v => crypto.sha256(v, 'hex')));
            samples.add(1, {bucket: `report_${limit}`});
        }
    } else if (journey === 'variant') {
        const variant = (Math.floor(n / 100) * 5 + slot - 75) % 32;
        for (let repeat = 0; repeat < coverageRepeats; repeat++) {
            request('GET', `/api/query-variants/${variant}`, 'query_variant', b => c.variant(b, variant));
            samples.add(1, {bucket: `variant_${variant}`});
        }
    } else {
        for (let repeat = 0; repeat < coverageRepeats; repeat++) {
            const repeatToken = `${token}_${repeat}`;
            if (journey === 'missing_pk') {
                missing(`/api/users/${2000000000 + pick(10000)}`, 'missing_pk', journey);
                detail(3);
            } else if (journey === 'empty_lookup') {
                missing(`/api/users/lookup?message=${['default', 'custom', 'callback'][pick(3)]}`, 'empty_lookup', journey);
                request('GET', '/api/users/lookup?email=user-3@example.invalid', 'lookup_recovery', b => c.user(b.data, 3));
            } else if (journey === 'relationship') {
                missing(pick(2) ? '/api/users/2/posts/1' : '/api/users/1/posts/2000000000', 'relationship_missing', journey);
                request('GET', '/api/users/1/posts/1', 'relationship_recovery', b => c.post(b.data, 1));
            } else if (journey === 'invalid_write') {
                attempted.add(1, {case: journey});
                request('POST', '/api/posts', 'invalid_write', (b,r) => c.invalid(r.status, b), 422, {ownerToken: repeatToken, title: ''}, journey);
                scratch(repeatToken);
                write(repeatToken);
            } else if (journey === 'rollback') {
                missing('/api/transactions/rollback', 'rollback', journey, 'POST', {ownerToken: repeatToken, title: 'rollback'});
                scratch(repeatToken);
                write(repeatToken);
            }
            // Count verification only after persistence assertions and the recovery sequence succeed.
            verified.add(1, {case: journey});
            recovered.add(1, {case: journey});
        }
    }
    completed.add(1, {journey});
    duration.add(Date.now() - begin, {journey});
}

export function teardown(data) {
    request('GET', '/diagnostics', 'final_diagnostics', b => {
        c.invariant(b.bootId === data.bootId && b.applicationStarts === 1, 'application restarted');
        c.invariant(b.scratchPosts === 0, 'scratch cleanup failed');
    });
}
export function handleSummary(data) { return { [__ENV.SOAK_SUMMARY]: JSON.stringify(data, null, 2) }; }
