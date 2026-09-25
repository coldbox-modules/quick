#!/usr/bin/env python3
"""Behavior tests through HTTP and Quick's installed distributable, with no TestBox lifecycle."""
import argparse
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import urllib.error
import urllib.request
import uuid
import sys


def request(base, token, method, path, status=200, data=None):
    headers = {"X-Soak-Token": token, "Content-Type": "application/json"}
    req = urllib.request.Request(base + path, method=method, headers=headers,
                                 data=json.dumps(data).encode() if data is not None else None)
    try:
        response = urllib.request.urlopen(req, timeout=10)
    except urllib.error.HTTPError as exc:
        response = exc
    with response:
        body = response.read()
        assert response.status == status, (method, path, response.status, body[:1000].decode(errors="replace"))
        assert "application/json" in response.headers.get("Content-Type", ""), (path, "not JSON")
        return json.loads(body)


def run(base, token, fixture):
    def call(method, path, status=200, data=None):
        return request(base, token, method, path, status, data)
    def missing(path, method="GET", data=None):
        result = call(method, path, 404, data)
        assert result == {"error": {"code": "EntityNotFound", "type": "EntityNotFound"}}, result
    def user(user_id):
        data = call("GET", f"/api/users/{user_id}")["data"]
        assert data["id"] == user_id and data["teamId"] == 1+(user_id-1)%20, data
        assert data["displayName"] == f"user-{user_id:04}" and "secret" not in data, data
        assert data["profile"] == {"level": user_id%7}, data
        assert data["team"]["id"] == data["teamId"] and len(data["posts"]) <= 5, data
        assert all(post["userId"] == user_id for post in data["posts"]), data
        if user_id%3 == 0:
            assert data["nickname"] is None, data
        if user_id in fixture["emptyUserIds"]:
            assert data["posts"] == [], data
        return data

    before = call("GET", "/diagnostics")
    assert call("GET", "/health/ready")["ready"] is True
    assert request(base, "incorrect", "GET", "/diagnostics", 401) == {"error": {"code": "Unauthorized"}}
    for user_id in [1, 3, 28, 999, 1000]:
        user(user_id)
    for team in [1, 7, 20]:
        for limit in [25, 100]:
            for page in [1, 2]:
                data = call("GET", f"/api/users?team={team}&limit={limit}&page={page}")["data"]
                expected = list(range(team, 1001, 20))[(page-1)*limit:page*limit]
                assert [u["id"] for u in data] == expected, (team, limit, page, data)
                assert all(u["teamId"] == team and "secret" not in u for u in data), data
    for start in [1, 199, 9996]:
        data = call("GET", f"/api/posts?start={start}")["data"]
        assert [p["id"] for p in data] == list(range(start, start+5)), data
        for post in data:
            key = str(post["id"])
            assert post["author"]["id"] == post["userId"], post
            assert "secret" not in post["author"], post
            assert len(post["comments"]) == fixture["postCommentCounts"][key], (key, len(post["comments"]))
            assert sorted(t["id"] for t in post["tags"]) == sorted(fixture["postTags"][key]), post
            assert all(c["commentableId"] == post["id"] and c["commentableType"] == "Post"
                       and c["author"]["id"] == c["userId"] for c in post["comments"]), post
    for limit in [100, 500, 1000]:
        result = call("GET", f"/api/reports/posts?limit={limit}")
        assert len(result["data"]) == limit, limit
        canonical = "|".join(f'{p["id"]}:{p["userId"]}:{p["title"]}' for p in result["data"])
        assert result["checksum"] == hashlib.sha256(canonical.encode()).hexdigest() == fixture["reportChecksums"][str(limit)]
    for variant in range(32):
        data = call("GET", f"/api/query-variants/{variant}")["data"]
        assert data["id"] == variant+1 and data["displayName"] == f"user-{variant+1:04}", data
    unrelated = call("GET", "/api/query-variants/32", 500)
    assert unrelated == {"error": {"code": "UnexpectedError", "type": "SoakInvalidVariant"}}, unrelated
    user(1)
    missing("/api/users/2000000000")
    user(1)
    for mode in ["default", "custom", "callback"]:
        missing(f"/api/users/lookup?message={mode}")
        assert call("GET", "/api/users/lookup?email=user-3@example.invalid")["data"]["id"] == 3
    missing("/api/users/1/posts/2000000000")
    missing("/api/users/2/posts/1")
    assert call("GET", "/api/users/1/posts/1")["data"]["userId"] == 1

    def write_journey(_):
        ownership = "smoke_" + uuid.uuid4().hex
        payload = {"ownerToken": ownership, "title": "created"}
        invalid = call("POST", "/api/posts", 422, {**payload, "title": ""})
        assert invalid["error"]["code"] == "ValidationFailed" and "title" in invalid["error"]["fields"], invalid
        assert call("GET", f"/api/scratch/{ownership}") == {"posts": 0, "orphanPivots": 0}
        missing("/api/transactions/rollback", "POST", payload)
        assert call("GET", f"/api/scratch/{ownership}") == {"posts": 0, "orphanPivots": 0}
        created = call("POST", "/api/posts", 201, payload)["data"]
        assert created["id"] >= fixture["scratchIdStart"] and created["lifecycleCount"] == 1, created
        path = f'/api/posts/{created["id"]}?token={ownership}'
        stored = call("GET", path)["data"]
        assert stored["ownerToken"] == ownership and stored["title"] == "created", stored
        assert stored["profile"] == {"level": 7} and stored["createdAt"] and stored["updatedAt"], stored
        assert sorted(tag["id"] for tag in stored["tags"]) == [1, 2], stored
        missing(f'/api/posts/{created["id"]}?token=another_ownership_token')
        call("PATCH", path, data={**payload, "title": "updated"})
        updated = call("GET", path)["data"]
        assert updated["title"] == "updated" and updated["lifecycleCount"] == 2, updated
        assert updated["createdAt"] == stored["createdAt"] and updated["updatedAt"] >= stored["updatedAt"], updated
        assert call("DELETE", path) == {"deleted": True}
        missing(path)
        assert call("GET", f"/api/scratch/{ownership}") == {"posts": 0, "orphanPivots": 0}
        user(3)

    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        list(pool.map(write_journey, range(16)))
    after = call("GET", "/diagnostics")
    assert after["bootId"] == before["bootId"] and after["applicationStarts"] == 1, (before, after)
    assert after["uptimeMs"] > before["uptimeMs"] and after["scratchPosts"] == 0, after
    assert after["registry"]["derivedEvictionCount"] > 0, after
    return {"status": "passed", "before": before, "after": after, "concurrentWriteJourneys": 16}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", default="http://127.0.0.1:60399")
    parser.add_argument("--fixture-manifest", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--package-manifest", type=Path, required=True)
    parser.add_argument("--installed-package", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        parser.error("Output already exists; use a new path to retain earlier evidence")
    try:
        package = json.loads(args.package_manifest.read_text())
        for name, expected in package["files"].items():
            assert hashlib.sha256((args.installed_package / name).read_bytes()).hexdigest() == expected, ("installed package changed", name)
        result = run(args.url, os.environ["SOAK_TOKEN"], json.loads(args.fixture_manifest.read_text()))
        result["package"] = {key: package[key] for key in ("candidateSha", "version", "packageSha256")}
        result["releaseQualified"] = False
    except Exception as exc:
        result = {"status": "failed", "error": str(exc)[:2000], "type": type(exc).__name__}
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    sys.exit(0 if result["status"] == "passed" else 1)
