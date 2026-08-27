## Scope

Add an optional framework `logUrl` config field and a dual-sink logger that always writes human-readable lines to stdout and, when configured, POSTs structured JSON log events to that URL. Replace direct `console.log` / `console.warn` / `console.error` usage in framework and ISC helper code with the logger; expose the same logger on `RequestContext` as `ctx.log` for operation handlers.

Out of scope: scripts (`scripts/`), codegen output, and operation-specific logging that already uses dedicated helpers (e.g. sod-remediation `logging.ts`) unless they are migrated opportunistically to `ctx.log` in a follow-up.

## Language

**logUrl** (`promote`):
Optional invoke-config URL that receives structured JSON log events from the custom-operation framework when set.
_Avoid_: log endpoint, remote logger URL (use `logUrl` verbatim in config and types)

**External log sink** (`draft`):
The HTTP POST destination derived from `logUrl`; receives one JSON object per log event.
_Avoid_: webhook, telemetry backend

**Framework logger** (`draft`):
The dual-sink logging abstraction used by framework code and exposed as `ctx.log` on `RequestContext`. Always emits to console; optionally emits JSON to the external log sink when `logUrl` is configured.
_Avoid_: ctx.logger, LoggerService

**Log event** (`draft`):
A single structured JSON record sent to the external log sink, including correlation fields (`requestId`, `command`, `level`, `message`, `timestamp`) and optional serializable detail payload.
_Avoid_: log line, log entry (prefer **log event** for JSON records)

## Decisions

**Context:** Operators debugging workflow runs need correlated logs in stdout today, but ISC SaaS runtime stdout is not always easily searchable. An optional external log URL lets workflows or middleware collect structured events without losing local console output.

**Q1 — Where does `logUrl` live?** Config vs operation input vs env var.
→ **Config field** on the invoke envelope (`config.logUrl`), optional, alongside `testMode`. Same resolution path as other invoke config (`context.config`, spcx `_withConfig`, bundled `readConfig`). Not duplicated on every operation's typed input.

**Q2 — Which console calls migrate?** All project `console.*` vs framework-only.
→ **Framework and ISC helper modules** under `src/framework/` and `src/isc/` (persist, debug). Operations migrate from raw `console.log` to `ctx.log` where they run inside `customOperation`; scripts and codegen keep direct console output.

**Q3 — External delivery semantics?** Sync POST vs fire-and-forget vs batching.
→ **Fire-and-forget async POST** per log event. Failures MUST NOT fail the operation; failed posts are ignored (optionally logged once to console at debug level — defer to design). No batching in v1.

**Q4 — JSON shape?** Plain string vs structured envelope.
→ **Structured JSON object** per event: `{ timestamp, level, requestId, command?, message, detail? }`. Sensitive values (token, raw Authorization) MUST be redacted before external POST, matching existing request-log redaction policy for `token`.

**Q5 — Log levels?** console.log only vs warn/error too.
→ **Mirror console levels**: `info` (console.log), `warn`, `error`. Incoming request logging and test-mode summaries use the framework logger.

**Q6 — Implement existing spec gap?** Spec references `ctx.log.info` but `RequestContext` has no `log` today.
→ **Yes** — this change implements `ctx.log` on `RequestContext` backed by the same framework logger instance created per invocation.

## Open questions

None blocking — deferred non-goals: logUrl authentication headers, retry/backoff, opt-out of console when logUrl is set, redacting fields beyond `token`.

## Scenarios discussed

- **logUrl absent:** Logger behaves as console-only; zero network I/O; no behavior change for existing invokes except log message formatting may include consistent `[requestId]` prefixes.
- **logUrl present but unreachable:** Operation completes; external POST fails silently; console output unaffected.
- **Test mode with logUrl:** Test-mode persist summaries and ISC status lines also POST to logUrl when configured.
- **Incoming request log:** Existing formatted incoming-request section still prints to console; a companion JSON event (or parsed summary fields) POSTs to logUrl when set; token redacted in both sinks.
- **Concurrent invokes:** Each invocation gets its own logger instance scoped to its `requestId` and `command`; no shared mutable logger state.
- **Offline test mode (no config):** `logUrl` unavailable; console-only path.
- **Operation handler logging:** Handler calls `ctx.log.info('step complete', { count: 3 })` → console line + optional JSON POST with detail object.
