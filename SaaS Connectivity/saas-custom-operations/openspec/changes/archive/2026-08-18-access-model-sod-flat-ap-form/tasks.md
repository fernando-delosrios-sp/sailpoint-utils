## 1. Flat AP line rendering

- [x] 1.1 Update `renderTreeBody` in `src/lib/sod-form-html/entitlement-tree.ts` to emit flat access profile rows with offending entitlement mentions
- [x] 1.2 Update `src/lib/sod-form-html/sod-form-html.spec.ts` for flat AP lines (no nested `<ul>`, offending mention present)
- [x] 1.3 Update `src/operations/access-model-sod-remediation/group-html.spec.ts` expectations if needed

## 2. Verification

- [x] 2.1 Confirm canonical test command: `npm test`
- [x] 2.2 All delta spec scenarios covered by named automated tests in sod-form-html and group-html specs

## 3. Documentation

- [x] 3.1 Update `src/operations/access-model-sod-remediation/README.md` Form HTML section for flat AP lines
- [x] 3.2 Update inline JSDoc on `renderEntitlementTree` if behavior comment references nested tree

## 4. Changelog

- [x] 4.1 Create or update changelog entry for this change
- [x] 4.2 Confirm entry covers flat access profile line presentation on access-model SoD remediation forms
