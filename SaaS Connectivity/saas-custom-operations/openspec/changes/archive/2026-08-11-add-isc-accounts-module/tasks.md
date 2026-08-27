## 1. ISC accounts module scaffolding

- [x] 1.1 Create `src/isc/accounts/types.ts` with `SourceAccountMatch` and shared types
- [x] 1.2 Create `src/isc/accounts/account-client.ts` with thin `getAccount`, `listAccounts`, `createAccount`, `putAccount` wrappers
- [x] 1.3 Create `src/isc/accounts/find-account.ts` — move `escapeODataString`, `findAccountOnSource`, and internal scan helpers from `persist-result.ts`
- [x] 1.4 Create `src/isc/accounts/index.ts` barrel exporting public API surface

## 2. Unit tests for isc/accounts

- [x] 2.1 Add `src/isc/accounts/account-client.spec.ts` covering get, list, create, and put scenarios (target-client/accounts API boundary)
- [x] 2.2 Add lookup tests in `account-client.spec.ts` or `find-account.spec.ts` covering nativeIdentity match, source scan fallback, 400 filter skip, and OData escape (target-client/accounts lookup scenarios)

## 3. Framework persist refactor

- [x] 3.1 Update `src/framework/persist-result.ts` to import lookup and CRUD from `../isc/accounts`
- [x] 3.2 Remove duplicated account lookup/CRUD code from `persist-result.ts`; keep upsert orchestration, task polling, verification
- [x] 3.3 Update `src/framework/persist-result.spec.ts` imports and relocate lookup-specific tests to isc/accounts specs where appropriate

## 4. Verification

- [x] 4.1 Grep for direct `AccountsApi` usage outside `sdk-factory`, `request-context`, and `isc/accounts`
- [x] 4.2 Run `npm test` — all tests pass
- [x] 4.3 Run `npm run build` — build succeeds

## 5. Documentation

- [x] 5.1 Update README layout section noting `accounts/` for AccountsApi instances vs `sources/` for account schemas (if README documents isc layout)

## 6. Changelog

- [x] 6.1 Add changelog entry for new `src/isc/accounts/` module and framework delegation (non-breaking refactor)
