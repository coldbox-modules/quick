#!/usr/bin/env python3
"""Run real fresh JVMs to prove the measurement method; never qualifies a release."""
import argparse
import datetime
import hashlib
import html
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

from memory import evaluate, MIB, METHOD

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def write_json(path, value):
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    temporary.replace(path)


def wait_file(path, processes, seconds=30):
    deadline = time.monotonic() + seconds
    while not path.exists():
        if any(p.poll() is not None for p in processes):
            raise RuntimeError(f"Process ended before {path.name}; inspect logs")
        if time.monotonic() > deadline:
            raise TimeoutError(f"Timed out waiting for {path.name}")
        time.sleep(0.1)


def stop(process):
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)


def trial(directory, classes, fault, java):
    directory.mkdir()
    logs, processes = [], []
    result = {"fault": fault, "status": "inconclusive", "releaseQualified": False}
    try:
        command = [java, "-Xms256m", "-Xmx256m", "-XX:+UseZGC", "-XX:-ZGenerational",
                   "-XX:ZCollectionInterval=5", f"-Xlog:gc*:file={directory}/gc.log:time,uptime,level,tags:filecount=3,filesize=8M",
                   "-cp", str(classes), "MeasurementPilot", str(directory), fault]
        log = open(directory / "target.log", "w")
        logs.append(log)
        target = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT)
        processes.append(target)
        wait_file(directory / "target-ready", processes)
        log = open(directory / "collector.log", "w")
        logs.append(log)
        collector = subprocess.Popen([java, "-Xmx128m", "--add-modules", "jdk.attach,jdk.management.jfr",
                                      "-cp", str(classes), "Collector", str(target.pid), str(directory), "2", "20"],
                                     stdout=log, stderr=subprocess.STDOUT)
        processes.append(collector)
        write_json(directory / "processes.json", {"target": target.pid, "collector": collector.pid})
        wait_file(directory / "ready", processes)
        start_ms = int(time.time() * 1000)
        write_json(directory / "trial.json", {"startMs": start_ms, "durationSeconds": 90, "fault": fault,
                                             "method": METHOD, "command": command})
        (directory / "start").touch()
        deadline = time.monotonic() + 90
        while time.monotonic() < deadline:
            if any(p.poll() is not None for p in processes):
                raise RuntimeError("Target or collector ended during observation")
            time.sleep(0.25)
        (directory / "stop").touch()
        collector.wait(timeout=15)
        if collector.returncode:
            raise RuntimeError("Collector failed")
        (directory / "target-stop").touch()
        target.wait(timeout=10)
        if target.returncode:
            raise RuntimeError("Target failed")
        rows = [json.loads(line) for line in (directory / "jvm.ndjson").read_text().splitlines()]
        result.update(evaluate(rows, start_ms=start_ms + 15_000, end_ms=start_ms + 75_000,
                               window_ms=10_000, min_span_ms=45_000, min_cycles=1,
                               growth_bytes=16 * MIB))
        samples = [r for r in rows if r["kind"] == "sample"]
        if (not samples or samples[0]["time"] > start_ms + 4000
                or samples[-1]["time"] < start_ms + 88000
                or any(b["time"] - a["time"] > 6000 for a, b in zip(samples, samples[1:]))):
            result.update(status="inconclusive", reasons=["telemetry-gap"])
        result["runtime"] = next(r for r in rows if r["kind"] == "runtime")
        result["jfrBytes"] = (directory / "recording-final.jfr").stat().st_size
    except BaseException as exc:
        result.update(status="inconclusive", reasons=[str(exc) or type(exc).__name__])
        raise
    finally:
        # Preserve original failure and collect bounded evidence before stopping the target.
        (directory / "stop").touch()
        if len(processes) > 1 and processes[1].poll() is None:
            try:
                processes[1].wait(timeout=8)
            except subprocess.TimeoutExpired:
                pass
        for process in reversed(processes):
            stop(process)
        for log in logs:
            log.close()
        result["childExitCodes"] = [p.returncode for p in processes]
        write_json(directory / "summary.json", result)
    return result


def render_report(results):
    parts = ["<!doctype html><meta charset=utf-8><title>Quick memory measurement pilot</title>",
             "<style>body{font:16px system-ui;max-width:1000px;margin:40px auto;padding:0 24px}svg{width:100%;background:#f5f5f5}pre{white-space:pre-wrap}</style>",
             "<h1>Memory measurement pilot</h1><p>Detector validation only. These short local runs are not a release baseline.</p>"]
    for r in results:
        parts.append(f'<h2>{html.escape(r["fault"])}: {html.escape(r["status"])}</h2>')
        points = r.get("observations", [])
        if points:
            begin, end = points[0]["time"], points[-1]["time"]
            maximum = max(32 * MIB, max(p["bytes"] for p in points) * 1.15)
            coords = " ".join(f'{50 + 880 * (p["time"]-begin)/max(1,end-begin):.1f},{225-200*p["bytes"]/maximum:.1f}' for p in points)
            parts.append(f'<svg viewBox="0 0 960 265" role="img" aria-label="Post-reclamation heap occupancy over time"><text x="10" y="18">Heap MiB (top: {maximum/MIB:.0f})</text><polyline points="{coords}" fill="none" stroke="#135da8" stroke-width="3"/><text x="50" y="253">0 seconds</text><text x="830" y="253">{(end-begin)/1000:.0f} seconds</text></svg>')
        parts.append("<pre>" + html.escape(json.dumps({k: v for k, v in r.items() if k != "observations"}, indent=2)) + "</pre>")
    return "\n".join(parts)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "tests/results/soak" / ("pilot-" + datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")))
    parser.add_argument("--cases", nargs="+", choices=["healthy", "leak", "late-leak"], default=["healthy", "leak", "late-leak"])
    args = parser.parse_args()
    directory = args.output.resolve()
    directory.mkdir(parents=True, exist_ok=False)
    classes = directory / "classes"
    classes.mkdir()
    java_home = os.environ.get("JAVA_HOME")
    java = str(Path(java_home) / "bin/java") if java_home else "java"
    javac = str(Path(java_home) / "bin/javac") if java_home else "javac"
    subprocess.run([javac, "--release", "21", "--add-modules", "jdk.attach,jdk.management.jfr", "-d", str(classes),
                    str(HERE / "Collector.java"), str(HERE / "MeasurementPilot.java")], check=True)
    sources = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in HERE.glob("*") if p.suffix in (".java", ".py")}
    write_json(directory / "manifest.json", {"sources": sources, "method": METHOD, "releaseQualified": False})
    def cancel(signum, frame):
        raise KeyboardInterrupt(f"Canceled by signal {signum}")
    signal.signal(signal.SIGTERM, cancel)
    results = []
    try:
        for fault in args.cases:
            print(f"Running {fault}: {directory / fault}", flush=True)
            results.append(trial(directory / fault, classes, fault, java))
            print(f'{fault}: {results[-1]["status"]} {results[-1].get("reasons", [])}', flush=True)
    finally:
        write_json(directory / "summary.json", {"releaseQualified": False, "complete": len(results) == len(args.cases), "results": results})
        (directory / "report.html").write_text(render_report(results))
    expected = {"healthy": "passed", "leak": "failed", "late-leak": "inconclusive"}
    success = all(r["status"] == expected[r["fault"]] for r in results) and len(results) == len(args.cases)
    print(f"Pilot {'passed' if success else 'FAILED'}: {directory}", flush=True)
    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
