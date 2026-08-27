## 1. Form seed and launch input

- [x] 1.1 Add `parentRequestId` to `access-model-sod-remediation.seed.json` declared `formInput` (STRING, no UI element)
- [x] 1.2 Extend `AccessModelSodFormInputValues` and serialize path to include `parentRequestId`
- [x] 1.3 Pass `ctx.requestId` as `parentRequestId` when calling `createAccessModelSodRemediationInstance` in `index.ts`

## 2. Request-scoped pending-form dedupe

- [x] 2.1 Change cache pair key to `${parentRequestId}:${accessItemId}:${policyId}` in `form-service.ts`
- [x] 2.2 Add `parentRequestId` parameter to `hasAssignedRemediationInstance` and match all three `formInput` fields plus ASSIGNED state
- [x] 2.3 Wire `ctx.requestId` through dedupe calls from `index.ts`; keep offline bypass unchanged

## 3. Tests

- [x] 3.1 Update `form-service.spec.ts`: same parent skips, different parent creates, legacy missing `parentRequestId` does not skip, cache reuse
- [x] 3.2 Update `index.spec.ts` skipped-form scenario to assert request-scoped dedupe behavior
- [x] 3.3 Add create-instance test asserting `parentRequestId` sent to `createFormInstanceV1`

## 4. Verification

- [x] 4.1 Confirm canonical test command: `npm test`
- [x] 4.2 Run `npm run typecheck`
- [x] 4.3 All delta spec scenarios covered by named automated tests in `src/operations/access-model-sod-remediation/**/*.spec.ts`

## 5. Documentation

- [x] 5.1 Update `src/operations/access-model-sod-remediation/README.md` — request-scoped dedupe, `parentRequestId` on instances, legacy/migration note
- [x] 5.2 Note form seed fingerprint / new `formName` adoption pattern in README (align with existing form-definition migration guidance)

## 6. Changelog

- [x] 6.1 Create or update changelog entry via **changelog-generator** during apply
- [x] 6.2 Confirm entry covers behavior change: dedupe scoped to parent `requestId` instead of tenant-wide
