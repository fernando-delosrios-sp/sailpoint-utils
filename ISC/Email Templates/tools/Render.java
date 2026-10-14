import java.io.StringWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.apache.velocity.VelocityContext;
import org.apache.velocity.app.VelocityEngine;

/**
 * Renders Velocity templates against a mock ISC context.
 *
 * Usage: java -cp ... tools/Render.java <jobs.tsv>
 * Each job line: templateFile \t contextFile \t outFile
 * Context file lines: dotted.key \t value  (value prefixes: "list:" comma list, "int:", "bool:")
 * Exits non-zero if any template fails to parse or render.
 */
public class Render {

    public static class Util {
        private final Map<String, Object> identity;
        Util(Map<String, Object> identity) { this.identity = identity; }
        public Map<String, Object> getIdentityDetailsByID(Object id) { return identity; }
        public Map<String, Object> getUser(Object id) { return identity; }
    }

    public static class DateTool {
        public java.util.Date toDate(String format, Object value) {
            try {
                java.text.SimpleDateFormat f = new java.text.SimpleDateFormat(format);
                f.setTimeZone(java.util.TimeZone.getTimeZone("UTC"));
                return f.parse(String.valueOf(value));
            } catch (Exception e) {
                return null;
            }
        }
        public String format(String format, Object date) {
            if (!(date instanceof java.util.Date)) return null;
            return new java.text.SimpleDateFormat(format, java.util.Locale.ENGLISH).format((java.util.Date) date);
        }
    }

    public static class NumberTool {
        public Integer integer(Object value) {
            try { return Integer.valueOf(String.valueOf(value).trim()); } catch (Exception e) { return null; }
        }
    }

    public static class SpTools {
        public String formatDate(Object d, int a, int b) { return String.valueOf(d); }
        public String formatOffsetDateTimeForEmail(Object d) { return String.valueOf(d); }
    }

    @SuppressWarnings("unchecked")
    static void put(Map<String, Object> root, String dotted, Object value) {
        String[] parts = dotted.split("\\.");
        Map<String, Object> cur = root;
        for (int i = 0; i < parts.length - 1; i++) {
            cur = (Map<String, Object>) cur.computeIfAbsent(parts[i], k -> new LinkedHashMap<String, Object>());
        }
        cur.put(parts[parts.length - 1], value);
    }

    static Object parse(String raw) {
        if (raw.startsWith("list:")) {
            String body = raw.substring(5);
            return body.isEmpty() ? new ArrayList<String>() : new ArrayList<>(Arrays.asList(body.split(",")));
        }
        if (raw.startsWith("int:")) return Integer.parseInt(raw.substring(4));
        if (raw.startsWith("bool:")) return Boolean.parseBoolean(raw.substring(5));
        return raw;
    }

    @SuppressWarnings("unchecked")
    public static void main(String[] args) throws Exception {
        VelocityEngine engine = new VelocityEngine();
        engine.setProperty("runtime.log.log_invalid_references", "false");
        engine.init();

        int failures = 0;
        for (String job : Files.readAllLines(Path.of(args[0]), StandardCharsets.UTF_8)) {
            if (job.isBlank()) continue;
            String[] cols = job.split("\t");
            String template = Files.readString(Path.of(cols[0]), StandardCharsets.UTF_8);
            Map<String, Object> data = new HashMap<>();
            for (String line : Files.readAllLines(Path.of(cols[1]), StandardCharsets.UTF_8)) {
                int tab = line.indexOf('\t');
                if (tab > 0) put(data, line.substring(0, tab), parse(line.substring(tab + 1)));
            }
            VelocityContext ctx = new VelocityContext();
            data.forEach(ctx::put);
            Map<String, Object> identity = (Map<String, Object>) data.getOrDefault("identity", new HashMap<>());
            ctx.put("__util", new Util(identity));
            ctx.put("spTools", new SpTools());
            ctx.put("__dateTool", new DateTool());
            ctx.put("__numberTool", new NumberTool());
            StringWriter out = new StringWriter();
            try {
                engine.evaluate(ctx, out, cols[0], template);
                Files.writeString(Path.of(cols[2]), out.toString(), StandardCharsets.UTF_8);
            } catch (Exception e) {
                failures++;
                System.err.println("FAIL " + cols[0] + ": " + e.getMessage().split("\n")[0]);
            }
        }
        if (failures > 0) System.exit(1);
    }
}
