#!/usr/bin/env python3
"""Cancel a live pilot and verify real child termination and retained evidence."""
import argparse
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time


def main(output):
    output = output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.with_suffix(".log").open("w") as log:
        controller = subprocess.Popen([sys.executable, str(Path(__file__).with_name("pilot.py")),
                                       "--output", str(output), "--cases", "healthy"], stdout=log, stderr=subprocess.STDOUT)
        try:
            deadline = time.monotonic() + 45
            while not (output / "healthy/start").exists():
                if controller.poll() is not None or time.monotonic() > deadline:
                    raise RuntimeError("Pilot did not become live")
                time.sleep(0.1)
            children = json.loads((output / "healthy/processes.json").read_text())
            for pid in children.values():
                os.kill(pid, 0)
            # Wait for actual observations, not just a state file.
            while not (output / "healthy/jvm.ndjson").exists() or '"kind":"sample"' not in (output / "healthy/jvm.ndjson").read_text():
                if time.monotonic() > deadline:
                    raise RuntimeError("No JVM sample before cancellation")
                time.sleep(0.1)
            controller.send_signal(signal.SIGTERM)
            code = controller.wait(timeout=40)
            assert code != 0, "Canceled controller returned success"
            for pid in children.values():
                try:
                    os.kill(pid, 0)
                except ProcessLookupError:
                    pass
                else:
                    raise AssertionError(f"Child {pid} survived cancellation")
            summary = json.loads((output / "healthy/summary.json").read_text())
            aggregate = json.loads((output / "summary.json").read_text())
            assert summary["status"] == "inconclusive" and not aggregate["complete"]
            assert (output / "healthy/jvm.ndjson").stat().st_size > 0
            assert (output / "healthy/recording-final.jfr").stat().st_size > 0
            evidence = {"status": "passed", "controllerExitCode": code, "childPids": children,
                        "childrenStopped": True, "partialEvidenceRetained": True, "canceledRunQualified": False}
            (output / "cancellation-verification.json").write_text(json.dumps(evidence, indent=2) + "\n")
            print(json.dumps(evidence, indent=2))
        finally:
            if controller.poll() is None:
                controller.terminate()
                try:
                    controller.wait(timeout=40)
                except subprocess.TimeoutExpired:
                    controller.kill()
                    controller.wait(timeout=5)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    main(parser.parse_args().output)
