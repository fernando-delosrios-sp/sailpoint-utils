## Why

Machine identities already carry entitlement *values* on correlated source accounts, but those values do not become machine-identity `userEntitlements` unless someone maps them by hand. Operators need a scan that opts in per source account schema, matches catalog entitlements, and hands each identity to an Account Created workflow for apply. This connector already persists per-entity result accounts for that pattern; there is no machine-identity command yet.

## What Changes

- Add **`custom:machine-identity-entitlements`**: evaluate machine identities, read inbound entitlement values from processable underlying accounts, match ISC entitlements, persist one trigger account per identity that has entitlements to add.
- Opt-in is **inbound entitlements attribute** on the source account schema (`configuration.inboundEntitlements`), single- or multi-valued.
- Add thin ISC wrappers for machine identities and entitlement lookup by value; reuse existing accounts and sources clients.
- Ship a bundled Account Created workflow that PATCHes `userEntitlements` and optionally deletes the trigger account.

**Operation contract**

- Input: optional `identityId` (one machine identity); omit to scan all.
- Persist identity: **machine identity persist identity** `{requestId}:{machineIdentityId}`.
- Output (namespaced):
  - `machine-identity-entitlements:machine-identity-id`
  - `machine-identity-entitlements:entitlement-ids` (`string[]`)
  - `machine-identity-entitlements:entitlement-source-ids` (`string[]`, same order)

**Explicit non-goals**

- Std account create/update on this connector
- Human identity entitlement sync
- Changing SoD or risk operations
- Failing the scan because a source is not opted in or a value has no catalog match

**Open questions carried from discovery**

- Accounts API `identityId` mapping (`cisIdentityId` vs machine-identity `id`) confirmed at implementation; default prefer `cisIdentityId`.
- Multi-source entitlement value collisions: include all unique matched ids.

## Capabilities

### New Capabilities

- `connector-operations/machine-identity-entitlements`: register and specify `custom:machine-identity-entitlements` and the bundled apply workflow
- `target-client/machine-identities`: list/get machine identities and read `userEntitlements`
- `target-client/entitlements`: list entitlements filtered by `value`

### Modified Capabilities

- `connector-operations`: namespaced persist keys for this slug
- `target-client`: add machine-identities and entitlements folders to the ISC module layout; expose `MachineIdentitiesApi` on `ctx.sdk`
- `ubiquitous-language`: promote inbound entitlements attribute, machine identity persist identity, entitlements to add, trigger account, underlying account

## Impact

Code: `src/operations/machine-identity-entitlements/`, `src/isc/machine-identities/`, `src/isc/entitlements/`, `sdk-factory` / `SailPointClients`, `connector-spec.json` via codegen, `workflows/` export, payloads, root README.

Tests: schema opt-in, single/multi values, match/delta/persist cardinality, unknown `identityId`, offline fixtures, workflow JSON contract.

External: PAT scopes for machine identities (experimental), accounts, sources/schemas, entitlements; workflow import and Account Created trigger on the result source.

Rollback: remove the workflow and stop invoking the command; prior connector versions ignore the new command.
