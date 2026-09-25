#!/usr/bin/env python3
"""Build and verify a distributable from an immutable commit and prepared metadata.

No publishing credentials or network calls. Promotion consumes this exact ZIP;
it must never rerun `forgebox publish` against a directory, which rebuilds it.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import re
import subprocess
import zipfile

FILES = {"box.json", "ModuleConfig.cfc", "README.md", "LICENSE", "CHANGELOG.md"}
DIRECTORIES = {"models", "dsl", "extras", "resources"}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def allowed(name):
    path = PurePosixPath(name)
    return (not path.is_absolute() and ".." not in path.parts
            and not any(part.startswith(".") for part in path.parts)
            and (name in FILES or path.parts[0] in DIRECTORIES))


def git(repo, *args):
    return subprocess.check_output(["git", "-C", str(repo), *args])


def build(repo, prepared, output):
    sha = prepared["candidateSha"]
    if not re.fullmatch(r"[0-9a-f]{40}", sha):
        raise ValueError("Candidate must be a full commit SHA")
    if git(repo, "rev-parse", f"{sha}^{{commit}}").decode().strip() != sha:
        raise ValueError("Candidate is not a commit")
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?", prepared["version"]):
        raise ValueError("Invalid prepared version")
    if not prepared.get("lastRelease") or not isinstance(prepared.get("notes"), str):
        raise ValueError("Last-release identity and prepared notes are required")
    output.mkdir(parents=True, exist_ok=False)
    files = {}
    # git archive is independent of untracked engines, installed modules, and dirty edits.
    archive = git(repo, "archive", "--format=zip", sha)
    with zipfile.ZipFile(io.BytesIO(archive)) as source:
        for entry in source.infolist():
            if entry.is_dir() or not allowed(entry.filename):
                continue
            if entry.external_attr >> 16 & 0o170000 == 0o120000:
                raise ValueError(f"Symlinks are not distributable: {entry.filename}")
            files[entry.filename] = source.read(entry)
    if not FILES <= files.keys():
        raise ValueError("Candidate is missing required package files")
    descriptor = json.loads(files["box.json"])
    descriptor["version"] = prepared["version"]
    files["box.json"] = (json.dumps(descriptor, indent=4) + "\n").encode()
    files["CHANGELOG.md"] = (prepared["notes"].rstrip() + "\n\n").encode() + files["CHANGELOG.md"]
    # Stable ZIP metadata gives repeatable checksums; preparation happens exactly once.
    package = output / "quick.zip"
    with zipfile.ZipFile(package, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as target:
        for name, data in sorted(files.items()):
            entry = zipfile.ZipInfo(name, (2020, 1, 1, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.external_attr = 0o100644 << 16
            target.writestr(entry, data)
    manifest = {"schema": 1, "candidateSha": sha, "version": prepared["version"],
                "lastRelease": prepared["lastRelease"], "slug": descriptor["slug"],
                "preparedSha256": digest(json.dumps(prepared, sort_keys=True).encode()),
                "packageSha256": digest(package.read_bytes()),
                "files": {name: digest(data) for name, data in sorted(files.items())}}
    (output / "prepared.json").write_text(json.dumps(prepared, indent=2) + "\n")
    (output / "package-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    verify(output, sha)
    return manifest


def verify(directory, expected_sha):
    manifest = json.loads((directory / "package-manifest.json").read_text())
    prepared = json.loads((directory / "prepared.json").read_text())
    if manifest["candidateSha"] != expected_sha or prepared["candidateSha"] != expected_sha:
        raise ValueError("Candidate SHA mismatch")
    if digest(json.dumps(prepared, sort_keys=True).encode()) != manifest["preparedSha256"]:
        raise ValueError("Prepared metadata changed")
    if prepared["lastRelease"] != manifest["lastRelease"] or prepared["version"] != manifest["version"]:
        raise ValueError("Prepared release identity mismatch")
    data = (directory / "quick.zip").read_bytes()
    if digest(data) != manifest["packageSha256"]:
        raise ValueError("Tested package checksum mismatch")
    with zipfile.ZipFile(io.BytesIO(data)) as package:
        names = package.namelist()
        if len(names) != len(set(names)) or not all(allowed(name) for name in names):
            raise ValueError("Forbidden or duplicate package members")
        contents = {name: digest(package.read(name)) for name in names}
        if contents != manifest["files"]:
            raise ValueError("Package content mismatch")
        descriptor = json.loads(package.read("box.json"))
        if descriptor["version"] != manifest["version"] or descriptor["slug"] != manifest["slug"]:
            raise ValueError("Package identity mismatch")
    return manifest


def promote(directory, expected_sha, publisher):
    """Caller must hold the repository publication guard for this whole operation.

    The publisher protocol lets tests exercise the real checks with a fake remote.
    The eventual network adapter must not rebuild, retry writes, or select a version.
    """
    manifest = verify(directory, expected_sha)
    if manifest["lastRelease"].get("diagnosticOnly"):
        raise ValueError("Diagnostic packages cannot be promoted")
    if publisher.candidate_sha() != expected_sha:
        raise ValueError("Candidate superseded")
    if publisher.last_release() != manifest["lastRelease"]:
        raise ValueError("Prepared version is stale; revalidation required")
    if publisher.version_exists(manifest["version"]):
        raise ValueError("Version already exists; reconcile partial publication")
    tested_bytes = (directory / "quick.zip").read_bytes()
    # Read once after verification and check again so the bytes submitted are bound to proof.
    if digest(tested_bytes) != manifest["packageSha256"]:
        raise ValueError("Package changed before upload")
    publisher.upload(manifest, tested_bytes)
    downloaded = publisher.download(manifest)
    if digest(downloaded) != manifest["packageSha256"]:
        raise ValueError("Published download differs from tested artifact")
    publisher.publicize(manifest, json.loads((directory / "prepared.json").read_text())["notes"])
    return {"candidateSha": expected_sha, "packageSha256": manifest["packageSha256"],
            "downloadSha256": digest(downloaded), "version": manifest["version"]}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("build")
    p.add_argument("--repo", type=Path, required=True)
    p.add_argument("--prepared", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    p = sub.add_parser("verify")
    p.add_argument("--directory", type=Path, required=True)
    p.add_argument("--candidate", required=True)
    args = parser.parse_args()
    if args.command == "build":
        print(json.dumps(build(args.repo, json.loads(args.prepared.read_text()), args.output), indent=2))
    else:
        print(json.dumps(verify(args.directory, args.candidate), indent=2))
