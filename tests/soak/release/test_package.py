import concurrent.futures
import json
from pathlib import Path
import subprocess
import tempfile
import threading
import time
import unittest
import zipfile

from package import build, promote, verify, digest


class FakePublisher:
    """No network capability. Models two provider writes and downloaded bytes."""
    def __init__(self, sha, last_release):
        self.sha, self.last = sha, last_release
        self.packages, self.events = {}, []
        self.lock = threading.Lock()
        self.corrupt_download = False
        self.fail_publicize = False

    def candidate_sha(self):
        return self.sha

    def last_release(self):
        return self.last

    def version_exists(self, version):
        return version in self.packages

    def upload(self, manifest, data):
        self.events.append("upload:" + manifest["version"])
        self.packages[manifest["version"]] = data
        # Leave a scheduling opportunity between the two provider operations.
        time.sleep(0.01)

    def download(self, manifest):
        return b"wrong" if self.corrupt_download else self.packages[manifest["version"]]

    def publicize(self, manifest, notes):
        if self.fail_publicize:
            raise RuntimeError("GitHub unavailable")
        self.events.append("publicize:" + manifest["version"])
        self.last = {"version": manifest["version"], "gitSha": manifest["candidateSha"]}


class PromotionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        self.git("init", "-q")
        self.git("config", "user.name", "Test")
        self.git("config", "user.email", "test@example.invalid")
        for name, contents in {"box.json": json.dumps({"slug": "quick", "version": "1.0.0"}),
                               "ModuleConfig.cfc": "component {}", "models/User.cfc": "component {}",
                               "README.md": "readme", "LICENSE": "license", "CHANGELOG.md": "history",
                               "tests/soak/app/index.cfm": "forbidden", "tests/results/nested/build.zip": "forbidden",
                               ".engine/lucee/file": "forbidden", "modules/qb/box.json": "forbidden"}.items():
            path = self.repo / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(contents)
        self.git("add", ".")
        self.git("commit", "-qm", "fixture")
        self.sha = self.git("rev-parse", "HEAD").strip()
        self.prepared = {"candidateSha": self.sha, "version": "1.0.1", "notes": "## 1.0.1\nFix.",
                         "lastRelease": {"version": "1.0.0", "gitSha": "a" * 40}}
        self.output = self.root / "artifact"
        self.manifest = build(self.repo, self.prepared, self.output)
        self.publisher = FakePublisher(self.sha, self.prepared["lastRelease"])

    def git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.repo), *args], stderr=subprocess.STDOUT).decode()

    def test_exact_tested_bytes_are_promoted_and_downloaded(self):
        receipt = promote(self.output, self.sha, self.publisher)
        self.assertEqual(receipt["downloadSha256"], self.manifest["packageSha256"])
        self.assertEqual(self.publisher.events, ["upload:1.0.1", "publicize:1.0.1"])

    def test_diagnostic_artifact_cannot_be_promoted(self):
        self.prepared["lastRelease"] = {"diagnosticOnly": True}
        diagnostic = self.root / "diagnostic"
        build(self.repo, self.prepared, diagnostic)
        publisher = FakePublisher(self.sha, self.prepared["lastRelease"])
        with self.assertRaisesRegex(ValueError, "Diagnostic packages"):
            promote(diagnostic, self.sha, publisher)
        self.assertEqual(publisher.events, [])

    def test_no_release_preparation_cannot_build_an_artifact(self):
        prepared = {**self.prepared, 'noRelease': True}
        with self.assertRaisesRegex(ValueError, 'No-release preparation'):
            build(self.repo, prepared, self.root / 'no-release')
        self.assertFalse((self.root / 'no-release').exists())

    def test_legacy_no_release_metadata_cannot_reach_publisher(self):
        prepared = {**self.prepared, 'noRelease': True}
        (self.output / 'prepared.json').write_text(json.dumps(prepared))
        manifest = {**self.manifest, 'preparedSha256': digest(json.dumps(prepared, sort_keys=True).encode())}
        (self.output / 'package-manifest.json').write_text(json.dumps(manifest))
        with self.assertRaisesRegex(ValueError, 'No-release preparation'):
            promote(self.output, self.sha, self.publisher)
        self.assertEqual(self.publisher.events, [])

    def test_harness_and_generated_files_are_excluded_even_when_tracked(self):
        with zipfile.ZipFile(self.output / "quick.zip") as package:
            self.assertEqual(set(package.namelist()), {"box.json", "ModuleConfig.cfc", "models/User.cfc", "README.md", "LICENSE", "CHANGELOG.md"})

    def test_build_ignores_working_tree_and_is_reproducible(self):
        (self.repo / "models/User.cfc").write_text("uncommitted changes")
        second = build(self.repo, self.prepared, self.root / "second")
        self.assertEqual(self.manifest, second)

    def test_changed_tested_zip_blocks_publication(self):
        with (self.output / "quick.zip").open("ab") as out:
            out.write(b"changed")
        with self.assertRaisesRegex(ValueError, "checksum mismatch"):
            promote(self.output, self.sha, self.publisher)
        self.assertEqual(self.publisher.events, [])

    def test_wrong_candidate_blocks_publication(self):
        with self.assertRaisesRegex(ValueError, "SHA mismatch"):
            promote(self.output, "b" * 40, self.publisher)
        self.assertEqual(self.publisher.events, [])

    def test_newer_push_supersedes_candidate(self):
        self.publisher.sha = "b" * 40
        with self.assertRaisesRegex(ValueError, "superseded"):
            promote(self.output, self.sha, self.publisher)

    def test_changed_last_release_blocks_prepared_version(self):
        self.publisher.last = {"version": "1.0.2", "gitSha": "c" * 40}
        with self.assertRaisesRegex(ValueError, "stale"):
            promote(self.output, self.sha, self.publisher)
        self.assertEqual(self.publisher.events, [])

    def test_corrupt_provider_download_blocks_publicizing(self):
        self.publisher.corrupt_download = True
        with self.assertRaisesRegex(ValueError, "download differs"):
            promote(self.output, self.sha, self.publisher)
        self.assertEqual(self.publisher.events, ["upload:1.0.1"])

    def test_partial_publication_is_not_silently_retried(self):
        self.publisher.fail_publicize = True
        with self.assertRaisesRegex(RuntimeError, "GitHub unavailable"):
            promote(self.output, self.sha, self.publisher)
        self.publisher.fail_publicize = False
        with self.assertRaisesRegex(ValueError, "already exists"):
            promote(self.output, self.sha, self.publisher)
        self.assertEqual(self.publisher.events, ["upload:1.0.1"])

    def test_overlapping_preparations_are_serialized_and_stale_one_stops(self):
        def guarded_promote():
            with self.publisher.lock:
                try:
                    return promote(self.output, self.sha, self.publisher)
                except ValueError as exc:
                    return str(exc)
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(lambda _: guarded_promote(), range(2)))
        self.assertEqual(sum(isinstance(r, dict) for r in results), 1)
        self.assertEqual(sum(isinstance(r, str) and "stale" in r for r in results), 1)
        self.assertEqual(self.publisher.events, ["upload:1.0.1", "publicize:1.0.1"])


if __name__ == "__main__":
    unittest.main()
