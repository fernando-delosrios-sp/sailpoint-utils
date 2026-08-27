## Context

The connector scaffold provides typed custom operations with ISC loopback (`ctx.sdk`). SOD Violation Management adds experimental REST APIs for reading violations and listing tenant compensating controls. ISC Custom Forms support reusable definitions with `formInput`-driven defaults (validated by Emergency Termination patterns in sailpoint-utils).

The operation is **launch-only**: it creates a standalone form instance for the violation owner (or override recipient) and returns `formUrl` + `situationSummary`. A separate ISC workflow sends email, waits for form submission, reads `formData`, and executes revoke or apply-control.

## Goals / Non-Goals

**Goals:**
- Implement `custom:sod-remediation` with agreed I/O contract
- Ensure form definition exists by `formName` (create once from seed, reuse thereafter)
- Populate form instance with violation context, access-path expansion, and workflow-friendly hidden fields
- Return standalone form URL and plain-text situation summary for notification workflows

**Non-Goals:**
- Execute corrective revokes or mitigation API calls
- PATCH or overwrite existing form definitions
- Persist violation execution context beyond optional `ctx.persist` of output fields

## Decisions

### D1: Launch-only operation boundary
- **选择:** Connector creates form instance; workflow executes decisions from submitted `formData`.
- **理由:** User explicitly deferred revoke/mitigate to workflow; keeps connector focused and testable.
- **已考虑 alternative:** Two-phase single command — rejected as unnecessary coupling.

### D2: Recipient resolution
- **选择:** `recipientId = input.owner ?? violation.owner.id`
- **理由:** Owner is default reviewer; optional `owner` input allows delegation.
- **已考虑 alternative:** Always violation target identity — rejected (wrong actor for compliance review).

### D3: Form definition lifecycle
- **选择:** `searchFormDefinitionsByTenantV1` filtered by `formName`; if missing, `createFormDefinitionV1` from bundled seed with `name = formName`.
- **理由:** Supports cosmetic admin edits and multiple named forms per tenant.
- **已考虑 alternative:** Fixed name in sourceConfig — rejected; user wants per-invoke `formName`.

### D4: Minimal operation output
- **选择:** Output only `formUrl` and `situationSummary`.
- **理由:** Caller already holds `violationId`, `formName`, and `owner`; reduces payload noise.
- **已考虑 alternative:** Echo IDs — user dropped them from output contract.

### D5: Access path expansion
- **选择:** For each conflicting entitlement on a side, list direct entitlement plus any assigned access profile or role on the target identity that grants it. Set per-side warning help text when AP/role present. Hidden JSON payload per side includes items and `recommendedRevoke` (Role > Access Profile > Entitlement).
- **理由:** Owners must see effective access path; revoke workflow needs structured targets.
- **已考虑 alternative:** Entitlement names only — insufficient for AP/role-granted access.

### D6: Single-side corrective removal
- **选择:** Form element `remediationSide` SELECT (`groupA` | `groupB`); exactly one side choosable when `action = Correct`.
- **理由:** SOD corrective action removes one side of the toxic pair, not both.
- **已考虑 alternative:** Dual toggles from scratch form — rejected.

### D7: Tenant compensating controls
- **选择:** `GET /controls/v1` at launch; if empty, hide Mitigate section via `formInput.hasControls=false` conditions; `policyControl` SELECT uses tenant-scoped data source in seed form.
- **理由:** Controls are tenant-level, not policy-bound (user correction).
- **已考虑 alternative:** Policy embedded controls — incorrect model.

### D8: Experimental API transport
- **选择:** Thin HTTP helper alongside SDK clients, sending `X-SailPoint-Experimental: true` for `/violations/v1/*` and `/controls/v1`.
- **理由:** Not yet in bundled `sailpoint-api-client` for this project version.
- **已考虑 alternative:** Wait for SDK — blocks delivery.

### D9: Form instance mode
- **选择:** `standAloneForm: true`, `state: ASSIGNED`, `createdBy.type: SOURCE`.
- **理由:** API returns `standAloneFormUrl` for email deep links.

### D10: Workflow form keys (stable contract)
- **选择:** User keys: `action`, `remediationSide`, `policyControl`, `comments`. Hidden keys: `violationId`, `targetIdentityId`, `groupARevokePayload`, `groupBRevokePayload`.
- **理由:** Workflow JSONPath stability without re-fetching violation.

## Risks / Trade-offs

- [Risk] Experimental API shape changes → Mitigation: isolate in `src/isc/violations-client.ts`; fixture tests with recorded payloads
- [Risk] Access path resolution incomplete → Mitigation: spike against tenant; fall back to entitlement-only list with log warning
- [Risk] Dynamic control SELECT unsupported in form builder → Mitigation: spike SEARCH_V2; fallback DESCRIPTION list + TEXT control ID field
- [Trade-off] No `formInstanceId` in output → Accept: parse from URL or workflow tracks correlation via input `violationId`

## Migration Plan

N/A — new custom command; no breaking changes to existing operations. Deploy updated connector bundle; register command via codegen sync to `connector-spec.json`. Workflows must invoke with new input shape.

## Open Questions

- Exact violation response schema field paths for criteria sides (confirm at implementation spike)
- Optimal identity API for AP/role cross-reference (Search vs `listIdentityAccessItemsV1`)
- Form SELECT data source for tenant controls (implementation spike)
