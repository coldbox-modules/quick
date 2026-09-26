#!/usr/bin/env python3
"""Generate deterministic v1 SQL once, outside the measured application lifecycle."""
import argparse
import hashlib
import json
from pathlib import Path

VERSION = "v1"


def owner(post_id):
    return 1 if post_id <= 200 else 2 + (post_id - 201) % 997


def sql_value(value):
    if value is None:
        return "NULL"
    if isinstance(value, int):
        return str(value)
    return "'" + str(value).replace("\\", "\\\\").replace("'", "''") + "'"


def fixture_settings(profile):
    settings = profile.get("fixtures", {"highFanoutComments": 180})
    if (not isinstance(settings, dict) or set(settings) != {"highFanoutComments"}
            or type(settings["highFanoutComments"]) is not int
            or settings["highFanoutComments"] not in (30, 60, 180)):
        raise ValueError("fixtures must declare highFanoutComments as 30, 60 or 180")
    return dict(settings)


def generate(output, high_fanout_comments=180):
    fixture_settings({"fixtures": {"highFanoutComments": high_fanout_comments}})
    # Every tenth comment belongs to a User, so the cutoff counts only Post rows.
    cutoff = (high_fanout_comments // 9) * 10 + high_fanout_comments % 9
    output.mkdir(parents=True, exist_ok=False)
    counts = {"teams": 20, "users": 1000, "posts": 10000, "comments": 50000, "tags": 100, "post_tags": 0}
    comments = {str(i): 0 for i in range(1, 10001)}
    tags = {}
    schema = """
CREATE DATABASE quick_soak CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
USE quick_soak;
CREATE TABLE teams (id INT PRIMARY KEY, name VARCHAR(40) NOT NULL);
CREATE TABLE users (id INT PRIMARY KEY, team_id INT NOT NULL, display_name VARCHAR(40) NOT NULL, email VARCHAR(80) NOT NULL UNIQUE, nickname VARCHAR(40) NULL, secret VARCHAR(40) NOT NULL, profile JSON NOT NULL, INDEX(team_id,id), FOREIGN KEY(team_id) REFERENCES teams(id));
CREATE TABLE posts (id INT PRIMARY KEY AUTO_INCREMENT, user_id INT NOT NULL, title VARCHAR(80) NOT NULL, summary VARCHAR(80) NULL, owner_token VARCHAR(100) NULL UNIQUE, profile JSON NOT NULL, lifecycle_count INT NOT NULL DEFAULT 0, created_at DATETIME(6) NULL, updated_at DATETIME(6) NULL, INDEX(user_id,id), FOREIGN KEY(user_id) REFERENCES users(id));
CREATE TABLE comments (id INT PRIMARY KEY, user_id INT NOT NULL, body VARCHAR(80) NOT NULL, commentable_id INT NOT NULL, commentable_type VARCHAR(20) NOT NULL, INDEX(commentable_type,commentable_id,id), FOREIGN KEY(user_id) REFERENCES users(id));
CREATE TABLE tags (id INT PRIMARY KEY, name VARCHAR(40) NOT NULL);
CREATE TABLE post_tags (post_id INT NOT NULL, tag_id INT NOT NULL, context VARCHAR(40) NOT NULL DEFAULT 'scratch', PRIMARY KEY(post_id,tag_id), FOREIGN KEY(post_id) REFERENCES posts(id), FOREIGN KEY(tag_id) REFERENCES tags(id));
CREATE TABLE fixture_manifest (version VARCHAR(20) PRIMARY KEY);
"""
    with (output / "seed.sql").open("w") as out:
        out.write(schema)
        def insert(table, columns, rows):
            batch = []
            for row in rows:
                batch.append("(" + ",".join(map(sql_value, row)) + ")")
                if len(batch) == 500:
                    out.write(f"INSERT INTO {table} ({columns}) VALUES " + ",".join(batch) + ";\n")
                    batch.clear()
            if batch:
                out.write(f"INSERT INTO {table} ({columns}) VALUES " + ",".join(batch) + ";\n")
        insert("teams", "id,name", ((i, f"team-{i:02}") for i in range(1, 21)))
        insert("users", "id,team_id,display_name,email,nickname,secret,profile", (
            (i, 1+(i-1)%20, f"user-{i:04}", f"user-{i}@example.invalid", None if i%3 == 0 else f"nick-{i}", "never-serialize", json.dumps({"level": i%7})) for i in range(1, 1001)))
        insert("posts", "id,user_id,title,summary,profile,created_at,updated_at", (
            (i, owner(i), f"post-{i:05}", None if i%3 == 0 else f"summary-{i}", json.dumps({"level": i%7}), "2026-01-01 00:00:00", "2026-01-01 00:00:00") for i in range(1, 10001)))
        insert("tags", "id,name", ((i, f"tag-{i:03}") for i in range(1, 101)))
        def comment_rows():
            for i in range(1, 50001):
                user_id = 1+(i-1)%1000
                kind = "User" if i%10 == 0 else "Post"
                parent = user_id if kind == "User" else (1 if i <= cutoff else 2+(i-cutoff-1)%9998)
                if kind == "Post":
                    comments[str(parent)] += 1
                yield i, user_id, f"comment-{i:05}", parent, kind
        insert("comments", "id,user_id,body,commentable_id,commentable_type", comment_rows())
        def pivot_rows():
            for i in range(1, 10001):
                assigned = [] if i%7 == 0 else [1+(i-1)%100, 1+i%100]
                tags[str(i)] = assigned
                for tag in assigned:
                    counts["post_tags"] += 1
                    yield i, tag, "fixture"
        insert("post_tags", "post_id,tag_id,context", pivot_rows())
        out.write("ALTER TABLE posts AUTO_INCREMENT=1000000;\nINSERT INTO fixture_manifest VALUES ('v1');\n")
    checksums = {str(limit): hashlib.sha256("|".join(f"{i}:{owner(i)}:post-{i:05}" for i in range(1, limit+1)).encode()).hexdigest() for limit in (25, 50, 100, 250, 500, 1000)}
    manifest = {"version": VERSION, "seed": 0, "counts": counts,
                "highFanoutComments": high_fanout_comments,
                "postCommentCounts": comments, "postTags": tags, "reportChecksums": checksums,
                "sqlSha256": hashlib.sha256((output / "seed.sql").read_bytes()).hexdigest(),
                "missingIdStart": 2000000000, "scratchIdStart": 1000000, "emptyUserIds": [999, 1000]}
    (output / "fixture-manifest.json").write_text(json.dumps(manifest, separators=(",", ":")) + "\n")
    return manifest


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("--high-fanout-comments", type=int, choices=(30, 60, 180), default=180)
    args = parser.parse_args()
    print(json.dumps({k: v for k, v in generate(args.output, args.high_fanout_comments).items() if k not in ("postCommentCounts", "postTags")}, indent=2))
