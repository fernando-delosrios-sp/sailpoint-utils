## 1. Framework logger module

- [x] 1.1 Add `src/framework/logger.ts` with `createFrameworkLogger({ requestId, command?, logUrl? })` exposing `info`, `warn`, and `error`
- [x] 1.2 Implement console formatting with `[requestId]` correlation prefix on every line
- [x] 1.3 Implement fire-and-forget JSON POST to `logUrl` with `{ timestamp, level, requestId, command?, message, detail? }` schema
- [x] 1.4 Reuse or extract sanitization so token and Bearer values are redacted in external `detail` payloads
- [x] 1.5 Export logger types and factory from `src/framework/index.ts`

## 2. Config resolution and context wiring

- [x] 2.1 Parse optional `logUrl` from invoke config (trim; treat empty as unset) alongside existing config resolution paths
- [x] 2.2 Attach `log: FrameworkLogger` to `RequestContext` in `createRequestContext`
- [x] 2.3 Wire `withCustomOperation` to create/pass logger scoped to `requestId`, `commandType`, and resolved `logUrl`
- [x] 2.4 Provide invocation-scoped logger access for modules without direct context (persist, failure-persist, test-mode) via parameter or scoped holder set by wrapper

## 3. Migrate framework console calls

- [x] 3.1 Replace `console.*` in `with-custom-operation.ts`, `request-logging.ts`, `persist-result.ts`, `test-mode-persist.ts`, `failure-persist.ts`, `result-source.ts`, and `attribute-limits.ts`
- [x] 3.2 Replace `console.*` in `src/isc/accounts/find-account.ts` and `src/isc/debug/log-isc-request.ts`
- [x] 3.3 Update `printIncomingRequest` / `withRequestLogging` to accept logger and emit structured detail for external sink while preserving formatted Incoming request console section
- [x] 3.4 Update `example` and `_template` operations to use `ctx.log` instead of raw `console.log`

## 4. Unit tests

- [x] 4.1 Add `src/framework/logger.spec.ts` — console always called; POST when logUrl set; redaction; POST failure non-fatal
- [x] 4.2 Update `request-context.spec.ts` — `ctx.log` present and delegates to logger
- [x] 4.3 Update `with-custom-operation.spec.ts` — logUrl passed through; ctx.log available in handler
- [x] 4.4 Update `request-logging.spec.ts` — incoming request external event when logUrl configured (mock fetch)
- [x] 4.5 Adjust affected persist / test-mode specs if log output assertions change

## 5. Verification

- [x] 5.1 Confirm canonical test command: `npm test`
- [x] 5.2 All delta spec scenarios covered by named automated tests in groups 4.x
- [x] 5.3 Manual spot-check: spcx or `npm run call:op` invoke with `config.logUrl` pointing at local mock HTTP server receives JSON events

## 6. Documentation

- [x] 6.1 Update README Development / invoke config section — optional `config.logUrl`, dual-sink behavior, JSON event fields, token redaction
- [x] 6.2 Add `logUrl` to connected dry-run invoke payload example under `payloads/` when a suitable example exists
- [x] 6.3 Document `ctx.log.info|warn|error(message, detail?)` in framework README section for operation authors

## 7. Changelog

- [x] 7.1 Create or update changelog entry for this change via changelog-generator during apply
- [x] 7.2 Confirm entry covers optional logUrl, dual-sink logger, and ctx.log implementation
