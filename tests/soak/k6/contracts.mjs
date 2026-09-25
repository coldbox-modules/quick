// Pure validators are shared by the real k6 workload and negative contract tests.
// They inspect values and ownership, not only response statuses.
export function invariant(condition, message) {
    if (!condition) throw new Error(message);
}
export function equal(a, b) { return JSON.stringify(a) === JSON.stringify(b); }
export function keys(value, expected) {
    return value && equal(Object.keys(value).sort(), expected.slice().sort());
}
export function response(response, name, status, validate) {
    invariant(response.status === status, `${name}: expected ${status}, got ${response.status}`);
    invariant((response.headers['Content-Type'] || '').includes('application/json'), `${name}: content type`);
    const value = response.json();
    validate(value, response);
    return value;
}
export function owner(id) { return id <= 200 ? 1 : 2 + (id - 201) % 997; }
export function missing(status, body) {
    invariant(status === 404 && keys(body, ['error']) && keys(body.error, ['code', 'type'])
        && body.error.code === 'EntityNotFound' && body.error.type === 'EntityNotFound', 'EntityNotFound contract');
}
export function invalid(status, body) {
    invariant(status === 422 && keys(body, ['error']) && keys(body.error, ['code', 'fields'])
        && body.error.code === 'ValidationFailed' && keys(body.error.fields, ['title'])
        && body.error.fields.title === 'required,maximum:80', 'ValidationFailed contract');
}
export function user(u, id) {
    invariant(u && u.id === id && u.teamId === 1 + (id - 1) % 20, 'user identity/team');
    invariant(u.displayName === `user-${String(id).padStart(4, '0')}` && !('secret' in u), 'user fields');
    invariant(equal(u.profile, {level: id % 7}), 'custom user cast');
    invariant(u.nickname === (id % 3 === 0 ? null : `nick-${id}`), 'nullable user field');
}
export function post(p, id) {
    invariant(p && p.id === id && p.userId === owner(id), 'post identity/owner');
    invariant(p.title === `post-${String(id).padStart(5, '0')}`, 'post fixture title');
    invariant(p.summary === (id % 3 === 0 ? null : `summary-${id}`), 'nullable post field');
}
export function detail(body, id) {
    const u = body.data;
    user(u, id);
    invariant(u.team && u.team.id === u.teamId && u.team.name === `team-${String(u.teamId).padStart(2, '0')}`, 'detail team');
    const ids = [];
    for (let i = 10000; i > 0 && ids.length < 5; i--) if (owner(i) === id) ids.push(i);
    invariant(equal(u.posts.map(p => p.id), ids), 'bounded recent-post ordering/count');
    for (const p of u.posts) post(p, p.id);
}
export function browse(body, {team, limit, page, nullable, descending}) {
    let ids = [];
    for (let i = 1; i <= 1000; i++) {
        if ((team === 0 || 1 + (i - 1) % 20 === team) && (!nullable || i % 3 === 0)) ids.push(i);
    }
    if (descending) ids.reverse();
    ids = ids.slice((page - 1) * limit, page * limit);
    invariant(body.page === page && body.limit === limit && equal(body.data.map(u => u.id), ids),
        `browse page/filter/order: ${JSON.stringify({expected: {page, limit, ids}, actual: {page: body.page, limit: body.limit, ids: body.data.map(u => u.id)}})}`);
    body.data.forEach((u, i) => user(u, ids[i]));
}
export function graph(body, start, fixture) {
    invariant(body.data.length === 5, 'graph row count');
    body.data.forEach((p, offset) => {
        post(p, start + offset);
        user(p.author, p.userId);
        invariant(p.comments.length === fixture.postCommentCounts[String(p.id)], 'graph comment count');
        for (const c of p.comments) {
            invariant(c.commentableType === 'Post' && c.commentableId === p.id, 'polymorphic comment owner');
            invariant(c.body === `comment-${String(c.id).padStart(5, '0')}` && c.userId === 1 + (c.id - 1) % 1000, 'comment fixture');
            user(c.author, c.userId);
        }
        invariant(equal(p.tags.map(t => t.id).sort((a,b) => a-b), fixture.postTags[String(p.id)].slice().sort((a,b) => a-b)), 'graph pivots');
        p.tags.forEach(t => invariant(t.name === `tag-${String(t.id).padStart(3, '0')}`, 'tag fixture'));
    });
}
export function report(body, limit, byteCount, fixture, checksum) {
    invariant(body.data.length === limit && byteCount >= limit * 40 && byteCount <= limit * 200, 'report rows/payload bound');
    body.data.forEach((p, i) => {
        invariant(keys(p, ['id', 'userId', 'title', 'summary']), 'report projection');
        post(p, i + 1);
    });
    const canonical = body.data.map(p => `${p.id}:${p.userId}:${p.title}`).join('|');
    invariant(checksum(canonical) === body.checksum && body.checksum === fixture.reportChecksums[String(limit)], 'report checksum');
}
export function variant(body, value) {
    const id = value + 1;
    const projection = ['id', 'displayName', 'nickname'];
    if (value % 2) projection.push('teamId');
    invariant(keys(body, ['variant', 'data']) && body.variant === value, 'query variant identity');
    invariant(keys(body.data, projection), 'query variant exact projection');
    invariant(body.data.id === id && body.data.displayName === `user-${String(id).padStart(4, '0')}`, 'query variant aliases');
    invariant(body.data.nickname === (id % 3 === 0 ? null : `nick-${id}`), 'query variant null');
    if (value % 2) invariant(body.data.teamId === 1 + (id - 1) % 20, 'query variant team');
}
export function scratch(body, expected = 0) {
    invariant(keys(body, ['posts', 'orphanPivots']) && body.posts === expected && body.orphanPivots === 0, 'scratch/pivot persistence');
}
export function written(body, token, title, count, id) {
    const p = body.data;
    invariant(p && p.id >= 1000000 && (id === undefined || p.id === id) && p.userId === 1, 'write identity');
    invariant(p.ownerToken === token && p.title === title && p.lifecycleCount === count, 'write ownership/lifecycle');
    invariant(equal(p.profile, {level: 7}) && p.summary === null && !!p.createdAt && !!p.updatedAt, 'write cast/null/timestamps');
    return p;
}
