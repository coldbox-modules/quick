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

    def production(self, values, **kwargs):
        rows = [{"kind": "runtime", "collectors": "ZGC Pauses,ZGC Cycles", "arguments": "-XX:ZCollectionInterval=15"}]
        for window, value in enumerate(values):
            for cycle in range(20):
                gc_id, time = window * 20 + cycle, window * 300000 + cycle * 15000 + 100
                rows += [{"kind": "gc", "gcId": gc_id, "name": "Z", "time": time},
                         {"kind": "heap", "gcId": gc_id, "when": "After GC", "heapUsed": value * MIB, "time": time}]
        return evaluate(rows, start_ms=0, end_ms=2400000, window_ms=300000,
                        min_span_ms=1200000, min_cycles=10, reference_ms=600000,
                        heap_max_bytes=kwargs.pop("heap_max_bytes", 1024 * MIB), exclude_initial_ms=30000, **kwargs)

    def test_production_compares_ten_minute_windows(self):
        r = self.production([200, 202, 200, 201, 203, 200, 202, 204])
        self.assertEqual(r["status"], "passed")
        self.assertEqual(r["lateMedianBytes"], 203 * MIB)
        self.assertGreaterEqual(r["spanMs"], 1200000)
        self.assertEqual(r["windows"][0]["cycles"], 18)

    def test_production_retained_growth_is_sustained(self):
        r = self.production([200, 202, 203, 275, 276, 278, 280, 282])
        self.assertEqual(r["status"], "failed")
        self.assertIn("sustained-retained-growth", r["reasons"])

    def test_late_growth_cannot_hide_in_last_ten_minute_average(self):
        r = self.production([200] * 7 + [290])
        self.assertLess(r["growthBytes"], r["thresholdBytes"])
        self.assertEqual(r["status"], "inconclusive")

    def test_flat_absolute_shift_against_reference_is_flagged(self):
        r = self.production([200] * 8, baseline_bytes=100 * MIB)
        self.assertEqual(r["status"], "inconclusive")
        self.assertIn("absolute-retained-occupancy-shift", r["warnings"])

    def test_unsettled_early_memory_is_not_a_healthy_reference(self):
        self.assertIn("unsettled-early-memory-reference", self.production([100, 150, 150, 150, 150, 150, 150, 150])["reasons"])

    def test_heap_fraction_scales_blocking_threshold(self):
        r = self.production([200, 200, 350, 350, 350, 350, 350, 350], heap_max_bytes=4096 * MIB)
        self.assertEqual(r["status"], "passed")
        self.assertAlmostEqual(r["thresholdBytes"], 0.05 * 4096 * MIB)

    def test_small_persistent_growth_is_reported(self):
        r = self.production(list(range(200, 208)))
        self.assertEqual(r["status"], "passed")
        self.assertIn("persistent-positive-retained-trend", r["warnings"])


if __name__ == "__main__":
    unittest.main()
