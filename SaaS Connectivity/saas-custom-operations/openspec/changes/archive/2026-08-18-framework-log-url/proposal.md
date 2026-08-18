## Why

Custom operation logs today go only to connector stdout. In ISC SaaS workflow runs, stdout is hard to search and correlate across steps. Operators need optional structured log delivery to an external HTTP endpoint without losing local console output for spcx and `npm run debug`. The framework spec already describes `ctx.log` correlation, but `RequestContext` does not expose a logger yet — this change closes that gap and adds optional remote collection via `logUrl`.

## What Changes

**Optional `logUrl` invoke config**
- From: No framework field for external log delivery.
- To: Optional `config.logUrl` string on the invoke envelope, resolved via the same config path as `apiUrl`, `token`, and `sourceName`.
- Reason: Workflows and middleware can POST structured events to a collector URL when configured.
- Impact: Non-breaking; absent `logUrl` preserves current console-only behavior.

**Dual-sink framework logger**
- From: Framework and ISC helpers call `console.log`, `console.warn`, and `console.error` directly; `RequestContext` has no `log` property.
- To: Shared framework logger always writes human-readable lines to console and, when `logUrl` is set, fire-and-forget POSTs one JSON log event per call. `RequestContext` exposes `ctx.log` with `info`, `warn`, and `error` methods backed by the same instance.
- Reason: Single logging path with correlation and optional external sink.
- Impact: Non-breaking for invoke contracts; log line formatting may gain consistent `[requestId]` prefixes.

**Console call migration in framework code**
- From: Direct `console.*` in `src/framework/` and selected `src/isc/` helpers (persist, debug).
- To: Those modules use the framework logger; incoming request logging, test-mode summaries, persist traces, and wrapper lifecycle logs route through it.
- Reason: External sink applies uniformly to framework diagnostics.
- Impact: Non-breaking; scripts and codegen keep direct console output.

**Sensitive value redaction**
- From: Token redaction exists only for incoming request log formatting.
- To: External JSON log events apply the same token redaction policy before POST.
- Reason: Prevent credential leakage to third-party log endpoints.
- Impact: Non-breaking.

## Capabilities

### New Capabilities

_(none — behavior extends existing framework and config capabilities)_

### Modified Capabilities

- `custom-operation-framework`: Implement `ctx.log`; add dual-sink framework logger; optional `logUrl` external POST; migrate framework/ISC helper console calls; extend operation logging and incoming request logging requirements.
- `connector-config`: Document optional `logUrl` on invoke config and external JSON log event behavior in README.
- `ubiquitous-language`: Add `logUrl` term entry.

## Impact

- **Code:** New `src/framework/logger.ts` (or equivalent), `request-context.ts`, `with-custom-operation.ts`, `request-logging.ts`, `persist-result.ts`, `test-mode-persist.ts`, `failure-persist.ts`, `result-source.ts`, `attribute-limits.ts`, `src/isc/accounts/find-account.ts`, `src/isc/debug/log-isc-request.ts`, `src/framework/index.ts`, example/template operations (`ctx.log` migration), unit tests.
- **APIs:** No connector-spec command changes; optional invoke `config.logUrl` only.
- **Dependencies:** Uses Node built-in `fetch` (or existing HTTP client if project already depends on one — prefer built-in).
- **Docs:** README Development / invoke config section — `logUrl` optional field and JSON event shape.
- **Breaking:** None.
