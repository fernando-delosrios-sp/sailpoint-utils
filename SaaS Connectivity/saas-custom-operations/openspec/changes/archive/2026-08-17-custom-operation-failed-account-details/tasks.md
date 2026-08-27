## 1. Base schema and persist pipeline

- [x] 1.1 Add `details` STRING to `CORE_ATTRIBUTES` in `src/framework/base-account-schema.ts` and update `CORE_ATTRIBUTE_NAMES` ordering
- [x] 1.2 Extend `buildAccountAttributes` in `src/framework/persist-result.ts` to merge handler-supplied `details` (framework-writable core field)
- [x] 1.3 Ensure schema reconciliation treats `details` as a required core attribute in `src/framework/result-source.ts`
- [x] 1.4 Add unit tests in `base-account-schema.spec.ts` and `persist-result.spec.ts` for base schema includes details, success persist with details, details truncation (covers scenarios: Base schema includes details, Success persist with informative details, Details truncated at STRING limit, Persist reconciles missing details)

## 2. Automatic failure persist in customOperation

- [x] 2.1 Add `persistFailedResult(requestId, message, ctx)` helper in framework (or inline in wrapper) using `verify: false`
- [x] 2.2 Invoke failure persist from `customOperation` catch block before `res.send({ status: 'failed', error })`
- [x] 2.3 Invoke failure persist from `trackedRes.send` when handler sends failed output
- [x] 2.4 Handle init failures: persist failed account when request context exists; skip safely when context not yet created
- [x] 2.5 Swallow failure-persist errors with console warning; still send failed invoke response (covers scenarios: Handler throw persists, Handler sends failed response, Initialization failure, Persist verification failure, Failure persist failure is non-fatal, Failed persist skips inline verification)
- [x] 2.6 Update `with-custom-operation.spec.ts` with mocks asserting persist called with status failed and details on each failure path

## 3. Test mode and local runner

- [x] 3.1 Ensure `test-mode-persist.ts` records inhibited failed persists with details in formatted attributes
- [x] 3.2 Add `test-mode-persist.spec.ts` coverage for inhibited failed persist logged with details
- [x] 3.3 Confirm `scripts/call-op.ts` / payload output summary surfaces failed inhibited persist with details (or extend `payload-output.ts` if needed)
- [x] 3.4 Add or extend runner spec coverage for failed invoke inhibited persist summary (covers operation-test-runner scenario: Failed invoke summary includes inhibited failed persist)

## 4. Documentation

- [x] 4.1 Update root README framework/persist section documenting `details` core attribute and automatic failed account behavior
- [x] 4.2 Update inline JSDoc on `customOperation` and persist helpers referencing failure account write

## 5. Changelog

- [x] 5.1 Add CHANGELOG entry under Unreleased describing failed result accounts, mandatory `details` schema attribute, optional success details
- [x] 5.2 Confirm entry covers user-visible workflow read-back change from proposal Capabilities
