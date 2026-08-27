## Why

Access approval workflows need an early signal: would this identity violate SoD if pending grant requests were approved? Without a connector operation, teams chain multiple HTTP calls or maintain a separate microservice. A proven prototype (`.scratch/sod-check`) uses ISC's predict API; the ABB branch used a weaker local matcher. Packaging the predict-based approach as `custom:preventive-sod-check` gives workflows persisted, namespaced outputs aligned with sod-remediation for email and branching steps.

## What Changes

- Add **`custom:preventive-sod-check`** — evaluates pending GRANT_ACCESS requests for an identity via ISC SoD prediction and persists situation summary fields.
- Port algorithm from `.scratch/sod-check`: filter executing grants, resolve items via events search with retry, expand roles/APs to entitlements, call `startPredictSodViolationsV1`.
- Add ISC modules for access-request status, executing-request events search, and SoD prediction (entitlement expansion reuses existing roles/access-profiles clients).
- Situation summary builder with optional `accessRequestId` input affecting narrative only.

**Operation contract**
- Input: `identityId` (required), `accessRequestId` (optional)
- Output (persisted, namespaced):
  - `preventive-sod-check:situation-summary` — e.g. "No violations found" or policy attribution text
  - `preventive-sod-check:violated-policy-names` — string[] of **all** violated policy names (empty when none)

**Situation summary rules**
- No violations → `"No violations found"`
- Violations without `accessRequestId` → list all violating policies
- Violations with `accessRequestId` → summary attributes violation to that access request; `violated-policy-names` still lists all policies

**Explicit non-goals**
- `approved` boolean/string output (dropped from scratch prototype)
- Local SoD policy matching (ABB `check-sod-pending`)
- access-request-status, access-request-threshold, or remediation actions
- Substitute for ISC violation certification

## Capabilities

### New Capabilities

- `connector-operations/preventive-sod-check`: Register and specify behavior of `custom:preventive-sod-check`

### Modified Capabilities

- `target-client`: Add access-request listing, executing-request events search, and SoD violation prediction client surfaces

## Impact

- New: `src/operations/preventive-sod-check/`, ISC helpers, offline fixtures, payloads, operation README
- Modify: `connector-spec.json` (codegen), root README, CHANGELOG
- Tests: summary builder scenarios, predict response parsing, offline invoke via `call:op`
- External: SoD predict API; events search index; appropriate PAT scopes
- Supersedes `.scratch/sod-check` standalone connector (optional cleanup later)
