## Why

Optional `config.logUrl` and `ctx.log` already deliver structured JSON alongside stdout for framework-routed logs, but several operation modules still call `console.log` directly — so remote collectors miss SOD step traces. Console output also crams `inspect(detail)` onto one line, and incoming-request logging uses a narrower redaction path than the dual-sink logger. Operators need every log event on both sinks with the same structured detail, readable multiline console layout, and JSON-safe encoding before POST.

## What Changes

**Unified emit pipeline**
- From: Incoming request uses `console.log` plus separate `postFrameworkLogEvent`; operations use raw `console.log` in SOD modules.
- To: All framework and operation logs route through one emit function: redact → JSON-safe normalize → pretty console → optional POST.
- Reason: Console and `logUrl` stay in sync; no silent gaps for remote collectors.
- Impact: Non-breaking for invoke contracts; stdout layout changes; more JSON events when `logUrl` is set.

**Named detail map convention**
- From: Second argument to `ctx.log` is an untyped optional blob; console renders as a single inline inspect string.
- To: Document and type `detail` as a named map (objects, arrays, scalars). Console prints a headline line plus labeled multiline blocks per key; JSON POST uses the same map in `detail` verbatim after redaction and JSON-safe normalization.
- Reason: Supports `ctx.log.info('violation loaded', { violation, controls, count: 3 })` with queryable remote payloads.
- Impact: Non-breaking signature; existing flat detail objects continue to work.

**JSON-safe detail normalization**
- From: `JSON.stringify` on detail can throw on circular refs or drop semantics unpredictably.
- To: Framework normalizes detail before emit: omit functions and symbols; omit undefined values; replace circular references with `"[Circular]"`; serialize `Error` as `{ name, message, stack }`.
- Reason: Prevent POST crashes and keep both sinks consistent.
- Impact: Non-breaking; some previously logged keys may be omitted.

**Pretty console formatting**
- From: `[requestId] message { inline inspect of entire detail }`.
- To: `[requestId] message` headline, then per-key labeled blocks using Node `inspect` with depth and TTY colors; scalars render inline after the key label.
- Reason: Operator readability for large SOD traces.
- Impact: Test assertions on log line format will need updates.

**Incoming request parity**
- From: Token-only redaction via `redactConfigForLogging`; split console/POST paths.
- To: Same `message` + `detail` envelope as other logs; full `sanitizeForLog` on config; optional boxed section styling on console only.
- Reason: One schema for collectors; consistent sensitive-field policy.
- Impact: Stricter redaction on incoming-request external events (improvement).

**Operation console migration**
- From: `sod-remediation/logging.ts`, `access-model-sod-remediation/index.ts`, and `preventive-sod-check/resolve-input.ts` use direct `console.log/warn`.
- To: Use `ctx.log` or `getActiveFrameworkLogger()` with named detail maps.
- Reason: Remote sync for operation step logs.
- Impact: Non-breaking; SOD log tests updated.

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `custom-operation-framework`: Unified emit pipeline; pretty console formatting; JSON-safe detail normalization; named detail map semantics; incoming request through same logger; require operation logs to use framework logger (no direct console in operations).
- `connector-config`: README documents named detail map convention and JSON-safe behavior for `logUrl` consumers.

## Impact

- **Code:** `src/framework/logger.ts`, `request-logging.ts`, `with-custom-operation.ts`, operation logging modules under `sod-remediation`, `access-model-sod-remediation`, `preventive-sod-check`; related `*.spec.ts` files.
- **APIs:** No connector-spec or invoke schema changes; `FrameworkLogger` detail typed as `Record<string, unknown>`.
- **Dependencies:** None.
- **Docs:** README Operation logging section — detail map convention, console layout, JSON-safe rules.
- **Breaking:** None for invoke contracts; stdout formatting changes only.
