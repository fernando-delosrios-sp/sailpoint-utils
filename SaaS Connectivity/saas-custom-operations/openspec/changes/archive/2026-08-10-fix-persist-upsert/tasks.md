## 1. Persist dependencies and types

- [x] 1.1 Replace `createAccount` with `upsertAccount` on `PersistDependencies` in `src/framework/types.ts`
- [x] 1.2 Add optional `findAccountByNativeIdentity(id)` returning `{ iscAccountId, attributes } | undefined` on `PersistDependencies` (or fold into upsert wiring)

## 2. Runtime wiring (`request-context.ts`)

- [x] 2.1 Implement account lookup via `listAccountsV1` returning ISC account id and attributes
- [x] 2.2 Implement `upsertAccount`: `createAccountV1` when absent, `putAccountV1` when present
- [x] 2.3 Refactor `readAccount` to reuse lookup helper (avoid duplicate filter logic)
- [x] 2.4 Add `putAccountV1` to offline SDK stub signature alongside existing stubs

## 3. Persist helper (`persist-result.ts`)

- [x] 3.1 Update `createPersist` to call `upsertAccount` instead of `createAccount`
- [x] 3.2 Update JSDoc comment to describe probe-first create-or-update semantics

## 4. Unit tests — persist-result

- [x] 4.1 Test: first persist invokes upsert/create path only (Scenario: Persist creates account when identity absent)
- [x] 4.2 Test: second persist with same identity invokes update path (Scenario: Persist upserts duplicate identity)
- [x] 4.3 Test: upsert read-back verification still passes with updated attributes
- [x] 4.4 Update existing `createPersist` tests to use `upsertAccount` mock name

## 5. Integration stubs

- [x] 5.1 Update `with-custom-operation.spec.ts` and operation specs if mocks reference `createAccountV1` only for persist wiring assertions

## 6. Documentation

- [x] 6.1 Update README persist/upsert section to document create vs putAccountV1 behavior
- [x] 6.2 Update inline JSDoc on persist helper if README references are insufficient
- [x] 6.3 N/A — connector-spec.json unchanged

## 7. Changelog

- [x] 7.1 Add CHANGELOG entry under Unreleased for persist upsert fix (create vs putAccountV1)
- [x] 7.2 Confirm entry covers debug re-run with same requestId scenario
