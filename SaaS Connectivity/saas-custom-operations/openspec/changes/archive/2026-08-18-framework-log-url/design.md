## Context

Custom operations run inside the ISC SaaS connector runtime or locally via spcx. Framework code logs diagnostics with direct `console.*` calls scattered across persist, test mode, request logging, and the `customOperation` wrapper. The canonical spec describes correlated operation logging via `ctx.log`, but `RequestContext` today exposes only persist, SDK clients, and `res`.

Invoke payloads carry optional `config` (connection fields, `testMode`) and `input` (`requestId` plus operation fields). Config resolves through `context.config`, spcx `_withConfig`, or bundled `readConfig()`.

Operators want optional delivery of structured log events to an HTTP endpoint (workflow middleware, log aggregator) while retaining stdout for local debugging.

## Goals / Non-Goals

**Goals:**

- Add optional `config.logUrl` resolved per invocation.
- Provide a framework logger that always logs to console and optionally POSTs JSON to `logUrl`.
- Expose the logger as `ctx.log` on `RequestContext`.
- Migrate framework and ISC helper `console.*` calls to the logger.
- Redact `token` (and Bearer-prefixed values) in external JSON payloads.
- Fire-and-forget external POST — failures must not fail operations.

**Non-Goals:**

- Authenticating to `logUrl` (custom headers, mTLS) in v1.
- Batching, buffering, or retry with backoff.
- Replacing `console.*` in scripts, codegen, or operation-specific logging modules (e.g. sod-remediation) unless trivial.
- Disabling console output when `logUrl` is set.
- Declaring `logUrl` in `connector-spec.json` sourceConfig (invoke-time only in v1).

## Decisions

### D1: logUrl placement

- **Choice:** Optional field on invoke `config` object (`config.logUrl`), not on operation typed input or manifest sourceConfig.
- **Reason:** Logging is a runtime/diagnostic concern, parallel to `testMode`; avoids polluting every operation signature.
- **Considered alternatives:** Per-operation input field — rejected (duplicate across operations); env var only — rejected (workflows need per-run URLs).

### D2: Logger module and API

- **Choice:** `createFrameworkLogger({ requestId, command?, logUrl? })` returning `{ info, warn, error }`. Methods accept `(message: string, detail?: unknown)`.
- **Reason:** Matches spec's `ctx.log.info` shape; testable factory; one instance per invocation.
- **Considered alternatives:** Global singleton — rejected (breaks concurrent invoke isolation); pass logger through every function manually without factory — rejected (error-prone).

### D3: Console formatting

- **Choice:** Console output remains human-readable strings: `[requestId] message` plus optional inspected detail (reuse patterns from existing logs). JSON structure applies only to external sink.
- **Reason:** Preserves operator familiarity with current stdout; external sink carries structure.
- **Considered alternatives:** JSON-only console when logUrl set — rejected per non-goal.

### D4: External POST transport

- **Choice:** `fetch(logUrl, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(event) })` without awaiting in the caller's critical path (void promise with `.catch(() => {})`).
- **Reason:** Node 18+ fetch available; minimal dependency; non-blocking.
- **Considered alternatives:** Sync POST — rejected (latency/failure risk); axios — rejected (unnecessary dependency).

### D5: Log event JSON schema

- **Choice:** `{ timestamp: ISO-8601, level: 'info'|'warn'|'error', requestId, command?: string, message: string, detail?: unknown }`. Apply `sanitizeForLog` / token redaction to `detail` and any nested config snapshots.
- **Reason:** Simple consumption by generic log collectors; aligns with existing ISC debug sanitization patterns.
- **Considered alternatives:** NDJSON stream to same URL — rejected (one POST per event is simpler for v1).

### D6: Wiring ctx.log

- **Choice:** `createRequestContext` receives optional `logger` or creates one from `logUrl` + `command`; attaches as `ctx.log`. `withCustomOperation` passes resolved `logUrl` from invoke config and `commandType` from context.
- **Reason:** Handlers get correlated logger without manual setup.
- **Considered alternatives:** Lazy getter on context — rejected (harder to inject in tests).

### D7: Request logging integration

- **Choice:** `printIncomingRequest` accepts optional logger; when present, calls `logger.info` with a short message and structured detail `{ command, input, config }` (redacted) for external sink while preserving existing formatted section output on console via the same logger's console path.
- **Reason:** Incoming request section stays readable; external sink gets parseable payload.
- **Considered alternatives:** Duplicate logging paths — rejected.

### D8: Migration scope

- **Choice:** Replace `console.*` in `src/framework/**` and `src/isc/accounts/find-account.ts`, `src/isc/debug/log-isc-request.ts`. Update `example` and `_template` operations to demonstrate `ctx.log`. Pass logger into modules that cannot access context (persist helpers) via parameter or invocation-scoped holder set by wrapper.
- **Reason:** Framework diagnostics benefit from external sink; scripts remain unchanged.
- **Considered alternatives:** ESLint rule banning console — deferred.

## Risks / Trade-offs

- [Risk] External POST volume on chatty persist logging → Mitigation: fire-and-forget; operators choose logUrl only when needed; no change when unset.
- [Risk] logUrl points to slow endpoint → Mitigation: non-awaited fetch; unbounded in-flight requests on very chatty logs → acceptable for v1; document.
- [Risk] PII in `detail` objects POSTed externally → Mitigation: token redaction; document that handlers must avoid logging secrets in `ctx.log` detail.
- [Trade-off] Silent external POST failures → Accept for v1; operation reliability prioritized over log delivery guarantees.

## Migration Plan

1. Add `logger.ts` with factory, console formatters, external POST, and sanitization.
2. Extend config resolution to expose optional `logUrl` (trimmed non-empty string).
3. Attach logger to `RequestContext`; wire through `withCustomOperation` and `createRequestContext`.
4. Migrate framework/ISC console calls; update request logging to use logger.
5. Update example/template operations to use `ctx.log`.
6. Add unit tests for logger (console always, POST when logUrl, redaction, failure non-fatal).
7. Update README invoke config documentation.
8. Run `npm test` and spot-check spcx invoke with mock logUrl server.

Rollback: remove logger module and revert console calls; no manifest or schema changes.

## Open Questions

None blocking. Future: auth headers for logUrl, env-based default logUrl, ESLint `no-console` in framework.
