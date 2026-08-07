## 1. Test mode detection and wiring

- [x] 1.1 Add `isTestMode(config)` helper reading `config.testMode` and `SPCX_TEST_MODE` env fallback in `src/framework/test-mode.ts`
- [x] 1.2 Add `hasAccessToken(config)` helper to detect non-empty token after normalize
- [x] 1.3 Extend `parseStandardInput` to relax apiUrl/token/sourceName requirements when test mode active and no token
- [x] 1.4 Branch `customOperation` on token presence: read-only ISC status + list-only source resolve when token present; skip all ISC when absent
- [x] 1.5 Pass test mode and offline flags into `createRequestContext` via `RequestContextDependencies`
- [x] 1.6 Unit test: test mode disabled by default (Scenario: Test mode disabled by default)
- [x] 1.7 Unit test: test mode enabled via config (Scenario: Test mode enabled via config)
- [x] 1.8 Unit test: test mode enabled via env fallback (Scenario: Test mode enabled via environment fallback)
- [x] 1.9 Unit test: minimal offline fixture accepted (Scenario: Minimal offline fixture accepted)

## 2. Inhibited persistence and logging

- [x] 2.1 Implement test-mode `PersistDependencies` that skip API calls but use `buildAccountAttributes` for logging
- [x] 2.2 Log `[test-mode]` lines for each inhibited persist with identity, status, and attributes
- [x] 2.3 Log inhibited `verifyPersisted` calls and startup/summary lines (persist count, command, requestId)
- [x] 2.4 Ensure token values never appear in test mode log output
- [x] 2.5 Unit test: persist does not call createAccount (Scenario: Persist does not create ISC account)
- [x] 2.6 Unit test: verifyPersisted does not call readAccount (Scenario: VerifyPersisted does not read ISC accounts)
- [x] 2.7 Unit test: inhibited persist logged with attributes (Scenario: Inhibited persist logged with attributes)
- [x] 2.8 Unit test: startup and summary logged (Scenario: Test mode startup and summary logged)
- [x] 2.9 Unit test: token not logged (Scenario: Token not logged in test mode output)
- [x] 2.10 Unit test: all ISC calls skipped without token (Scenario: All ISC calls skipped without token)

## 2b. Token-gated ISC status checks

- [x] 2b.1 Implement read-only `verifyIscStatus(sourcesApi)` helper for test mode startup
- [x] 2b.2 Implement list-only `resolveSourceByNameReadOnly` (no create) for test mode with token
- [x] 2b.3 Log ISC status success and source-not-found warnings to console
- [x] 2b.4 Unit test: ISC status checked when token provided (Scenario: ISC status checked when token provided)
- [x] 2b.5 Unit test: ISC status logged on success (Scenario: ISC status logged on success)
- [x] 2b.6 Unit test: source resolved read-only when token provided (Scenario: Source resolved read-only when token provided)
- [x] 2b.7 Unit test: source auto-provision inhibited (Scenario: Source auto-provision inhibited in test mode)

## 3. res.send unchanged in test mode

- [x] 3.1 Verify `ctx.res` is unmodified SDK Response in test mode path
- [x] 3.2 Unit test: res.send receives payload normally (Scenario: res.send invoked normally)

## 4. Operation fixture runner

- [x] 4.1 Create `scripts/run-operation-fixture.ts` loading `{ command, config, input }` JSON
- [x] 4.2 Wire runner to invoke built connector handler and capture `res.send` payload to stdout
- [x] 4.3 Add npm script `test:operation` in `package.json`
- [x] 4.4 Add example fixtures `fixtures/custom-example.json` (with token) and `fixtures/custom-example-offline.json` (without token)
- [x] 4.5 Unit/integration test: valid fixture invokes handler (Scenario: Valid fixture loads command and payload)
- [x] 4.6 Unit test: missing command exits non-zero (Scenario: Missing command rejected)
- [x] 4.7 Unit test: res.send payload printed (Scenario: res.send payload printed on success)
- [x] 4.8 Verify npm script entry exists (Scenario: test operation script documented)

## 5. Documentation

- [x] 5.1 Update README with test mode, token-present vs token-absent behavior, SPCX_TEST_MODE, fixture format, and `npm run test:operation` usage
- [x] 5.2 Update inline JSDoc on test mode helpers and fixture runner script header

## 6. Changelog

- [x] 6.1 Create or update changelog entry for test mode and fixture runner (apply invokes changelog-generator if available)
- [x] 6.2 Confirm entry covers user-visible changes from Capabilities
