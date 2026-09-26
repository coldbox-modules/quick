// Real HTTP/threshold proof for the same response validators used by the load.
import http from 'k6/http';
import {check} from 'k6';
import * as c from './contracts.mjs';
export const options = {vus: 1, iterations: 1, thresholds: {checks: ['rate==1'], http_req_failed: ['rate==0']}};
export default function () {
    const status = __ENV.CASE.startsWith('invalid') ? 422 : 404;
    const result = http.get(`${__ENV.PROBE_URL}/${__ENV.CASE}`, {responseCallback: http.expectedStatuses(status)});
    let correct = true;
    try {
        c.response(result, 'probe', status, (body, r) => (status === 422 ? c.invalid : c.missing)(r.status, body));
    } catch (_) { correct = false; }
    check(correct, {'exact response contract': value => value});
}
export function handleSummary(data) { return {[__ENV.PROBE_SUMMARY]: JSON.stringify(data, null, 2)}; }
