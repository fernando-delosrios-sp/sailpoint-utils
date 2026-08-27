## 1. Codegen export

- [x] 1.1 Extend `generate-operation-schemas.ts` to emit `OPERATION_HANDLERS` export in auto-registry.ts
- [x] 1.2 Extend `generate-operation-schemas.spec.ts` — handler map keys match discovered commands

## 2. call-op refactor

- [x] 2.1 Import OPERATION_HANDLERS from auto-registry; remove manual handler imports and map
- [x] 2.2 Preserve injectable handler override for `call-op.spec.ts`
- [x] 2.3 Verify all six current operations invoke via call:op after build

## 3. Verification

- [x] 3.1 Confirm canonical test command: `npm test`
- [x] 3.2 All delta spec scenarios covered by named automated tests

## 4. Documentation

- [x] 4.1 Remove manual call-op registration steps from root README
- [x] 4.2 Update `_template/README.md` if it mentions manual registration
- [x] 4.3 Update inline comments in call-op.ts

## 5. Changelog

- [x] 5.1 Create or update changelog entry for this change
- [x] 5.2 Confirm entry covers auto-wired local invoke
