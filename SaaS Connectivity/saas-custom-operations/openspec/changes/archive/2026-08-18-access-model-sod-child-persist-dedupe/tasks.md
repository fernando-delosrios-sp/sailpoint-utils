## 1. Scan handler idempotency

- [x] 1.1 Replace form-instance dedupe in `index.ts` with `findAccountOnSource` check on `childPersistIdentity` before form launch and persist
- [x] 1.2 Skip both form creation and `ctx.persist` when child account exists; log skip with identity
- [x] 1.3 Preserve offline bypass (no account lookup in offline/test mode)

## 2. Remove form-instance dedupe surface

- [x] 2.1 Remove `hasAssignedRemediationInstance`, cache helpers, and `isPendingRemediationFormInstanceState` from `form-service.ts`
- [x] 2.2 Trim `form-service.spec.ts` to form creation/serialization tests only

## 3. Tests

- [x] 3.1 Update `index.spec.ts`: child account exists → `forms-skipped`, no form create
- [x] 3.2 Update `index.spec.ts`: different `requestId` with prior child account → still creates form
- [x] 3.3 Update `index.spec.ts`: assert no `searchFormInstancesByTenantV1` for dedupe
- [x] 3.4 Add or confirm test: skip when child account exists regardless of form state (if not covered by 3.1)

## 4. Verification

- [x] 4.1 Confirm canonical test command: `npm test`
- [x] 4.2 Run `npm run typecheck`
- [x] 4.3 All delta spec scenarios covered by named automated tests in `src/operations/access-model-sod-remediation/**/*.spec.ts`

## 5. Documentation

- [x] 5.1 Update `src/operations/access-model-sod-remediation/README.md` — child persist idempotency, revised `forms-skipped` meaning, remove form search performance note
- [x] 5.2 Remove stale references to request-scoped form dedupe in operation README workflow section if present

## 6. Changelog

- [x] 6.1 Create or update changelog entry via **changelog-generator** during apply
- [x] 6.2 Confirm entry covers idempotency behavior change (child account vs form instance)
