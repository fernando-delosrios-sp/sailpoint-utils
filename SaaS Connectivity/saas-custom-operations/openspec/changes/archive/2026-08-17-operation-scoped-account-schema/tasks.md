## 1. Source provisioning — operation-scoped base schema

- [x] 1.1 Add failing test in `result-source.spec.ts`: auto-create applies only invoking operation output fields, not other registered operations
- [x] 1.2 Add failing test: core-only base schema when `outputFields` is empty / operationSchema absent
- [x] 1.3 Change `applyBaseAccountSchema` to accept `outputFields: OperationField[]` instead of calling `registeredOutputFields()`
- [x] 1.4 Change `createDelimitedFileResultSource` and `resolveSourceByName` to accept and forward `outputFields`
- [x] 1.5 Remove `registeredOutputFields` helper and unused registry import from `result-source.ts`
- [x] 1.6 Run `npm test -- result-source` — PASS

## 2. Custom operation wrapper wiring

- [x] 2.1 Add failing test in `with-custom-operation.spec.ts`: first invocation passes operation output fields into source create
- [x] 2.2 Resolve `operationSchema` before `resolveSourceByName` in `runCustomOperation` and pass `outputFields`
- [x] 2.3 Run `npm test -- with-custom-operation` — PASS

## 3. Multi-operation lazy schema growth

- [x] 3.1 Add failing integration-style test: source created with op A fields; op B persist adds B fields via `ensureSourceSchema` (may live in `result-source.spec.ts` or `persist-result.spec.ts`)
- [x] 3.2 Verify existing persist reconciliation tests still pass — `npm test -- persist-result result-source`

## 4. Documentation

- [x] 4.1 Update README result-source / base schema sections: runtime create is operation-scoped; `account-schema.json` union is reference only
- [x] 4.2 Update inline JSDoc on `applyBaseAccountSchema` and `buildBaseAccountSchema` if they mention registry union
- [x] 4.3 N/A: connector-spec.json (no std command changes)

## 5. Changelog

- [x] 5.1 Create or update changelog entry (apply invokes **changelog-generator** if available)
- [x] 5.2 Confirm entry covers operation-scoped base schema on result source auto-create
