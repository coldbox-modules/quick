"""Collector-specific evidence rules shared by the pilot and eventual release analyzer.

Non-generational ZGC only: join an After GC heap summary to its *completed*
ZGC cycle. Young collections, reservation, and unmatched summaries are not
retained-heap evidence. Occupancy includes concurrent allocations, so compare
matched traffic windows and calibrated noise; this is not an object census.
"""
import math
import statistics

MIB = 1024 * 1024
METHOD = "jdk21-zgc-nongenerational-periodic-jfr-v1"


def evaluate(rows, *, start_ms, end_ms, window_ms, min_span_ms,
             min_cycles=2, growth_bytes=64 * MIB, noise_bytes=0,
             reference_ms=None, heap_max_bytes=0, exclude_initial_ms=0,
             baseline_bytes=None):
    reasons, warnings = [], []
    runtime = [r for r in rows if r["kind"] == "runtime"]
    if len(runtime) != 1 or set(runtime[0].get("collectors", "").split(",")) != {"ZGC Cycles", "ZGC Pauses"}:
        reasons.append("collector-method-mismatch")
    if runtime and ("-XX:+ZGenerational" in runtime[0].get("arguments", "")
                    or "-XX:ZCollectionInterval=" not in runtime[0].get("arguments", "")):
        reasons.append("collector-method-mismatch")
    samples = sorted((r for r in rows if r["kind"] == "sample"), key=lambda r: r["time"])
    if any(b["uptimeMs"] <= a["uptimeMs"] for a, b in zip(samples, samples[1:])):
        return {"status": "failed", "reasons": ["jvm-restarted"], "method": METHOD}
    if any(r["kind"] == "collectorError" for r in rows):
        reasons.append("collector-error")
    # JMX names the collector "ZGC Cycles"; JFR's name for that completed cycle is "Z".
    complete = {r["gcId"]: r for r in rows if r["kind"] == "gc" and r["name"] == "Z"}
    reclaimed = sorted((r for r in rows if r["kind"] == "heap" and r["when"] == "After GC"
                        and r["gcId"] in complete and start_ms + exclude_initial_ms <= r["time"] < end_ms), key=lambda r: r["time"])
    # Duplicate or out-of-order inputs cannot manufacture additional observations.
    reclaimed = list({r["gcId"]: r for r in reclaimed}.values())
    count = math.ceil((end_ms - start_ms) / window_ms)
    if count < 3 or start_ms + count * window_ms != end_ms:
        reasons.append("invalid-comparison-windows")
    windows = []
    for i in range(count):
        points = [r for r in reclaimed if start_ms + i * window_ms <= r["time"] < start_ms + (i + 1) * window_ms]
        windows.append({"index": i, "cycles": len(points),
                        "medianBytes": statistics.median(r["heapUsed"] for r in points) if points else None})
        if len(points) < min_cycles:
            reasons.append(f"insufficient-reclamation-window-{i}")
    span = reclaimed[-1]["time"] - reclaimed[0]["time"] if reclaimed else 0
    if span < min_span_ms:
        reasons.append("insufficient-reclamation-span")
    result = {"method": METHOD, "status": "inconclusive" if reasons else "passed",
              "reasons": list(dict.fromkeys(reasons)), "warnings": warnings,
              "windows": windows, "cycles": len(reclaimed), "spanMs": span,
              "observations": [{"time": r["time"], "bytes": r["heapUsed"]} for r in reclaimed]}
    if reasons:
        return result
    reference_ms = reference_ms or window_ms
    if reference_ms > (end_ms - start_ms) / 2 or reference_ms % window_ms:
        result.update(status="inconclusive", reasons=["invalid-reference-duration"])
        return result
    early = [r["heapUsed"] for r in reclaimed if r["time"] < start_ms + reference_ms]
    late = [r["heapUsed"] for r in reclaimed if r["time"] >= end_ms - reference_ms]
    if not early or not late:
        result.update(status="inconclusive", reasons=["missing-early-or-late-reclamation"])
        return result
    reference = statistics.median(early)
    late_median = statistics.median(late)
    threshold = max(growth_bytes, 0.05 * heap_max_bytes, noise_bytes)
    warning_threshold = max(32 * MIB, 0.03 * heap_max_bytes, noise_bytes)
    growth = late_median - reference
    values = [w["medianBytes"] for w in windows]
    center = (len(values) - 1) / 2
    slope = sum((i - center) * value for i, value in enumerate(values)) / sum((i - center) ** 2 for i in range(len(values)))
    result.update(growthBytes=growth, thresholdBytes=threshold, warningBytes=warning_threshold,
                  earlyMedianBytes=reference, lateMedianBytes=late_median,
                  slopeBytesPerMinute=slope * 60000 / window_ms, referenceMs=reference_ms)
    consecutive = 0
    for window in windows[reference_ms // window_ms:]:
        above = window["medianBytes"] - reference > threshold
        consecutive = consecutive + 1 if above else 0
        window["growthBytes"] = window["medianBytes"] - reference
        if consecutive >= 3:
            result["status"] = "failed"
            result["reasons"] = ["sustained-retained-growth"]
    if result["status"] != "failed" and consecutive:
        result["status"] = "inconclusive"
        result["reasons"] = ["late-retained-growth-needs-observation"]
    if growth > warning_threshold:
        warnings.append("retained-growth-warning")
    if all(b > a for a, b in zip(values, values[1:])):
        warnings.append("persistent-positive-retained-trend")
    if baseline_bytes is not None and reference - baseline_bytes > warning_threshold:
        warnings.append("absolute-retained-occupancy-shift")
        result["baselineShiftBytes"] = reference - baseline_bytes
        if reference - baseline_bytes > threshold and result["status"] != "failed":
            result.update(status="inconclusive", reasons=["unexplained-retained-occupancy-shift"])
    if reference_ms > window_ms and abs(values[reference_ms // window_ms - 1] - values[0]) > warning_threshold and result["status"] != "failed":
        result.update(status="inconclusive", reasons=["unsettled-early-memory-reference"])
    return result
