## 1. Revocable search builder

- [x] 1.1 Add `buildRevocableAccessSearchString()` to `access-path-resolver.ts`
- [x] 1.2 Add unit tests: mixed revocable/non-revocable side, entitlement-only side, empty revocable set

## 2. Form input wiring

- [x] 2.1 Use `buildRevocableAccessSearchString()` in `assembleFormInput()` for both sides
- [x] 2.2 Update `context.spec.ts` expectations (group B → `id:role-1` only)

## 3. Docs and spec sync

- [x] 3.1 Update README workflow section to note revocable-only search filters
- [x] 3.2 Add CHANGELOG patch entry for corrected filter behavior
- [x] 3.3 Run `npm test`
