import java.nio.file.*;
import java.util.*;

/** Controlled detector input only. Never loaded into the soak application. */
public final class MeasurementPilot {
    private static volatile byte[] sink;
    private static final List<byte[]> retained = new ArrayList<>();

    public static void main(String[] args) throws Exception {
        Path control = Path.of(args[0]);
        String fault = args[1];
        if (!Set.of("healthy", "leak", "late-leak").contains(fault)) throw new IllegalArgumentException(fault);
        Files.writeString(control.resolve("target-ready"), Long.toString(ProcessHandle.current().pid()));
        while (!Files.exists(control.resolve("start"))) Thread.sleep(50);
        long start = System.nanoTime();
        while (!Files.exists(control.resolve("target-stop"))) {
            double elapsed = (System.nanoTime() - start) / 1e9;
            // Constant allocation churn in both cases; only the retained reference differs.
            for (int i = 0; i < 64; i++) {
                byte[] value = new byte[64 * 1024];
                Arrays.fill(value, (byte) i);
                sink = value;
            }
            if ((fault.equals("leak") && elapsed >= 15 && elapsed < 75)
                || (fault.equals("late-leak") && elapsed >= 60 && elapsed < 75)) {
                byte[] value = new byte[(fault.equals("late-leak") ? 512 : 128) * 1024];
                Arrays.fill(value, (byte) 7);
                retained.add(value);
            }
            Thread.sleep(100);
        }
    }
}
