# Proposal: SOD remediation access search strings

## Why

Downstream ISC workflows read submitted SOD remediation form data to fetch access items and drive corrective removal. Hidden `groupARevokePayload` / `groupBRevokePayload` fields were JSON strings workflows cannot parse. Workflow authors need plain, paste-ready ISC access-item search filters per violation side instead of structured blobs requiring a transform step.

## What Changes

**Form hidden keys**
- From: `groupARevokePayload`, `groupBRevokePayload` (stringified JSON with `items` and `recommendedRevoke`)
- To: `groupAAccessSearch`, `groupBAccessSearch` (plain filters: `id:x OR id:y`)
- Reason: ISC workflows consume form outputs as flat strings, not parsed objects
- Impact: **Breaking** for workflows referencing old hidden keys; operation launch/persist outputs unchanged

**Implementation**
- Add `buildAccessSearchString()` derived from resolved access path ids
- Update bundled seed hidden TEXT elements and SET_DEFAULT_VALUE conditions
- Keep internal `revokePayload` on `ResolvedAccessSide` for resolver/logging only

## Capabilities

### New Capabilities

_(none — behavior extends existing sod-remediation form contract)_

### Modified Capabilities

- `connector-operations/sod-remediation`: Replace hidden revoke JSON payload requirements with per-side access search string requirements; clarify revocability metadata stays internal/HTML-only

## Impact

- **Code:** `context.ts`, `form-service.ts`, `access-path-resolver.ts`, seed JSON, logging, tests
- **Docs:** README workflow integration section, CHANGELOG breaking note
- **Tenants:** Form definition watermark applies seed on next launch; workflows must switch JSONPath keys
- **Non-breaking:** Operation persisted outputs (`form-url`, `situation-summary`, etc.) unchanged
