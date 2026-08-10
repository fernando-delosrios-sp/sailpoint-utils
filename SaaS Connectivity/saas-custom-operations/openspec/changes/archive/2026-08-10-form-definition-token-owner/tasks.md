## 1. Form definition owner resolution

- [x] 1.1 Resolve form definition owner in `sod-remediation-operation.ts`: online via `resolveTokenIdentity(ctx.token)`, offline via canned `offline-owner`
- [x] 1.2 Pass resolved owner to `ensureFormDefinition` instead of `violation.owner.id`
- [x] 1.3 Extend `logSodRemediationFormDefinition` with `definitionOwnerId` and `definitionOwnerSource` (`token-identity` | `offline-fallback`)

## 2. Tests

- [x] 2.1 Update `sod-remediation-operation.spec.ts` — form definition create uses token identity, not violation owner (mock JWT with distinct `identity_id`)
- [x] 2.2 Add test — offline invoke uses offline fallback owner for form definition create
- [x] 2.3 Confirm recipient override test still passes unchanged
- [x] 2.4 Run `npm test` and confirm coverage thresholds

## 3. Debug instrumentation cleanup

- [x] 3.1 Remove `#region agent log` fetch blocks from `sod-remediation-operation.ts`
- [x] 3.2 Remove `#region agent log` fetch blocks from `sod-form-service.ts` (including `logFormApiError` ingest call)
- [x] 3.3 Remove `#region agent log` fetch blocks from `experimental-client.ts`, `identity-access-client.ts`, `sdk-factory.ts`

## 4. Documentation

- [x] 4.1 Update README SOD remediation section — form definition owner = access token identity; recipient override unchanged
