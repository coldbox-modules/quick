import unittest

from memory import evaluate, MIB


class MemoryEvidenceTests(unittest.TestCase):
    def rows(self, values):
        rows = [{"kind": "runtime", "collectors": "ZGC Pauses,ZGC Cycles", "arguments": "-XX:ZCollectionInterval=5"}]
        for i, value in enumerate(values):
            rows += [{"kind": "gc", "gcId": i, "name": "Z", "time": i * 10000 + 100},
                     {"kind": "heap", "gcId": i, "when": "After GC", "heapUsed": value * MIB, "time": i * 10000 + 100}]
        return rows

    def evaluate(self, rows):
        return evaluate(rows, start_ms=0, end_ms=60000, window_ms=10000,
                        min_span_ms=45000, min_cycles=1, growth_bytes=16 * MIB)

    def test_bounded_churn_passes(self):
        self.assertEqual(self.evaluate(self.rows([20, 24, 18, 25, 21, 22]))["status"], "passed")

    def test_retained_growth_fails(self):
        self.assertEqual(self.evaluate(self.rows([20, 30, 40, 50, 60, 70]))["status"], "failed")

    def test_final_window_regression_cannot_pass(self):
        result = self.evaluate(self.rows([20, 20, 20, 20, 20, 60]))
        self.assertEqual(result["status"], "inconclusive")
        self.assertIn("late-retained-growth-needs-observation", result["reasons"])

    def test_young_gc_does_not_prove_reclamation(self):
        rows = self.rows([20] * 6)
        for row in rows:
            if row["kind"] == "gc":
                row["name"] = "G1New"
        self.assertEqual(self.evaluate(rows)["status"], "inconclusive")

    def test_heap_summary_without_completed_cycle_is_not_evidence(self):
        rows = [r for r in self.rows([20] * 6) if r["kind"] != "gc"]
        self.assertEqual(self.evaluate(rows)["cycles"], 0)

    def test_duplicates_do_not_satisfy_sample_requirements(self):
        rows = self.rows([20] * 6)
        self.assertEqual(self.evaluate(rows + [r for r in rows if r["kind"] == "heap"])["cycles"], 6)

    def test_missing_middle_window_invalidates_stable_run(self):
        rows = [r for r in self.rows([20] * 6) if r.get("gcId") != 3]
        self.assertEqual(self.evaluate(rows)["status"], "inconclusive")

    def test_jvm_restart_fails(self):
        rows = self.rows([20] * 6) + [
            {"kind": "sample", "time": 0, "uptimeMs": 100},
            {"kind": "sample", "time": 1000, "uptimeMs": 10}]
        self.assertEqual(self.evaluate(rows)["status"], "failed")

    def test_collector_profile_mismatch_is_inconclusive(self):
        rows = self.rows([20] * 6)
        rows[0]["arguments"] += " -XX:+ZGenerational"
        self.assertEqual(self.evaluate(rows)["status"], "inconclusive")


if __name__ == "__main__":
    unittest.main()
