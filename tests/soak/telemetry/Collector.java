import com.sun.tools.attach.VirtualMachine;
import java.io.*;
import java.lang.management.*;
import java.nio.file.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.atomic.AtomicBoolean;
import javax.management.*;
import javax.management.remote.*;
import jdk.management.jfr.RemoteRecordingStream;

/** External observer: no application endpoint, forced GC, or heap dump is needed. */
public final class Collector {
    private static PrintWriter output;
    private static final AtomicBoolean stopping = new AtomicBoolean();
    private static final AtomicBoolean failed = new AtomicBoolean();

    private static String quote(String s) {
        return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"")
            .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t") + "\"";
    }

    private static synchronized void emit(Map<String, Object> values) {
        var fields = new ArrayList<String>();
        for (var e : values.entrySet()) {
            Object v = e.getValue();
            fields.add(quote(e.getKey()) + ":" + ((v instanceof Number || v instanceof Boolean)
                ? v.toString() : quote(v.toString())));
        }
        output.println("{" + String.join(",", fields) + "}");
        output.flush();
        if (output.checkError()) throw new UncheckedIOException(new IOException("Telemetry write failed"));
    }

    private static Map<String, Object> row(String kind, long time) {
        var r = new LinkedHashMap<String, Object>();
        r.put("kind", kind);
        r.put("time", time);
        return r;
    }

    private static long residentBytes(String pid) throws Exception {
        var status = Path.of("/proc", pid, "status");
        if (Files.exists(status)) {
            for (String line : Files.readAllLines(status)) {
                if (line.startsWith("VmRSS:")) return Long.parseLong(line.trim().split("\\s+")[1]) * 1024;
            }
            throw new IOException("VmRSS missing");
        }
        var process = new ProcessBuilder("ps", "-o", "rss=", "-p", pid).start();
        String value = new String(process.getInputStream().readAllBytes()).trim();
        if (process.waitFor() != 0 || value.isEmpty()) throw new IOException("Cannot sample target RSS");
        return Long.parseLong(value) * 1024;
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 4) throw new IllegalArgumentException("Collector PID OUTPUT_DIR SAMPLE_SECONDS DUMP_SECONDS");
        String pid = args[0];
        Path dir = Path.of(args[1]).toAbsolutePath();
        Files.createDirectories(dir.resolve("stream"));
        int interval = Integer.parseInt(args[2]);
        int dumpInterval = Integer.parseInt(args[3]);
        if (interval < 1 || dumpInterval < interval) throw new IllegalArgumentException("Invalid intervals");
        output = new PrintWriter(Files.newBufferedWriter(dir.resolve("jvm.ndjson"), StandardOpenOption.CREATE_NEW));
        Runtime.getRuntime().addShutdownHook(new Thread(() -> stopping.set(true)));
        VirtualMachine vm = VirtualMachine.attach(pid);
        String address;
        try { address = vm.startLocalManagementAgent(); } finally { vm.detach(); }
        try (var connector = JMXConnectorFactory.connect(new JMXServiceURL(address))) {
            var connection = connector.getMBeanServerConnection();
            var runtime = ManagementFactory.newPlatformMXBeanProxy(connection, ManagementFactory.RUNTIME_MXBEAN_NAME, RuntimeMXBean.class);
            var memory = ManagementFactory.newPlatformMXBeanProxy(connection, ManagementFactory.MEMORY_MXBEAN_NAME, MemoryMXBean.class);
            var threads = ManagementFactory.newPlatformMXBeanProxy(connection, ManagementFactory.THREAD_MXBEAN_NAME, ThreadMXBean.class);
            var os = ManagementFactory.newPlatformMXBeanProxy(connection, ManagementFactory.OPERATING_SYSTEM_MXBEAN_NAME, com.sun.management.UnixOperatingSystemMXBean.class);
            var pools = ManagementFactory.getPlatformMXBeans(connection, MemoryPoolMXBean.class);
            var collectors = ManagementFactory.getPlatformMXBeans(connection, GarbageCollectorMXBean.class);
            var manifest = row("runtime", System.currentTimeMillis());
            manifest.put("pid", pid);
            manifest.put("javaVersion", runtime.getSystemProperties().get("java.runtime.version"));
            manifest.put("vm", runtime.getVmName());
            manifest.put("os", os.getName());
            manifest.put("arch", os.getArch());
            manifest.put("processors", os.getAvailableProcessors());
            manifest.put("physicalMemoryBytes", os.getTotalMemorySize());
            manifest.put("arguments", String.join(" ", runtime.getInputArguments()));
            manifest.put("collectors", String.join(",", collectors.stream().map(GarbageCollectorMXBean::getName).toList()));
            manifest.put("startTime", runtime.getStartTime());
            manifest.put("collectorHeapMax", Runtime.getRuntime().maxMemory());
            emit(manifest);
            try (var stream = new RemoteRecordingStream(connection, dir.resolve("stream"))) {
                stream.setMaxSize(64L * 1024 * 1024);
                stream.setMaxAge(Duration.ofMinutes(10));
                stream.enable("jdk.GCHeapSummary");
                stream.enable("jdk.GarbageCollection");
                stream.enable("jdk.GCPhasePause").withoutThreshold();
                stream.enable("jdk.CPULoad").withPeriod(Duration.ofSeconds(interval));
                stream.enable("jdk.ObjectAllocationSample").with("throttle", "100/s");
                // Exception counts and samples live in a bounded JFR, never in an application array.
                stream.enable("jdk.JavaExceptionThrow").withoutStackTrace();
                stream.onEvent("jdk.GCHeapSummary", e -> {
                    var r = row("heap", e.getStartTime().toEpochMilli());
                    r.put("gcId", e.getLong("gcId"));
                    r.put("when", e.getString("when"));
                    r.put("heapUsed", e.getLong("heapUsed"));
                    emit(r);
                });
                stream.onEvent("jdk.GarbageCollection", e -> {
                    var r = row("gc", e.getEndTime().toEpochMilli());
                    r.put("gcId", e.getLong("gcId"));
                    r.put("name", e.getString("name"));
                    r.put("cause", e.getString("cause"));
                    r.put("durationMs", e.getDuration().toNanos() / 1e6);
                    emit(r);
                });
                stream.onEvent("jdk.GCPhasePause", e -> {
                    var r = row("pause", e.getStartTime().toEpochMilli());
                    r.put("gcId", e.getLong("gcId"));
                    r.put("durationMs", e.getDuration().toNanos() / 1e6);
                    emit(r);
                });
                stream.onError(e -> {
                    failed.set(true);
                    var r = row("collectorError", System.currentTimeMillis());
                    r.put("error", e.toString());
                    emit(r);
                });
                stream.startAsync();
                Files.writeString(dir.resolve("ready"), pid, StandardOpenOption.CREATE_NEW);
                long lastDump = System.nanoTime();
                while (!stopping.get() && !failed.get()) {
                    var r = row("sample", System.currentTimeMillis());
                    r.put("uptimeMs", runtime.getUptime());
                    r.put("heapUsed", memory.getHeapMemoryUsage().getUsed());
                    r.put("heapCommitted", memory.getHeapMemoryUsage().getCommitted());
                    r.put("heapMax", memory.getHeapMemoryUsage().getMax());
                    r.put("nonHeapUsed", memory.getNonHeapMemoryUsage().getUsed());
                    for (var pool : pools) if (pool.getName().equals("Metaspace")) r.put("metaspaceUsed", pool.getUsage().getUsed());
                    r.put("threads", threads.getThreadCount());
                    r.put("descriptors", os.getOpenFileDescriptorCount());
                    r.put("processCpuLoad", os.getProcessCpuLoad());
                    r.put("processCpuTimeNs", os.getProcessCpuTime());
                    r.put("rssBytes", residentBytes(pid));
                    var observerHeap = ManagementFactory.getMemoryMXBean().getHeapMemoryUsage();
                    r.put("collectorHeapUsed", observerHeap.getUsed());
                    r.put("collectorHeapCommitted", observerHeap.getCommitted());
                    emit(r);
                    if (System.nanoTime() - lastDump >= dumpInterval * 1_000_000_000L) {
                        Path next = dir.resolve("recording-next.jfr");
                        stream.dump(next);
                        Files.move(next, dir.resolve("recording.jfr"), StandardCopyOption.REPLACE_EXISTING);
                        lastDump = System.nanoTime();
                    }
                    // File-based stop lets the controller flush before terminating the target JVM.
                    if (Files.exists(dir.resolve("stop"))) break;
                    Thread.sleep(interval * 1000L);
                }
                stream.stop();
                stream.dump(dir.resolve("recording-final.jfr"));
                emit(row("collectorEnd", System.currentTimeMillis()));
            }
        } finally { output.close(); }
        if (failed.get()) System.exit(1);
    }
}
