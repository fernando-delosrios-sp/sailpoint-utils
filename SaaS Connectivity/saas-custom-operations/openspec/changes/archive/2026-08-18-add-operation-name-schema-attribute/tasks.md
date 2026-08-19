## 1. Core schema attribute

- [x] 1.1 Add `operationName` to `CORE_ATTRIBUTES` and `CORE_ATTRIBUTE_NAMES` in `base-account-schema.ts` (STRING, isMulti false)
- [x] 1.2 Exclude `operationName` from operation output field collection (same pattern as `details`)
- [x] 1.3 Update `result-source.ts` core ordering / required reconciliation to include `operationName`

## 2. Persist wiring

- [x] 2.1 Pass invocation command into persist dependencies (`PersistDependencies.command` or equivalent)
- [x] 2.2 Set `operationName` in `buildAccountAttributes` when command is defined; ignore author-supplied value
- [x] 2.3 Add `operationName` to framework reserved / ignored persist keys in `output-schema.ts` if needed
- [x] 2.4 Wire command from `with-custom-operation.ts` / `request-context.ts` into `createPersist`
- [x] 2.5 Include `operationName` on automatic failure persist in `failure-persist.ts`
- [x] 2.6 Include `operationName` in test-mode inhibited persist records in `test-mode-persist.ts`

## 3. Tests

- [x] 3.1 Update `base-account-schema.spec.ts` for core attribute list including `operationName`
- [x] 3.2 Add persist tests: auto-set, ignore override, failure persist (`persist-result.spec.ts`, `with-custom-operation.spec.ts`)
- [x] 3.3 Update `result-source.spec.ts` base schema expectations
- [x] 3.4 Update `test-mode-persist.spec.ts` and `call-op.spec.ts` / `payload-output.spec.ts` for inhibited failed persist
- [x] 3.5 Update `scripts/templates/account-schema.spec.ts` to expect `operationName` in reference schema

## 4. Verification

- [x] 4.1 Confirm canonical test command: `npm test`
- [x] 4.2 All delta spec scenarios covered by named automated tests

## 5. Documentation

- [x] 5.1 Update README framework/persist section to document `operationName` core attribute
- [x] 5.2 Note `operationName` in result-source / Get Accounts workflow guidance where core attrs are listed

## 6. Changelog

- [x] 6.1 Create or update changelog entry for this change
- [x] 6.2 Confirm entry covers user-visible `operationName` on result accounts
