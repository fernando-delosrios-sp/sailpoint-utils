## Context

Custom operations are invoked via ISC workflows or locally via spcx (`npm run debug`). Invoke payloads carry `type`, optional `config` (apiUrl, token, sourceName, testMode), and `input`. spcx wraps each POST in `_withConfig(cmd.config)` so handlers resolve config via `readConfig()`.

The connector is bundled with ncc, which inlines `@sailpoint/connector-sdk`. spcx uses the external SDK copy for `_withConfig`. Bundled and external copies maintain separate AsyncLocalStorage stores — bundled `readConfig()` never sees spcx's per-invoke config. The fixture runner (`test:operation`) bypasses this by setting `context.config` directly.

Existing framework logging covers handler-scoped `ctx.log` correlation and test-mode persist summaries, but not the raw invoke envelope at entry.

## Goals / Non-Goals

**Goals:**

- Log every incoming invoke (command, input, resolved config) before handler execution.
- Use fixture-style readable formatting (section headers, spread JSON).
- Redact `config.token` in log output.
- Resolve invoke config correctly under spcx dev (external SDK) and ISC production (bundled CONNECTOR_CONFIG).
- Share JSON pretty-print helper with fixture runner.

**Non-Goals:**

- Logging invoke responses (fixture runner already covers post-run output).
- Opt-out env var or log level configuration in v1.
- Redacting secrets beyond `config.token`.
- Changing connector-spec.json or invoke API contract.

## Decisions

### D1: Command registration wrapper

- **选择:** `wrapConnectorWithRequestLogging()` patches `connector.command()` in `registerCommands` to wrap every handler with `withRequestLogging`.
- **理由:** Automatic coverage for auto-discovered and manually registered commands; no per-operation changes.
- **已考虑 alternative:** Logging inside `customOperation` only — rejected; misses logging before config parse failures and non-customOperation handlers.

### D2: Request log format

- **选择:** `formatIncomingRequest()` emits sectioned output matching `test:operation` style: header line (command, requestId, testMode), then spread JSON of `{ command, input, config }`.
- **理由:** Operators already familiar with fixture runner output.
- **已考虑 alternative:** Raw `JSON.stringify` — rejected; harder to scan.

### D3: Invoke config resolution (spcx/bundle split)

- **选择:** `readInvokeConfig()` in `invoke-config.ts` tries `readExternalInvokeConfig()` via `createRequire(process.cwd()/package.json)` → node_modules SDK, then bundled `readConfig()`.
- **理由:** spcx sets AsyncLocalStorage on external SDK; production runtime sets CONNECTOR_CONFIG read by bundled copy.
- **已考虑 alternative:** Externalize connector-sdk in ncc build — rejected; larger packaging change, out of scope.

### D4: Shared config resolver for handlers

- **选择:** `resolveInvocationConfig` default `readConfigFn` becomes `readInvokeConfig`.
- **理由:** Same root cause affects handlers and logging; single fix path.
- **已考虑 alternative:** Fix logging only — rejected; handlers still fail with "Missing required config fields" under spcx.

### D5: Token redaction

- **选择:** Replace non-empty `config.token` with `[REDACTED]` before logging.
- **理由:** Prevent credential leakage in dev server stdout.
- **已考虑 alternative:** Omit config entirely — rejected per operator request to see config fields.

## Risks / Trade-offs

- [Risk] Production ISC runtime logs every invoke to stdout → Mitigation: acceptable for workflow-debug connector; document behavior; consider opt-out in future if noisy.
- [Risk] `createRequire` fails when cwd is not project root → Mitigation: falls back to bundled readConfig; production path unaffected.
- [Trade-off] Always-on logging vs configurable → Accept for v1 simplicity.

## Migration Plan

1. Add framework modules (`pretty-json`, `invoke-config`, `request-logging`).
2. Wire `wrapConnectorWithRequestLogging` in `registerCommands`.
3. Update `resolveInvocationConfig` to use `readInvokeConfig`.
4. Extract shared formatter; update fixture runner import.
5. Add unit tests; verify with `npm test`, spcx curl invoke with config block.
6. Update README Development section.

Rollback: revert `registerCommands` wrapper and `readInvokeConfig` default; no schema or manifest changes.

## Open Questions

None blocking.
