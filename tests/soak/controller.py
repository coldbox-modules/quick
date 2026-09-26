#!/usr/bin/env python3
"""Provision and supervise one isolated application/MySQL/k6/collector run.

There is deliberately no publishing capability. Release qualification requires
the full analyzer and an accepted baseline, never the controller exit alone.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import datetime
import hashlib
import json
import os
import platform
from pathlib import Path
import secrets
import shutil
import signal
import subprocess
import sys
import time
import traceback
import urllib.error

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE / "release"))
from package import build, verify
sys.path.insert(0, str(HERE / "telemetry"))
from traffic import evaluate as evaluate_traffic
from report import render as render_report
from resources import evaluate as evaluate_resources
from memory import evaluate as evaluate_memory
from delivery import evaluate as evaluate_delivery
from native import parse_memory_stat


def write_json(path, value):
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    temporary.replace(path)


def sha_file(path):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


class Inconclusive(RuntimeError):
    """Required run evidence is unavailable; this is never a passing result."""


class Controller:
    def __init__(self, args):
        self.args = args
        self.profile = json.loads(args.profile.read_text())
        self.run_id = "r" + datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S").lower() + "-" + secrets.token_hex(3)
        self.out = (args.output or ROOT / "tests/results/soak" / self.run_id).resolve()
        self.out.mkdir(parents=True, exist_ok=False)
        self.prefix = "quick-soak-" + self.run_id
        self.containers = []
        self.network = False
        self.volume = False
        self.env = {**os.environ, "SOAK_TOKEN": secrets.token_hex(24), "MYSQL_ROOT_PASSWORD": secrets.token_hex(20),
                    "SOAK_DB_PASSWORD": secrets.token_hex(20)}
        self.env["MYSQL_PASSWORD"] = self.env["SOAK_DB_PASSWORD"]
        self.env["MYSQL_PWD"] = self.env["MYSQL_ROOT_PASSWORD"]
        self.env["SOAK_MYSQL_ROOT_PASSWORD"] = self.env["MYSQL_ROOT_PASSWORD"]
        self.summary = {"runId": self.run_id, "status": "inconclusive", "releaseQualified": False, "reasons": []}
        self.app_pid = None
        self.url = None
        self.measured_start = None
        self.last_diag = None
        self.sample_number = 0
        self.memory_pressure_since = None
        self.latency_baseline = None
        self.memory_baseline = {}

    def command(self, args, *, timeout=120, input=None, log=None, check=True):
        if log:
            with (self.out / log).open("ab") as stream:
                p = subprocess.run(args, input=input, stdout=stream, stderr=subprocess.STDOUT,
                                   timeout=timeout, env=self.env)
            if check and p.returncode:
                raise RuntimeError(f"{args[0]} failed ({p.returncode}); see {log}")
            return p
        p = subprocess.run(args, input=input, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                           timeout=timeout, env=self.env)
        if check and p.returncode:
            raise RuntimeError(f"{args[0]} failed ({p.returncode}): {p.stderr.decode(errors='replace')[:800]}")
        return p

    def docker(self, *args, **kwargs):
        return self.command(["docker", *map(str, args)], **kwargs)

    def inspect(self, name):
        return json.loads(self.docker("inspect", name).stdout)[0]

    def start_container(self, role, arguments, image, command=()):
        name = self.prefix + "-" + role
        # Register before the Docker call: cancellation can arrive after the
        # daemon creates a container but before the CLI returns its ID.
        self.containers.append(name)
        self.docker("run", "-d", "--no-healthcheck", "--name", name, "--label", "org.quick.soak=" + self.run_id,
                    "--platform", "linux/" + self.profile["architecture"], *arguments, image, *command)
        return name

    def http(self, path, timeout=10, method="GET"):
        result = self.docker("exec", self.app, "curl", "--fail", "--silent", "--show-error",
                             "--max-time", str(timeout), "-X", method, "-H", "X-Soak-Token: " + self.env["SOAK_TOKEN"],
                             "http://127.0.0.1:8080" + path, check=False, timeout=timeout + 2)
        if result.returncode:
            raise urllib.error.URLError("Diagnostic request failed: " + result.stderr.decode(errors="replace")[:300])
        return json.loads(result.stdout)

    def wait_for(self, name, predicate, seconds):
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            state = self.inspect(name)["State"]
            if not state["Running"]:
                raise RuntimeError(f"{name} ended during setup: {state['ExitCode']}")
            try:
                if predicate():
                    return
            except (urllib.error.URLError, TimeoutError, ConnectionError):
                pass  # Startup readiness only; measured workload requests are never retried.
            time.sleep(1)
        raise TimeoutError(f"Readiness deadline exceeded for {name}")

    def setup(self):
        p = self.profile
        supported_runtime = {"lucee": "6.2.8+20", "coldbox": "8.2.0", "java": "21.0.10+7",
                             "jdbc": "8.0.33", "fullNull": True, "parallelEagerLoading": False}
        parallel_runtime = {**supported_runtime, "parallelEagerLoading": True,
                            "parallelEagerLoadingMaxThreads": 4, "parallelEagerLoadingQueueCapacity": 64,
                            "parallelEagerLoadingTimeout": 8000}
        if p["runtime"] not in (supported_runtime, parallel_runtime):
            raise Inconclusive("Unsupported runtime or eager-loading configuration")
        self.env["SOAK_PARALLEL"] = "true" if p["runtime"]["parallelEagerLoading"] else "false"
        if self.args.development:
            arch = self.docker("info", "--format", "{{.Architecture}}").stdout.decode().strip()
            p["architecture"] = {"aarch64": "arm64", "x86_64": "amd64"}.get(arch, arch)
            p["workload"].update(warmupSeconds=300, rampSeconds=15, plateauSeconds=180,
                                 recoverySeconds=15, idleSeconds=15, drainSeconds=10,
                                 sampleSeconds=5, windowSeconds=30, rate=5, vus=40,
                                 minimumFailuresPerCase=3, minimumLatencySamples=1, shortDevelopment=True)
            p["id"] += "-development"
        p["fault"] = self.args.fault
        self.env["SOAK_FAULT_MODE"] = self.args.fault
        w = p["workload"]
        delay = w["warmupSeconds"] + w["rampSeconds"] + (w["plateauSeconds"] - 20 if self.args.fault == "late-latency" else 60)
        self.env["SOAK_FAULT_DELAY_MS"] = str(delay * 1000)
        write_json(self.out / "profile.json", p)
        docker_info = json.loads(self.docker("info", "--format", "{{json .}}").stdout)
        self.cgroup_version = docker_info["CgroupVersion"]
        write_json(self.out / "host.json", {"docker": docker_info,
                   "cpu": json.loads(self.command(["lscpu", "--json"]).stdout) if platform.system() == "Linux" else
                          {"model": self.command(["sysctl", "-n", "machdep.cpu.brand_string"]).stdout.decode().strip()},
                   "runnerImage": os.environ.get("ImageOS"), "runnerImageVersion": os.environ.get("ImageVersion"),
                   "githubRunId": os.environ.get("GITHUB_RUN_ID"), "githubSha": os.environ.get("GITHUB_SHA")})
        source = self.out / "harness"
        source_hashes = {}
        for path in sorted(HERE.rglob("*")):
            if path.is_file() and not any(x in path.parts for x in (".engine", "modules", "coldbox", "logs", "__pycache__")):
                relative = path.relative_to(HERE)
                content = path.read_bytes()
                destination = source / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(content)
                source_hashes[str(relative)] = hashlib.sha256(content).hexdigest()
        write_json(self.out / "harness-manifest.json", source_hashes)
        app = self.out / "app"
        shutil.copytree(source / "app", app)
        shutil.copytree(source / "k6", self.out / "k6")
        shutil.copyfile(source / "docker/setup.sh", self.out / "setup.sh")
        shutil.copytree(source / "telemetry", self.out / "collector")
        for name in ("jvm", "tmp", "classes"):
            (self.out / name).mkdir()
        if self.args.package:
            manifest = json.loads((self.args.package / "package-manifest.json").read_text())
            verify(self.args.package, self.args.candidate or manifest["candidateSha"])
            shutil.copytree(self.args.package, self.out / "package")
        else:
            sha = self.command(["git", "-C", str(ROOT), "rev-parse", self.args.candidate or "HEAD"]).stdout.decode().strip()
            descriptor = json.loads(self.command(["git", "-C", str(ROOT), "show", sha + ":box.json"]).stdout)
            # Diagnostic packages cannot be promoted: real preparation must provide --package.
            build(ROOT, {"candidateSha": sha, "version": descriptor["version"],
                         "lastRelease": {"diagnosticOnly": True}, "notes": "## Diagnostic package; not prepared for publication"}, self.out / "package")
        server = json.loads((app / "server.json").read_text())
        server["name"] = self.prefix
        server["web"]["host"] = "0.0.0.0"
        server["web"]["http"]["port"] = 8080
        server["JVM"]["heapSize"] = p["resources"]["application"]["heapMiB"]
        server["JVM"]["minHeapSize"] = p["resources"]["application"]["heapMiB"]
        server["JVM"]["args"] += " -Xlog:gc*:file=/work/jvm/gc.log:time,uptime,level,tags:filecount=4,filesize=16M"
        write_json(app / "server.json", server)
        image = "quick-soak-runtime:" + p["architecture"]
        self.docker("build", "--platform", "linux/" + p["architecture"], "--build-arg", "SOURCE_DATE_EPOCH=0",
                    "-t", image, source / "docker", log="image-build.log", timeout=600)
        self.image = image
        resources = p["resources"]
        self.network = True
        self.docker("network", "create", "--internal", "--label", "org.quick.soak=" + self.run_id, self.prefix)
        self.volume = True
        self.docker("volume", "create", "--label", "org.quick.soak=" + self.run_id, self.prefix)
        self.db = self.start_container("mysql", ["--network", self.prefix, "--network-alias", "mysql",
            "--cpus", str(resources["mysql"]["cpus"]), "--memory", f'{resources["mysql"]["memoryMiB"]}m',
            "-e", "MYSQL_ROOT_PASSWORD", "-e", "MYSQL_USER=quick_soak", "-e", "MYSQL_PASSWORD"],
            p["images"]["mysql"], ["--max-connections=" + str(resources["mysql"]["maxConnections"]), "--performance-schema=ON"])
        self.wait_for(self.db, lambda: self.docker("exec", "-e", "MYSQL_PWD", self.db, "mysql", "--protocol=TCP", "-h127.0.0.1", "-uroot", "-N", "-e", "SELECT 1", check=False).returncode == 0, 120)
        self.command(["box", "version"], log="seed-commandbox-version.log", timeout=30)
        self.command(["box", "task", "run", "taskFile=" + str(source / "Seed.cfc"),
                      ":container=" + self.db, ":output=" + str(self.out / "fixtures")],
                     log="seed.log", timeout=180)
        self.docker("exec", "-e", "MYSQL_PWD", self.db, "mysql", "-uroot", "-e",
                    "GRANT ALL PRIVILEGES ON quick_soak.* TO 'quick_soak'@'%';", log="seed.log")
        # Only setup has Internet access for dependency resolution. The measured app network is internal.
        setup = self.start_container("setup", ["-v", f"{self.out}:/work", "--mount", f"type=volume,src={self.prefix},dst=/app,volume-nocopy"], image,
            ["sh", "/work/setup.sh"])
        deadline = time.monotonic() + 600
        while self.inspect(setup)["State"]["Running"]:
            if time.monotonic() > deadline:
                raise TimeoutError("Dependency installation timed out")
            time.sleep(2)
        self.docker("logs", setup, log="dependencies.log")
        if self.inspect(setup)["State"]["ExitCode"]:
            raise RuntimeError("Dependency installation failed; see dependencies.log")
        # Code and engine live on a Docker volume, avoiding host file-sharing
        # overhead. Retain installed dependencies separately as evidence.
        for directory in ("modules", "coldbox"):
            self.docker("cp", f"{setup}:/app/{directory}", app / directory)
        manifest = json.loads((self.out / "package/package-manifest.json").read_text())
        for name, expected in manifest["files"].items():
            if sha_file(app / "modules/quick" / name) != expected:
                raise RuntimeError("Installed candidate changed: " + name)
        dependencies = {str(path.relative_to(app)): {"version": json.loads(path.read_text()).get("version"), "sha256": sha_file(path)}
                        for path in app.rglob("box.json")}
        write_json(self.out / "dependencies.json", dependencies)
        dependency_files = {}
        for root in (app / "coldbox", app / "modules/quick/modules"):
            for path in sorted(root.rglob("*")):
                if path.is_file():
                    dependency_files[str(path.relative_to(app))] = sha_file(path)
        write_json(self.out / "dependency-files.json", dependency_files)
        write_json(self.out / "dependency-identity.json", {"sha256": sha_file(self.out / "dependency-files.json"),
                   "files": len(dependency_files)})
        self.app = self.start_container("app", ["--network", self.prefix, "--network-alias", "application",
            "--cpus", str(resources["application"]["cpus"]), "--memory", f'{resources["application"]["memoryMiB"]}m',
            "--memory-swap", f'{resources["application"]["memoryMiB"]}m',
            "-v", f"{self.out}:/work", "-v", f"{self.prefix}:/app", "-v", f"{app / 'logs'}:/app/logs", "-v", f"{self.out / 'tmp'}:/tmp",
            "-e", "SOAK_TOKEN", "-e", "SOAK_PARALLEL", "-e", "SOAK_FAULT_MODE", "-e", "SOAK_FAULT_DELAY_MS", "-e", "SOAK_DB_PASSWORD", "-e", "SOAK_DB_HOST=mysql", "-e", "SOAK_DB_PORT=3306",
            "-e", "SOAK_DB_POOL_LIMIT=" + str(resources["application"]["jdbcPoolLimit"])], image)
        self.wait_for(self.app, lambda: self.http("/health/ready").get("ready"), 240)
        self.initial_diag = self.http("/diagnostics")
        write_json(self.out / "initial-diagnostics.json", self.initial_diag)
        if self.initial_diag.get("appName") != "Quick release soak" or self.initial_diag.get("exceptionHandler") != "Api.onException":
            raise RuntimeError("The dedicated ColdBox configuration was not loaded")
        if self.initial_diag.get("parallelEagerLoading") != p["runtime"]["parallelEagerLoading"]:
            raise RuntimeError("Actual eager-loading mode differs from profile")
        self.app_pid = self.initial_diag["pid"]
        self.observer = self.start_container("collector", ["--pid", "container:" + self.app, "--network", "container:" + self.app,
            "--volumes-from", self.app, "--cpus", str(resources["collector"]["cpus"]), "--memory", f'{resources["collector"]["memoryMiB"]}m'], image,
            ["java", "-Xmx128m", "-Dsun.rmi.transport.tcp.responseTimeout=5000", "--add-modules", "jdk.attach,jdk.management.jfr", "-cp", "/work/classes",
             "Collector", str(self.app_pid), "/work/jvm", str(p["workload"]["sampleSeconds"]), "60"])
        self.wait_for(self.observer, lambda: (self.out / "jvm/ready").exists(), 45)
        write_json(self.out / "runtime-containers.json", [{"name": n, "image": self.inspect(n)["Image"],
                   "limits": {k: self.inspect(n)["HostConfig"][k] for k in ("Memory", "MemorySwap", "NanoCpus")}}
                   for n in (self.app, self.db, self.observer)])

    def collect(self):
        timestamp = int(time.time() * 1000)
        def app_sample():
            value = self.http("/diagnostics", timeout=5)
            if value["bootId"] != self.initial_diag["bootId"] or value["applicationStarts"] != 1:
                raise RuntimeError("Application lifecycle changed")
            if self.last_diag and value["uptimeMs"] <= self.last_diag["uptimeMs"]:
                raise RuntimeError("JVM uptime fell")
            self.last_diag = value
            return value
        def db_sample():
            sql = "SELECT COUNT(*) AS waits FROM performance_schema.data_lock_waits; SELECT COUNT(*) AS locks FROM performance_schema.data_locks; SELECT COALESCE(SUM(COUNT_STAR),0),COALESCE(SUM(SUM_TIMER_WAIT),0) FROM performance_schema.events_statements_summary_by_digest WHERE SCHEMA_NAME='quick_soak';"
            values = self.docker("exec", "-e", "MYSQL_PWD", self.db, "mysql", "-uroot", "-N", "-e", sql, timeout=5).stdout.decode().split()
            return dict(zip(("lockWaits", "locks", "queries", "queryTimePicoseconds"), map(int, values)))
        def resources():
            return [json.loads(x) for x in self.docker("stats", "--no-stream", "--format", "{{json .}}", self.app, self.db, self.observer, self.generator, timeout=8).stdout.decode().splitlines()]
        def native_memory():
            path = "/sys/fs/cgroup/memory.stat" if self.cgroup_version == "2" else "/sys/fs/cgroup/memory/memory.stat"
            raw = self.docker("exec", self.app, "cat", path, timeout=5).stdout.decode()
            return parse_memory_stat(raw, self.cgroup_version)
        row = {"time": timestamp}
        with ThreadPoolExecutor(max_workers=4) as pool:
            jobs = {key: pool.submit(fn) for key, fn in (("application", app_sample), ("database", db_sample), ("containers", resources), ("applicationMemory", native_memory))}
            for key, job in jobs.items():
                try:
                    row[key] = job.result()
                except Exception as exc:
                    row[key + "Error"] = str(exc)[:500]
        with (self.out / "observations.ndjson").open("a") as out:
            out.write(json.dumps(row) + "\n")
        if "applicationError" in row:
            raise RuntimeError(row["applicationError"])
        if any(key.endswith("Error") for key in row):
            raise Inconclusive("External telemetry failed; see observations.ndjson")
        if row["application"]["errors"]["unexpected"]:
            raise RuntimeError("Application recorded an unexpected exception")
        application_usage = next(item for item in row["containers"] if item["Name"] == self.app)
        if float(application_usage["MemPerc"].rstrip("%")) > 90:
            if self.memory_pressure_since is None:
                self.memory_pressure_since = timestamp
            elif timestamp - self.memory_pressure_since >= 120000:
                raise RuntimeError("Application memory exceeded 90% of its fixed budget for two minutes")
        else:
            self.memory_pressure_since = None
        for name in (self.app, self.db, self.observer):
            state = self.inspect(name)["State"]
            if state["OOMKilled"] or not state["Running"]:
                raise RuntimeError(f"Required process {name} stopped or OOMed")
        return row

    def run(self):
        self.setup()
        w = self.profile["workload"]
        r = self.profile["resources"]["generator"]
        self.env["SOAK_URL"] = "http://application:8080"
        self.env["SOAK_RUN_ID"] = self.run_id
        if self.args.fault != "none":
            write_json(self.out / "fault.json", self.http("/diagnostics/fault", method="POST"))
        self.measured_start = time.time()
        self.timing = {"controllerStartMs": int(self.measured_start * 1000),
                   "workloadSeconds": sum(w[k] for k in ("warmupSeconds", "rampSeconds", "plateauSeconds", "recoverySeconds")), "idleSeconds": w["idleSeconds"]}
        write_json(self.out / "timing.json", self.timing)
        self.generator = self.start_container("k6", ["--network", self.prefix, "--cpus", str(r["cpus"]), "--memory", f'{r["memoryMiB"]}m',
            "--user", "0", "-v", f"{self.out}:/work", "-e", "SOAK_TOKEN", "-e", "SOAK_URL", "-e", "SOAK_RUN_ID",
            "-e", "SOAK_PROFILE=/work/profile.json", "-e", "SOAK_FIXTURES=/work/fixtures/fixture-manifest.json", "-e", "SOAK_SUMMARY=/work/k6-summary.json"],
            self.profile["images"]["k6"], ["run", "--no-usage-report", "--out", "json=/work/k6.ndjson", "/work/k6/workload.mjs"])
        generator = self.inspect(self.generator)
        write_json(self.out / "generator.json", {"image": generator["Image"], "limits": {
            key: generator["HostConfig"][key] for key in ("Memory", "MemorySwap", "NanoCpus")}})
        self.summary["state"] = "measuring"
        write_json(self.out / "summary.json", self.summary)
        print("Measuring: " + str(self.out), flush=True)
        deadline = time.monotonic() + sum(w[k] for k in ("warmupSeconds", "rampSeconds", "plateauSeconds", "recoverySeconds")) + w["drainSeconds"] + 60
        while self.inspect(self.generator)["State"]["Running"]:
            sample_started = time.monotonic()
            self.collect()
            if time.monotonic() > deadline:
                raise TimeoutError("Generator exceeded declared duration and drain")
            time.sleep(max(0, sample_started + w["sampleSeconds"] - time.monotonic()))
        self.docker("logs", self.generator, log="k6.log")
        self.timing["generatorEndedMs"] = int(time.time() * 1000)
        with (self.out / "k6.ndjson").open() as stream:
            traffic = evaluate_traffic((json.loads(line) for line in stream if line.strip()), w, self.latency_baseline)
        write_json(self.out / "traffic-analysis.json", traffic)
        self.timing["warmupStartMs"] = traffic["phaseStartsMs"].get("warmup")
        self.timing["phaseStartsMs"] = traffic["phaseStartsMs"]
        write_json(self.out / "timing.json", self.timing)
        state = self.inspect(self.generator)["State"]
        observations = [json.loads(line) for line in (self.out / "observations.ndjson").read_text().splitlines()]
        delivery = evaluate_delivery(traffic, observations, self.profile, state)
        write_json(self.out / "delivery-analysis.json", delivery)
        if state["ExitCode"] != 0 or state["OOMKilled"]:
            reason = "; ".join(delivery["reasons"])
            if delivery["status"] == "failed":
                raise RuntimeError(reason)
            raise Inconclusive(reason)
        self.summary["state"] = "idle-observation"
        self.timing["idleStartedMs"] = int(time.time() * 1000)
        write_json(self.out / "timing.json", self.timing)
        write_json(self.out / "summary.json", self.summary)
        idle_end = time.monotonic() + w["idleSeconds"]
        while time.monotonic() < idle_end:
            sample_started = time.monotonic()
            self.collect()
            time.sleep(max(0, min(idle_end, sample_started + w["sampleSeconds"]) - time.monotonic()))
        final = self.http("/diagnostics")
        self.timing["idleFinishedMs"] = int(time.time() * 1000)
        write_json(self.out / "timing.json", self.timing)
        write_json(self.out / "final-diagnostics.json", final)
        self.summary.update(status="development-passed" if self.args.development else "inconclusive", state="complete",
                            reasons=[] if self.args.development else ["accepted-baseline-and-profile-qualification-required"])
        if delivery["status"] != "passed":
            self.summary.update(status=delivery["status"], reasons=delivery["reasons"])
        for field in ("scratchPosts", "jdbcActive", "jdbcWaiting", "queuedRequests"):
            if final[field] != 0:
                self.summary["status"] = "failed"
                self.summary["reasons"].append("final-resource-not-released:" + field)

    def analyze_resources(self):
        if self.summary.get("state") != "complete":
            return  # Canceled/aborted runs retain partial evidence and their original outcome.
        jvm = [json.loads(line) for line in (self.out / "jvm/jvm.ndjson").read_text().splitlines()]
        observations = [json.loads(line) for line in (self.out / "observations.ndjson").read_text().splitlines()]
        traffic = json.loads((self.out / "traffic-analysis.json").read_text())
        exits = {role: json.loads((self.out / (role + "-exit.json")).read_text()) for role in ("app", "mysql", "k6", "collector")}
        assessment = evaluate_resources(jvm, observations, self.profile, self.timing,
                                        plateau_start=traffic["plateauStartMs"], exits=exits)
        write_json(self.out / "resource-analysis.json", assessment)
        # Preserve proven hard failures even if later memory/report analysis
        # cannot finish because another part of the evidence is incomplete.
        if assessment["status"] != "passed":
            if self.summary["status"] != "failed":
                self.summary["status"] = assessment["status"]
            self.summary["reasons"].extend(assessment["failures"] + assessment["invalid"])
        w = self.profile["workload"]
        start = traffic["plateauStartMs"]
        memory = evaluate_memory(jvm, start_ms=start, end_ms=start + w["plateauSeconds"] * 1000,
            window_ms=w["windowSeconds"] * 1000, min_span_ms=1200000, reference_ms=600000,
            min_cycles=10, heap_max_bytes=self.profile["resources"]["application"]["heapMiB"] * 1024 * 1024,
            exclude_initial_ms=w["drainSeconds"] * 1000,
            noise_bytes=self.memory_baseline.get("noiseBytes", 0), baseline_bytes=self.memory_baseline.get("baselineBytes"))
        write_json(self.out / "memory-analysis.json", memory)
        if not self.args.development and memory["status"] != "passed":
            if self.summary["status"] != "failed":
                self.summary["status"] = memory["status"]
            self.summary["reasons"].extend(memory["reasons"])
        self.summary["assessments"] = {"traffic": traffic["status"], "resources": assessment["status"], "memory": memory["status"]}
        write_json(self.out / "summary.json", self.summary)

    def cleanup(self):
        # Every owned resource gets a cleanup attempt even when diagnostics fail.
        errors = []
        def attempt(label, fn):
            try:
                return fn()
            except Exception as exc:
                errors.append(label + ": " + str(exc)[:500])
                return None
        if hasattr(self, "generator"):
            attempt("stop arrivals", lambda: self.docker("stop", "--time", "10", self.generator, timeout=20))
        if self.app_pid and self.summary["status"] != "development-passed":
            attempt("thread dump", lambda: self.docker("exec", self.app, "jcmd", self.app_pid, "Thread.print",
                    log="failure-threads.txt", timeout=10))
        (self.out / "jvm/stop").parent.mkdir(exist_ok=True)
        (self.out / "jvm/stop").touch()
        if hasattr(self, "observer"):
            def drain_collector():
                deadline = time.monotonic() + 15
                while self.inspect(self.observer)["State"]["Running"] and time.monotonic() < deadline:
                    time.sleep(1)
            attempt("flush collector", drain_collector)
        for name in reversed(self.containers):
            role = name.removeprefix(self.prefix + "-")
            inspected = attempt("locate " + role, lambda: self.docker("inspect", name, check=False))
            if inspected is None:
                continue
            if inspected.returncode and b"No such object" in inspected.stderr:
                continue
            if inspected.returncode:
                errors.append("Cannot locate owned container " + role)
                continue
            if json.loads(inspected.stdout)[0]["Config"].get("Labels", {}).get("org.quick.soak") != self.run_id:
                errors.append("Refusing to stop container with a different ownership label: " + role)
                continue
            attempt("stop " + role, lambda: self.docker("stop", "--time", "10", name, timeout=20))
            attempt("logs " + role, lambda: self.docker("logs", name, log=role + ".log", timeout=10))
            if role == "app":
                attempt("engine logs", lambda: self.docker("cp", name + ":/app/.engine/WEB-INF/lucee-server/context/logs",
                                                           self.out / "engine-logs", timeout=10))
            state = attempt("inspect " + role, lambda: self.inspect(name))
            if state:
                # Never serialize Config.Env with per-run credentials.
                write_json(self.out / (role + "-exit.json"), state["State"])
                if role == "collector" and state["State"]["ExitCode"] != 0:
                    errors.append("Collector did not finish cleanly")
                write_json(self.out / (role + "-volumes.json"),
                           [{"name": mount["Name"], "destination": mount["Destination"]}
                            for mount in state["Mounts"] if mount["Type"] == "volume"])
            # -v removes anonymous image volumes (notably MySQL's data volume).
            # The named application volume is removed separately with its label.
            attempt("remove " + role, lambda: self.docker("rm", "-v", name))
        def remove_owned_resource(kind):
            inspected = self.docker(kind, "inspect", self.prefix, check=False)
            if inspected.returncode and b"no such" in inspected.stderr.lower():
                return
            if inspected.returncode:
                raise RuntimeError("Cannot inspect " + kind)
            if json.loads(inspected.stdout)[0].get("Labels", {}).get("org.quick.soak") != self.run_id:
                raise RuntimeError("Refusing to remove " + kind + " with a different ownership label")
            self.docker(kind, "rm", self.prefix)
        if self.network:
            attempt("remove network", lambda: remove_owned_resource("network"))
        if self.volume:
            attempt("remove volume", lambda: remove_owned_resource("volume"))
        if hasattr(self, "observer"):
            def verify_recording():
                if (self.out / "jvm/recording-final.jfr").stat().st_size == 0:
                    raise RuntimeError("Final recording is empty")
                with (self.out / "jvm/jvm.ndjson").open("rb") as stream:
                    stream.seek(max(0, stream.seek(0, 2) - 4096))
                    if b'"kind":"collectorEnd"' not in stream.read():
                        raise RuntimeError("Collector end marker is missing")
            attempt("verify flushed recording", verify_recording)
        self.summary["finishedAt"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
        if errors:
            self.summary["reasons"].extend("Cleanup incomplete: " + error for error in errors)
            if self.summary["status"] != "failed":
                self.summary["status"] = "inconclusive"
        write_json(self.out / "summary.json", self.summary)


def execute(controller):
    def cancel(signum, frame):
        raise KeyboardInterrupt(f"Canceled by signal {signum}")
    signal.signal(signal.SIGTERM, cancel)
    try:
        controller.run()
    except BaseException as exc:
        controller.summary.update(status="inconclusive" if isinstance(exc, (KeyboardInterrupt, Inconclusive)) else "failed",
                                  state="canceled" if isinstance(exc, KeyboardInterrupt) else "aborted",
                                  reasons=[str(exc) or type(exc).__name__])
        (controller.out / "failure.txt").write_text(traceback.format_exc())
        print(str(exc), file=sys.stderr, flush=True)
    finally:
        try:
            controller.cleanup()
        except BaseException as exc:
            controller.summary["reasons"].append("Cleanup incomplete: " + str(exc))
            if controller.summary["status"] != "failed":
                controller.summary["status"] = "inconclusive"
            write_json(controller.out / "summary.json", controller.summary)
        try:
            controller.analyze_resources()
            render_report(controller.out)
        except Exception as exc:
            controller.summary["reasons"].append("Analysis/report incomplete: " + str(exc))
            if controller.summary["status"] != "failed":
                controller.summary["status"] = "inconclusive"
            write_json(controller.out / "summary.json", controller.summary)
    if controller.summary['status'] != 'passed':
        controller.summary['releaseQualified'] = False
        write_json(controller.out / 'summary.json', controller.summary)
    print(json.dumps(controller.summary, indent=2), flush=True)
    return 0 if controller.summary["status"] in ("development-passed", "capacity-measured") else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", type=Path, default=HERE / "profiles/lucee6-serial.json")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--candidate")
    parser.add_argument("--package", type=Path, help="Verified prepared package directory; omitted for diagnostic-only builds")
    parser.add_argument("--development", action="store_true", help="Short plateau with full warmup; cannot qualify releases")
    parser.add_argument("--fault", choices=("none", "held-connection", "wrong-contract", "latency", "late-latency"),
                        default="none", help="Controlled diagnostic fault; requires --development")
    args = parser.parse_args()
    if args.fault != "none" and not args.development:
        parser.error("Controlled faults require --development and cannot qualify a release")
    return execute(Controller(args))


if __name__ == "__main__":
    sys.exit(main())
