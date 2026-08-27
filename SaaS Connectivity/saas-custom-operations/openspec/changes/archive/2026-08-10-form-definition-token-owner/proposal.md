## Why

SOD remediation form definitions are tenant-level reusable templates created once per `formName`, but `custom:sod-remediation` currently assigns ownership to the violation owner on create. That ties administrative control of the shared form to whichever identity owns the current incident, which varies per violation and may lack Forms admin rights. The connector already resolves the access-token identity for DelimitedFile source provisioning; form definition ownership should follow the same rule so the invoking service account retains stable ownership.

## What Changes

**Form definition owner on create**
- From: `ensureFormDefinition(..., violation.owner.id)` — violation owner owns new form definitions
- To: `ensureFormDefinition(..., resolveTokenIdentity(ctx.token))` — access-token identity owns new form definitions
- Reason: Reusable tenant asset should be owned by the connector operator, not the incident reviewer
- Impact: Non-breaking for existing tenants (reuse-by-name unchanged); new creates get correct owner

**Offline fallback**
- From: Offline path passes violation owner implicitly via same call
- To: Offline path (`!apiUrl && !token`) uses canned `offline-owner` id without JWT decode
- Reason: Fixtures and test-mode runs have no token
- Impact: Non-breaking; offline behavior unchanged in practice

**Debug instrumentation removal**
- From: Temporary `#region agent log` fetch calls to local ingest URL in SOD and SDK files
- To: Removed; rely on `sod-remediation-logging.ts` and framework request logging
- Reason: Debug-only noise with hardcoded session IDs; not production observability
- Impact: Non-breaking; reduces extraneous network calls during invoke

**SOD remediation logging**
- From: Form definition log omits owner resolution source
- To: Log includes definition owner id and source (`token-identity` | `offline-fallback`)
- Reason: Operators can verify correct owner at create time
- Impact: Non-breaking; additive log fields

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `connector-operations`: Form definition create owner for `custom:sod-remediation` SHALL be access-token identity (with offline fallback)

## Impact

- **Code:** `src/operations/sod-remediation-operation.ts`, `src/isc/sod-remediation-logging.ts`, `src/operations/sod-remediation-operation.spec.ts`, `src/isc/sod-form-service.spec.ts`; remove debug fetch blocks from SOD-related files listed in brainstorm
- **APIs:** No connector-spec or operation I/O contract changes
- **Dependencies:** None
- **Docs:** README SOD section — note form definition owner = token identity
- **Breaking:** None (existing definitions not re-owned)
