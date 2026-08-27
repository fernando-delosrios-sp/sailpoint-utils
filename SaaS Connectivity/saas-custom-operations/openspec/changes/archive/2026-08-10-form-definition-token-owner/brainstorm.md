# Brainstorm: Form definition owner — access token identity

Raw capture from design exploration (Aug 2026).

## Background

`custom:sod-remediation` bootstraps ISC form definitions on first use via `ensureFormDefinition(formName, ownerId)`. Today the operation passes `violation.owner.id` as the form definition owner. That ties administrative ownership of the reusable form template to whoever owns the current violation — a different identity on every incident when violations have different owners.

The connector already resolves the access-token holder's identity for DelimitedFile source provisioning via `resolveTokenIdentity(token)` in `src/framework/source-provisioning.ts`. The same pattern fits form definition ownership: the service account or admin PAT that invokes the connector should own the tenant form template.

Form instance **recipient** behavior is unchanged: `input.owner ?? violation.owner.id`.

Temporary debug instrumentation (`fetch` to local ingest on `127.0.0.1:7830`) was added during SOD troubleshooting across several files. Structured SOD logging already exists in `src/isc/sod-remediation-logging.ts` and framework request logging was added in the connector-request-logging change. The debug blocks should be removed as part of this fix pass.

## Agreed scope

**In scope:**
- Use access-token identity as `ownerId` when creating a new SOD remediation form definition from seed
- Reuse existing `resolveTokenIdentity` helper (same JWT decode as source owner)
- Update tests and spec delta for connector-operations
- Remove temporary agent debug `fetch` instrumentation from SOD-related source files
- Log form-definition owner source in existing SOD remediation logging

**Out of scope:**
- Changing form instance recipient resolution (`input.owner` override)
- PATCHing or re-owning existing form definitions in the tenant
- Renaming input field `owner` to `ownerOverride`
- New framework-level token resolution API (reuse existing helper)

## Decision chain

### Q1: Who should own the form definition template?
**Decision:** The identity associated with the connector's access token (PAT/OAuth), not the violation owner.

**Reason:** Form definitions are tenant-level reusable assets created once per `formName`. The invoking service account or compliance admin should retain ownership and edit rights. Violation owners vary per incident and are the wrong stable owner for a shared template.

### Q2: How to resolve token identity?
**Decision:** Reuse `resolveTokenIdentity(ctx.token)` from `src/framework/source-provisioning.ts` (exported via `src/framework/index.ts`).

**Reason:** Already proven for source auto-provision; same config token on every invoke.

### Q3: Offline / test-mode without token?
**Decision:** When `offline` (`!ctx.apiUrl && !ctx.token`), pass a fixed canned owner id (`offline-owner`, matching `OFFLINE_VIOLATION.owner.id`) to `ensureFormDefinition`. Do not call `resolveTokenIdentity` without a token.

**Reason:** Offline fixtures and test-mode runs lack credentials; consistent with existing offline violation stub pattern.

### Q4: Existing form definitions already created with violation owner?
**Decision:** No migration. `ensureFormDefinition` only sets owner on **create**; existing definitions are reused by name without patch (unchanged D3 from sod-remediation).

**Reason:** Preserves admin edits and avoids destructive ownership changes in tenant.

### Q5: Debug agent logging cleanup?
**Decision:** Remove all `#region agent log` fetch blocks added for local debugging in:
- `src/operations/sod-remediation-operation.ts`
- `src/isc/sod-form-service.ts`
- `src/isc/experimental-client.ts`
- `src/isc/identity-access-client.ts`
- `src/framework/sdk-factory.ts`

**Reason:** Not production logging; duplicates structured logs; adds network noise and hardcoded session IDs.

## Approaches considered

| Approach | Trade-off |
|----------|-----------|
| Keep violation owner for form definition | Rejected — wrong actor for reusable tenant asset |
| New ISC API call to resolve token identity | Rejected — JWT decode already works for PAT |
| Pass `input.owner` as form definition owner | Rejected — `owner` input is recipient override only |
| Re-owner existing definitions on each invoke | Rejected — violates never-PATCH rule |

## Open items for implementation

- Confirm unit tests mock JWT with `identity_id` claim when asserting form definition create owner
- Extend `logSodRemediationFormDefinition` to include resolved definition owner id and source (`token-identity` | `offline-fallback`)

## Reference

- Current call site: `ensureFormDefinition(ctx.sdk.forms, input.formName, violation.owner.id)` in `sod-remediation-operation.ts`
- Prior art: `resolveTokenIdentity` in `source-provisioning.ts`; spec requirement in `custom-operation-framework` for source owner = token identity
