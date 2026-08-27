## 1. Shared formatting and invoke config

- [x] 1.1 Add `src/framework/pretty-json.ts` with `formatSpreadJson`
- [x] 1.2 Add `src/framework/invoke-config.ts` with `readExternalInvokeConfig` and `readInvokeConfig`
- [x] 1.3 Update `scripts/fixture-output.ts` to re-export `formatSpreadJson` from framework
- [x] 1.4 Unit test: formatSpreadJson blank lines between top-level properties (fixture-output spec)
- [x] 1.5 Unit test: readInvokeConfig returns undefined when no config sources available

## 2. Request logging wrapper

- [x] 2.1 Add `src/framework/request-logging.ts` with formatIncomingRequest, redactConfigForLogging, withRequestLogging, wrapConnectorWithRequestLogging
- [x] 2.2 Wire `wrapConnectorWithRequestLogging` in `src/operations/index.ts`
- [x] 2.3 Export new symbols from `src/framework/index.ts`
- [x] 2.4 Unit test: token redacted in formatIncomingRequest (Scenario: Token redacted in request log)
- [x] 2.5 Unit test: withRequestLogging logs before handler delegation (Scenario: Invoke payload logged at command entry)
- [x] 2.6 Unit test: config included when context.config present (Scenario: Config included when resolved)

## 3. Handler config resolution fix

- [x] 3.1 Update `resolveInvocationConfig` default to use `readInvokeConfig`
- [x] 3.2 Handle undefined readConfig return without throwing in resolveInvocationConfig
- [x] 3.3 Unit test: spcx AsyncLocalStorage config counts as provided (Scenario: spcx AsyncLocalStorage config counts as provided)
- [x] 3.4 Unit test: absent config returns not provided (Scenario: Absent config returns not provided)

## 4. Integration validation

- [x] 4.1 Run `npm test` and confirm coverage thresholds pass
- [x] 4.2 Run `npm run build` and verify dist bundles successfully
- [x] 4.3 Manual spcx validation: POST invoke with config block shows config in Incoming request log and handler receives connection fields

## 5. Documentation

- [x] 5.1 Update README Development section with spcx invoke envelope example and default request logging note
- [x] 5.2 Update inline JSDoc on request-logging and invoke-config modules

## 6. Changelog

- [x] 6.1 Create or update changelog entry via changelog-generator skill
- [x] 6.2 Confirm entry covers default request logging and spcx config resolution fix
