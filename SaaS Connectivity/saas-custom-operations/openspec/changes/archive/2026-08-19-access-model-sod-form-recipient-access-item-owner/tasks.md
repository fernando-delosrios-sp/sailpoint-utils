## 1. ISC owner resolution helpers

- [x] 1.1 Add `resolveRoleOwnerId` under `src/isc/roles/` (IDENTITY-or-omitted-type, missing/non-IDENTITY throws ConnectorError); export from barrel; unit tests
- [x] 1.2 Add `resolveAccessProfileOwnerId` under `src/isc/access-profiles/` with the same contract; export from barrel; unit tests
- [x] 1.3 Add fetch+resolve helpers (or dispatcher) that call `getRoleV1` / `getAccessProfileV1` then extract owner id for a `CatalogAccessItem`
- [x] 1.4 Extend offline role/AP fixtures and public-identity offline emails so offline scans resolve a canned access item owner

## 2. Access-model scan recipient retarget

- [x] 2.1 In `src/operations/access-model-sod-remediation/index.ts`, replace `resolvePolicyOwnerId` usage with memoized access-item owner resolution (by access item id)
- [x] 2.2 Pass access item owner id as form `recipientId`; persist `[ownerEmail]` as `form-email-recipients`; treat resolve/fetch failures as form launch failures (`forms-launch-failed`)
- [x] 2.3 Update `form-service.ts` comments/docs that still say “policy owner” for instance creation
- [x] 2.4 Update `index.spec.ts` (and related mocks) so recipient/email assertions use access item owner, not policy owner; cover missing-owner launch failure

## 3. Verification

- [x] 3.1 Confirm canonical test command: `npm test`
- [x] 3.2 Run `npm run typecheck` and `npm test` for touched modules
- [x] 3.3 All delta spec scenarios covered by named automated tests (role/AP owner helpers + access-model recipient/email/missing-owner)

## 4. Documentation

- [x] 4.1 Update `src/operations/access-model-sod-remediation/README.md` (audience, email recipients table, workflow narrative) from policy owner → access item owner
- [x] 4.2 Update seed description in `seed/access-model-sod-remediation.seed.json`
- [x] 4.3 Update package `README.md` workflow table wording for Access Model SOD notification
- [x] 4.4 Update inline comments/JSDoc on the scan handler that still describe policy-owner forms

## 5. Changelog

- [x] 5.1 Create or update changelog entry via **changelog-generator** during apply
- [x] 5.2 Confirm entry documents the breaking recipient/email retarget from policy owner to access item owner
