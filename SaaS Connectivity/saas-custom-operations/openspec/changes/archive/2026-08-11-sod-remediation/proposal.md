## Why

SOD violation owners need a consistent, professional remediation form populated from live violation data, without manually building forms per incident. ISC workflows should orchestrate email notification and post-submit actions (revoke or apply compensating control), while the connector handles violation lookup, access-path resolution, form definition bootstrap, and standalone form instance creation. Today the scaffold has no SOD or Forms integration.

## What Changes

- Add **`custom:sod-remediation`** — launch-only operation that prepares a remediation form instance and returns a shareable URL plus email-ready situation summary.
- Extend ISC loopback client usage for **experimental violations API**, **tenant controls API**, and **Custom Forms API**.
- Ship a **seed form definition template** (input-driven, workflow-friendly keys) created on first use when `formName` is not found in the tenant.
- Resolve **entitlement conflicts** into display lists including access profiles and roles when the target identity holds the entitlement through those paths, with elevated-access warnings.

**Operation contract**
- Input: `violationId`, `formName`, optional `owner` (recipient identity ID override)
- Output: `formUrl`, `situationSummary`

**Explicit non-goals**
- Revoke access or apply mitigating controls (downstream workflow)
- Update existing form definitions after creation

## Capabilities

### New Capabilities

_(none — requirements extend existing connector capabilities)_

### Modified Capabilities

- `connector-operations`: register and specify behavior of `custom:sod-remediation`
- `target-client`: ISC client surface for violations, controls, forms, and identity access resolution

## Impact

- New: `src/operations/sod-remediation-operation.ts`, seed JSON under `assets/forms/`, ISC client helpers
- Modify: `src/framework/sdk-factory.ts`, `src/framework/types.ts`, generated `auto-registry.ts`, `connector-spec.json` (codegen)
- Tests: unit tests with mocked violation/forms/controls responses; operation fixture
- Docs: README section, CHANGELOG entry via changelog-generator skill at apply
- External: experimental APIs require `X-SailPoint-Experimental: true` and appropriate PAT scopes
