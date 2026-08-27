## 1. Identity access module layout

- [x] 1.1 Rename SDK orchestration module to `src/isc/identity-access/fetch-identity-access-items.ts` (from `fetch-from-sdk.ts`)
- [x] 1.2 Keep runtime offline lookup in `src/isc/identity-access/offline-data.ts` with module-private lookup map
- [x] 1.3 Update `src/isc/identity-access/index.ts` exports — orchestration from `fetch-identity-access-items.ts`, offline from `offline-data.ts`
- [x] 1.4 Confirm `identity-access.spec.ts` uses inline expected literals and imports via `./index` only (target-client/identity-access: Offline data listing, Offline stub in dedicated module)

## 2. SOD remediation offline violation co-location

- [x] 2.1 Move `OFFLINE_VIOLATION` constant from `src/operations/sod-remediation/offline-data.ts` into `src/operations/sod-remediation/index.ts` as module-private constant
- [x] 2.2 Update imports in `index.ts` to use co-located constant; delete `offline-data.ts`
- [x] 2.3 Confirm `src/operations/sod-remediation/index.spec.ts` uses inline mocks only (no fixture file imports)

## 3. Spec scenario coverage

- [x] 3.1 Ensure `identity-access.spec.ts` retains SDK loopback listing test with inline `vi.fn()` mocks (target-client/identity-access: SDK loopback listing)
- [x] 3.2 Retain inline mock data in framework and operation specs (custom-operation-framework: Spec file contains its own mock data)
- [x] 3.3 Confirm no `fixtures.ts` or Vitest-only `test-data.ts` under `src/`; `offline-data.ts` retained for runtime invoke only (custom-operation-framework: No new test-fixture sibling files)

## 4. Verification

- [x] 4.1 Run `npm test` — all suites pass; coverage thresholds unchanged
- [x] 4.2 Smoke `npm run call:op -- payloads/sod-remediation-offline.json` — offline invoke succeeds without config

## 5. Documentation

- [x] 5.1 Update README / getting-started — N/A (no user-visible invoke or CLI change)
- [x] 5.2 Update API / connector docs — N/A (no connector-spec or handler contract change)
- [x] 5.3 Update inline docs (JSDoc on offline constants)

## 6. Changelog

- [x] 6.1 Update CHANGELOG Unreleased entry
- [x] 6.2 Entry notes inline spec fixture convention and sod-remediation offline-data removal
