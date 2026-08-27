# Brainstorm: custom:sod-remediation

Raw capture from design exploration (Aug 2026).

## Background

ISC SOD Violation Management exposes experimental APIs to read violations and apply compensating controls. Compliance teams need a guided remediation UI that violation owners can complete, while orchestration (revoke access, apply control) stays in standard ISC workflows.

The saas-custom-operations connector scaffold supports auto-discovered custom operations with typed I/O and ISC loopback via `sailpoint-api-client`. A scratch form export (`SOD Violation Remediation`) and Emergency Termination workflow patterns in sailpoint-utils demonstrate ISC Forms `formInput` + conditional defaults.

## Agreed scope

**In scope (connector):**
- New command `custom:sod-remediation`
- Fetch violation by ID (`GET /violations/v1/:id`, experimental header)
- Resolve conflicting entitlement pair; expand to access profiles/roles when identity holds entitlement via those paths
- Ensure form definition exists by name (create from seed if missing; never PATCH existing)
- List tenant compensating controls (`GET /controls/v1`) to gate Mitigate UI
- Create standalone form instance for recipient with violation-driven `formInput`
- Return minimal output: `formUrl`, `situationSummary`

**Out of scope (connector):**
- Executing revoke or apply-control (workflow responsibility)
- Updating form definition after initial create (preserves admin cosmetic edits)

## Decision chain

### Q1: Operation phases?
**Decision:** Launch-only. Connector prepares form instance; downstream workflow reads submitted `formData` and executes Correct (revoke) or Mitigate (apply-control) via HTTP actions.

### Q2: Recipient?
**Decision:** Violation owner by default. Optional input `owner` (identity ID) overrides recipient.

### Q3: Form definition lifecycle?
**Decision:** Input `formName` identifies tenant form. Search by name; create from bundled seed template if absent. Reuse existing definition ID when found.

### Q4: Form output contract?
**Decision:** Stable element keys for workflow JSONPath:
- User-facing: `action`, `remediationSide`, `policyControl`, `comments`
- Hidden (launch-populated): `violationId`, `targetIdentityId`, `groupARevokePayload`, `groupBRevokePayload` (JSON strings)

### Q5: Corrective removal rules?
**Decision:** Violation is an entitlement pair (group A vs group B). User selects exactly one side via `remediationSide` SELECT. Display lists include entitlement plus any assigned access profile/role containing that entitlement. Warn in help text when AP/role present. Hidden payload includes `recommendedRevoke` (highest level: Role > Access Profile > Entitlement).

### Q6: Mitigation controls source?
**Decision:** Tenant-level catalog via `GET /controls/v1`, not policy-bound. If zero controls, hide Mitigate path and note in summary.

### Q7: Operation I/O?
**Input:** `violationId` (required), `formName` (required), `owner?` (recipient override)
**Output:** `formUrl`, `situationSummary` only (workflow already knows violationId, formName, owner)

### Q8: Professional form UX?
**Decision:** Seed template includes DESCRIPTION blocks for context (identity, policy, situation summary HTML via formInput interpolation). Email-oriented plain-text `situationSummary` generated separately at launch.

## Approaches considered

| Approach | Trade-off |
|----------|-----------|
| Single op with launch + execute phases | Rejected — user wants workflow to execute decisions |
| PATCH form definition per violation | Rejected — breaks cosmetic reuse goal |
| Policy-bound control list | Rejected — controls are tenant-scoped |
| Dual toggles for group removal | Rejected — exactly one side must be removable |

## Open items for implementation spike

- Confirm violation response field names for left/right criteria and owner reference
- Confirm identity access API for entitlement → AP/role expansion on target identity
- Confirm tenant controls SELECT data source (SEARCH_V2 vs fallback) in Forms builder
- Parse `formInstanceId` from `standAloneFormUrl` if workflow needs it (not in operation output)

## Reference assets

- Scratch form: `.scratch/Forms/Form-company22986-poc.identitynow.com-SOD Violation Remediation-20260810-110359.json`
- ET formInput pattern: `ISC/Emergency Termination/Emergency Termination.sp-config.json`
