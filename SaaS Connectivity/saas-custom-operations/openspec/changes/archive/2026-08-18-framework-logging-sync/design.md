## Context

The custom-operation framework exposes `ctx.log` and optional `config.logUrl` external POSTs. Framework internals already use `createFrameworkLogger`, but incoming-request logging bypasses the active logger, and SOD operations log via raw `console.log`. Console renders detail as one inline inspect string. Discovery locked a named detail map API, caller-owned truncation, in-place evolution, and full sync between stdout and `logUrl`.

## Goals / Non-Goals

**Goals:**

- Single emit path for all invoke-scoped logs (framework + operations + incoming request).
- Console and JSON POST share the same normalized `message` and `detail` after redaction and JSON-safe filtering.
- Pretty multiline console output with per-key labeled blocks.
- Migrate remaining operation `console.log/warn` call sites to the framework logger.
- JSON POST never throws due to unserializable detail values.

**Non-Goals:**

- Changing `FrameworkLogEvent` top-level field names (`detail` stays).
- Framework-enforced size limits or truncation (callers keep domain truncation, e.g. SOD HTML previews).
- Logging changes in `scripts/*` or codegen CLIs.
- New invoke config fields or connector-spec changes.
- Adding a separate `step` or event-type field — headline + named keys suffice.

## Decisions

### D1: Emit pipeline order

- **Choice:** `sanitizeForLog(detail)` → `normalizeDetailForJson(detail)` → `formatPrettyConsole(...)` → `buildJsonEvent(...)` → POST (if `logUrl`).
- **Reason:** One normalized detail value feeds both sinks; redaction before normalization avoids leaking secrets into circular placeholders.
- **Considered alternatives:** Separate redaction for console vs POST (rejected — security hardening already unified both sinks).

### D2: Detail map semantics

- **Choice:** Second argument is a named map; scalars allowed. Public type: `Record<string, unknown> | undefined`.
- **Reason:** Matches chosen call-site pattern; JSON `detail` stays a single object for collectors.
- **Considered alternatives:** Top-level flatten on JSON event (rejected — breaks existing schema); rename to `objects` (rejected — unnecessary fork).

### D3: JSON-safe normalization rules

- **Choice:** Omit keys whose values are `undefined`, functions, or symbols. Replace circular references with string `"[Circular]"`. Serialize `Error` instances as plain objects with `name`, `message`, `stack`. Convert `bigint` to string.
- **Reason:** Prevent `JSON.stringify` throws; preserve debuggability for errors.
- **Considered alternatives:** Fail the log call (rejected — must not fail invocation); silent omit for circular without placeholder (rejected — `"[Circular]"` aids debugging).

### D4: Pretty console layout

- **Choice:** Emit headline `[requestId] message` on first line. For each detail entry: scalars as `  key: value`; objects/arrays as `  key:` followed by indented `inspect(value)` block (depth null, TTY colors when available).
- **Reason:** Matches SOD two-arg console readability; scales to multiple named attachments.
- **Considered alternatives:** Single-line inline inspect (current — rejected); `console.log` with multiple arguments per key (acceptable implementation detail if output matches layout intent).

### D5: Incoming request

- **Choice:** Route through `createFrameworkLogger` / shared emit with `message: 'Incoming request'` and `detail: { command, input, config }`. Console renderer may wrap output in existing boxed section + spread JSON for operator UX; POST uses standard JSON event only.
- **Reason:** Same schema as all logs; full `sanitizeForLog` on config.
- **Considered alternatives:** Drop boxed layout (deferred — keep as console-only render mode).

### D6: Operation migration strategy

- **Choice:** Replace `sod-remediation/logging.ts` helpers to call `getActiveFrameworkLogger()` with headline + named map; inline `console.log` in `access-model-sod-remediation` → `ctx.log`; `preventive-sod-check` warn → `getActiveFrameworkLogger().warn`.
- **Reason:** Minimal API churn; preserves step-oriented messages as English headlines with structured keys.
- **Considered alternatives:** Pass `ctx.log` into every helper (acceptable where handler has ctx; use active logger elsewhere).

### D7: `postFrameworkLogEvent` consolidation

- **Choice:** Deprecate duplicate POST logic in favor of shared internal `emitLogEvent` used by `createFrameworkLogger` and incoming-request path.
- **Reason:** Single place for normalization and POST behavior.
- **Considered alternatives:** Keep parallel paths (rejected — drift caused current sync gap).

## Risks / Trade-offs

- [Risk] Prettier multiline logs break brittle test string matches → Mitigation: update specs to assert on structure (headline, key presence, redaction) not full single-line strings.
- [Risk] Larger console volume for multi-key detail → Mitigation: caller truncation unchanged; operators opt into verbosity.
- [Risk] Omitted unserializable keys confuse debugging → Mitigation: document normalization rules in README; use plain objects at call sites.
- [Trade-off] Incoming request console keeps box styling while JSON is flat → Accepted: console is for humans; collectors get structured detail.

## Migration Plan

1. Implement `normalizeDetailForJson` and pretty console formatter in `logger.ts`.
2. Refactor emit to shared internal function; wire incoming request through it.
3. Migrate operation logging modules; update unit tests.
4. Update README logging section.
5. Verify: `npm run typecheck`, `npm test`; manual spot-check with `logUrl` mock server.

**Rollback:** Revert logger and request-logging changes; operation migrations are independent commits if needed. No deploy or schema migration — connector bundle only.

## Open Questions

- None — boxed incoming-request console layout retained as console-only render mode per discovery.
