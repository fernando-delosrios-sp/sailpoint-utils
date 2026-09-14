## 1. Apply persist identity

- [x] 1.1 Add `applyPersistIdentity(formInstanceId)` to the apply operation folder (mirroring `childPersistIdentity` in `access-model-sod-remediation/constants.ts`) returning `access-model-sod-remediation-apply:{formInstanceId}`
- [x] 1.2 Use it for the main persist call in `access-model-sod-remediation-apply/index.ts` so outputs land on the prefixed identity
- [x] 1.3 Use it for the prior-apply replay persist call in the same handler
- [x] 1.4 Confirm the handler still ignores invoke `requestId` for persist identity and that offline fixture keys stay keyed on `formInstanceId`

## 2. Prior-apply lookup with legacy fallback

- [x] 2.1 In `prior-apply-status.ts`, look up the prefixed identity via `findAccountOnSource` first
- [x] 2.2 Fall back to the bare `{formInstanceId}` account only when the prefixed lookup returns nothing, reusing identical terminal-status and required-field validation for both
- [x] 2.3 Verify no write, update, or delete targets the legacy account on any path

## 3. Description audit line label

- [x] 3.1 Change the `buildDescriptionAuditLine` prefix in `description-audit.ts` from `[SOD remediation {timestamp}]` to `[access-model-sod-remediation-apply {timestamp}]`, leaving the line body unchanged
- [x] 3.2 Confirm the relabeled line flows unchanged into catalog PATCH and into `access-model-sod-remediation-apply:description-appended`

## 4. Tests

- [x] 4.1 `description-audit.spec.ts` — assert the line starts with `[access-model-sod-remediation-apply <iso-timestamp>]` and never with `[SOD remediation`, and that policy, side, detached profiles, removed entitlements, form instance id, submitter, and comments still appear
- [x] 4.2 `index.spec.ts` — successful apply persists on `access-model-sod-remediation-apply:{formInstanceId}` and never on the bare id
- [x] 4.3 `index.spec.ts` — invoke whose `requestId` differs from the derived identity still persists on the prefixed identity
- [x] 4.4 Prior-apply coverage — prefixed account found returns `skipped-already-applied` without a legacy lookup and without PATCH
- [x] 4.5 Prior-apply coverage — only a legacy bare account exists: returns `skipped-already-applied`, no PATCH, no second audit line, replay persists on the prefixed identity, legacy account untouched
- [x] 4.6 Prior-apply coverage — both identities present: prefixed wins; non-terminal legacy status is treated as no prior apply; neither present proceeds to definition lookup, list, and PATCH
- [x] 4.7 Offline/testMode apply persists on the prefixed identity when persist is enabled

## 5. Verification

- [x] 5.1 Confirm canonical test command: `npm test` (plus `npm run typecheck` for these TypeScript changes)
- [x] 5.2 All delta spec scenarios covered by named automated tests
- [x] 5.3 Run an offline `npm run call:op` apply payload and confirm the inhibited-persist log shows the prefixed identity

## 6. Documentation

- [x] 6.1 Update `src/operations/access-model-sod-remediation-apply/README.md` — output persist identity, `requestId` row wording, idempotency section (prefixed plus legacy fallback), and the workflow persist-key table
- [x] 6.2 Update `src/operations/access-model-sod-remediation/README.md` where it points at the apply persist identity for read-back
- [x] 6.3 Check root `README.md` and `payloads/` apply examples for references to the bare form instance persist identity
- [x] 6.4 Note in the apply README that the bundled `Access Model SOD - Remediation` workflow needs no edit (no Get Accounts step), but manual account read-back must use the prefixed identity

## 7. Changelog

- [x] 7.1 Create changelog entry for this change via **changelog-generator**
- [x] 7.2 Confirm the entry marks both the persist identity and the audit label as breaking, and states that legacy accounts are neither backfilled nor deleted
