## Why

Machine identities already have linked Machine Accounts carrying entitlement *values*, but those values do not become machine-identity `userEntitlements` unless someone maps them by hand. The first implementation split evaluation and apply across per-identity trigger accounts and a second custom command. That indirection is unnecessary: the scan already has the identities, matched entitlements, SDK client, and authorization needed to PATCH the union itself.

## What Changes

- **`custom:machine-identity-entitlements`** lists machine accounts, follows each `machineIdentity` node, reads configured connector entitlement values, matches catalog entitlements by value across sources, and directly PATCHes each machine identity's `userEntitlements` union.
- Entitlement input uses the source's native `connectorAttributes.userEntitlements` setting and the named field on machine-account `connectorAttributes`.
- Patches use bounded concurrency and continue after an individual identity fails.
- Persist exactly one **scan summary account** per invoke, keyed by `requestId`, containing scanned, updated, skipped, failed, and entitlements-added counts plus failed identity details.
- Mixed outcomes succeed with summary status `partial`; an all-failed apply persists status `failed` and then reports operation failure.
- Remove `custom:machine-identity-entitlements-apply`, its payload/tests/schema, and the Account Created Apply workflow.
- Keep the interactive Scan workflow as the wrapper and update its result messages to use the summary counts.

**Operation contract**

- Input: optional `identityId` (one machine identity); omit to scan all.
- Persist identity: **scan summary identity** `{requestId}`.
- Output (namespaced):
  - `machine-identity-entitlements:identities-scanned`
  - `machine-identity-entitlements:identities-updated`
  - `machine-identity-entitlements:identities-skipped`
  - `machine-identity-entitlements:identities-failed`
  - `machine-identity-entitlements:entitlements-added`
  - `machine-identity-entitlements:failed-identity-ids`
  - `machine-identity-entitlements:failure-details`

**Explicit non-goals**

- Std account create/update on this connector
- Human identity entitlement sync
- Changing SoD or risk operations
- Failing the scan because a source is not opted in or a value has no catalog match

## Capabilities

### New Capabilities

- `connector-operations/machine-identity-entitlements`: specify direct evaluate-and-apply behavior, continue-and-summarize errors, and the single summary account
- `target-client/machine-identities`: list/get/patch machine identities and read `userEntitlements`
- `target-client/entitlements`: list entitlements filtered by `value`

### Modified Capabilities

- `connector-operations`: replace per-identity trigger output with scan-summary output and remove the apply command
- `target-client`: add machine-identities and entitlements folders to the ISC module layout; expose `MachineIdentitiesApi` on `ctx.sdk`
- `ubiquitous-language`: retain machine-account and entitlements-to-add terms; replace trigger-account vocabulary with scan summary account

## Impact

Code: `src/operations/machine-identity-entitlements/`, removal of `src/operations/machine-identity-entitlements-apply/`, `src/isc/machine-identities/`, generated registry/spec files, Scan workflow, payloads, README, and changelog.

Tests: schema opt-in, single/multi values, matching and union, bounded patch concurrency, success/no-op/mixed/all-failed summaries, unknown `identityId`, offline fixtures, and Scan workflow contract.

External: PAT scopes for machine identity list/get/patch (experimental), machine accounts, sources/schemas, entitlements, and one result-source summary account.

Rollback: deploy the prior connector version and restore the Apply workflow if the split architecture is needed again.
