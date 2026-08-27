## Context

`custom:sod-remediation` ensures a named ISC form definition exists before creating a standalone remediation instance. The sod-remediation change established ensure-by-name with seed create-on-miss and never-PATCH reuse. Recipient resolution (`input.owner ?? violation.owner.id`) is correct for form instances but was never intended for form definition ownership.

The framework already exposes `resolveTokenIdentity(token)` for source auto-provisioning (JWT `identity_id` / `identityId` / `sub` claims). Connector config always includes `token` for online invokes.

Temporary debug `fetch` instrumentation was added during SOD API troubleshooting. Structured logging via `sod-remediation-logging.ts` and framework request logging supersede it.

## Goals / Non-Goals

**Goals:**
- Pass access-token identity as `ownerId` to `ensureFormDefinition` on online invokes
- Preserve offline/test-mode behavior with a fixed fallback owner id
- Update unit tests and spec delta to lock behavior
- Remove debug agent fetch blocks from SOD-related source
- Extend form-definition log line with owner id and resolution source

**Non-Goals:**
- Change form instance recipient logic or `owner` input semantics
- Re-owner or PATCH existing tenant form definitions
- Add new token resolution mechanism beyond `resolveTokenIdentity`
- Rename `owner` input to `ownerOverride`

## Decisions

### D1: Form definition owner source
- **选择:** Online: `resolveTokenIdentity(ctx.token)`. Offline: `'offline-owner'` (matches `OFFLINE_VIOLATION.owner.id`).
- **理由:** Aligns with source provisioning pattern; violation owner is wrong stable owner for reusable template.
- **已考虑 alternative:** Use `input.owner` when present — rejected; that field is recipient-only.

### D2: Reuse existing helper
- **选择:** Import `resolveTokenIdentity` from `../framework` (already exported).
- **理由:** Single JWT decode implementation; no duplicate logic.
- **已考虑 alternative:** Inline decode in operation — rejected; violates DRY.

### D3: Existing definitions unchanged
- **选择:** No migration; `ensureFormDefinition` only sets owner on create-from-seed.
- **理由:** sod-remediation D3 never-PATCH rule still applies.
- **已考虑 alternative:** Ownership transfer API on each invoke — rejected.

### D4: Debug instrumentation cleanup
- **选择:** Delete all `#region agent log` fetch blocks in sod-remediation-operation, sod-form-service, experimental-client, identity-access-client, sdk-factory.
- **理由:** Temporary debugging artifact; structured logs cover operational needs.
- **已考虑 alternative:** Gate behind env flag — rejected; YAGNI.

### D5: Logging extension
- **选择:** Extend `logSodRemediationFormDefinition` to accept `definitionOwnerId` and `definitionOwnerSource: 'token-identity' | 'offline-fallback'`.
- **理由:** Verifies fix in connector stdout without re-enabling debug fetch.
- **已考虑 alternative:** No log change — rejected; operators need visibility at create time.

## Risks / Trade-offs

- [Risk] Token lacks `identity_id` claim → Mitigation: `resolveTokenIdentity` falls back to `sub`; same behavior as source provisioning
- [Risk] Tenants with definitions already created under violation owner → Mitigation: documented non-goal; manual ISC admin re-assign if needed
- [Trade-off] Offline owner is synthetic → Accept: offline path does not hit real Forms API in typical fixture runs

## Migration Plan

N/A — behavior change only on **new** form definition creates. Deploy updated connector bundle. No connector-spec or workflow input changes. Operators who need existing definitions re-owned must do so manually in ISC admin UI.

## Open Questions

- None blocking — JWT claim precedence matches existing source-provisioning tests
