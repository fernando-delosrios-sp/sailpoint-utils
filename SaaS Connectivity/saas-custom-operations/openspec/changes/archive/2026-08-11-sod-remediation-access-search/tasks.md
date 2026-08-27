## 1. Search string builder

- [x] 1.1 Add `buildAccessSearchString()` to `access-path-resolver.ts`
- [x] 1.2 Add unit tests for single-item, multi-item, and empty inputs

## 2. Form input and seed

- [x] 2.1 Replace revoke payload keys with `groupAAccessSearch` / `groupBAccessSearch` in `assembleFormInput` and `SodFormInputValues`
- [x] 2.2 Update bundled seed formInput, hidden TEXT elements, and formConditions
- [x] 2.3 Update `seed.spec.ts` hidden key expectations

## 3. Tests and docs

- [x] 3.1 Update `context.spec.ts` for access search string assertions
- [x] 3.2 Update `logging.ts` / `logging.spec.ts` for new formInput fields
- [x] 3.3 Update README workflow integration section and CHANGELOG breaking note
- [x] 3.4 Update `openspec/specs/connector-operations/sod-remediation/spec.md`
- [x] 3.5 Run `npm test`
