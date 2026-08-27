## Why

Local connector debugging via `npm run debug` and workflow invoke troubleshooting lack a single entry-point log of the full invoke envelope. Operators must infer request shape from scattered handler logs or run `test:operation` separately. Additionally, per-invoke `config` sent to spcx was invisible to both logging and handlers because the ncc-bundled connector uses a separate `readConfig()` AsyncLocalStorage store from the spcx dev server. This change adds default readable request logging and fixes invoke config resolution so config appears in logs and reaches handlers during local development.

## What Changes

**Default incoming request logging**
- From: No framework-level log of invoke payloads at command entry.
- To: Every registered command logs command, input, and resolved config (token redacted) in fixture-style formatted output before handler execution.
- Reason: Match `test:operation` readability for live connector runs.
- Impact: Non-breaking; adds stdout output on every invocation.

**Invoke config resolution**
- From: `resolveInvocationConfig` uses bundled `readConfig()` only; spcx `_withConfig` config invisible to bundled connector.
- To: Shared `readInvokeConfig()` tries external node_modules SDK `readConfig()` first (spcx AsyncLocalStorage), then bundled `readConfig()` (production CONNECTOR_CONFIG).
- Reason: Per-invoke config in spcx POST body must reach handlers and request logs.
- Impact: Non-breaking; fixes local dev when config is supplied in invoke body.

**Shared JSON formatting**
- From: `formatSpreadJson` lives only in `scripts/fixture-output.ts`.
- To: Extracted to `src/framework/pretty-json.ts`; fixture runner re-exports.
- Reason: Consistent formatting between `test:operation` and connector logging.
- Impact: Non-breaking refactor.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `custom-operation-framework`: Add default incoming request logging at command registration; add invoke config resolution for spcx/bundled SDK split; token redaction in request logs.
- `connector-config`: Document spcx debug invoke envelope and default request logging behavior in README.

## Impact

- **Code:** `src/framework/request-logging.ts`, `src/framework/invoke-config.ts`, `src/framework/pretty-json.ts`, `src/framework/test-mode.ts`, `src/operations/index.ts`, `scripts/fixture-output.ts`, `src/framework/index.ts`, unit tests.
- **APIs:** No connector-spec or invoke contract changes.
- **Dependencies:** No new packages.
- **Docs:** README Development section — request logging and spcx invoke shape.
- **Breaking:** None.
