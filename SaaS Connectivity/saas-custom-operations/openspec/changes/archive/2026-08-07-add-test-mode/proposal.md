## Why

Custom operation handlers today always resolve ISC sources and persist results through the SailPoint API when `ctx.persist` is called. Local development and pre-deployment validation require running real handler code and observing `ctx.res.send` output without writing accounts or mutating source schema on ISC. Without a first-class test mode, developers must either hit a live tenant or maintain extensive mocks, slowing iteration and increasing risk of accidental data writes during dry runs.

## What Changes

**Test mode activation**
- From: Every invocation resolves `sourceName` and performs real ISC persistence when handlers call `ctx.persist`.
- To: When `config.testMode` is true (or `SPCX_TEST_MODE=1` env fallback), the framework inhibits ISC persistence and write-side effects while handlers and `ctx.res.send` run unchanged. When a valid access token is provided, read-only ISC status checks still run; when no token is provided, all ISC calls are skipped.
- Reason: Safe local execution with optional live connectivity validation before dry-run.
- Impact: Non-breaking; default behavior unchanged when test mode is off.

**Token-gated ISC status checks**
- From: Test mode plan skipped all ISC interaction including source lookup.
- To: With token + apiUrl, test mode validates ISC connectivity (read-only) and resolves result source by list-only lookup without auto-create. Without token, config fields apiUrl/token/sourceName are optional and no ISC APIs are called.
- Reason: Developers can verify credentials and source existence while still avoiding writes.
- Impact: Non-breaking; offline fixtures supported without credentials.

**JSON fixture local runner**
- From: No standard way to invoke a custom command from a JSON file outside Vitest.
- To: A documented fixture format (`command`, `config`, `input`) and npm script load a file, invoke the handler, print `res.send` output, and echo inhibited operations to console.
- Reason: Repeatable dry runs aligned with ISC invoke shape.
- Impact: Non-breaking; additive dev tooling.

**Console visibility of inhibited operations**
- From: Persist calls either write to ISC or are mocked opaquely in unit tests.
- To: Each inhibited persist, verifyPersisted, and source/schema operation logs a `[test-mode]` line with identity, attributes, and summary counts.
- Reason: Developers see exactly what would have been written.
- Impact: Non-breaking; logging only when test mode is active.

## Capabilities

### New Capabilities

- `operation-test-runner`: JSON fixture format, local invoke script, stdout capture of `res.send`, and npm script entry point for dry-run operation execution.

### Modified Capabilities

- `custom-operation-framework`: Test mode on request context — token-gated read-only ISC status checks, inhibited persist/verify/schema/source-create with console logging; unchanged handler and `res.send` contracts.
- `connector-config`: Document optional `testMode`, token-gated config requirements (token present vs absent), and env fallback.

## Impact

- **Code:** `src/framework/with-custom-operation.ts`, `src/framework/request-context.ts`, `src/framework/source-provisioning.ts` (read-only resolve helper), new test-mode module, `scripts/run-operation-fixture.ts`, fixtures including token-less example.
- **Tests:** Vitest coverage for test-mode persist logging, env fallback, and fixture runner smoke test.
- **Docs:** README section for test mode and fixture usage.
- **Dependencies:** None.
- **Systems:** No ISC manifest change required; test mode is opt-in via config/env.
