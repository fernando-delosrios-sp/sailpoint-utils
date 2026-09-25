## Scope

In: a new custom command that scans machine identities, reads entitlement values from underlying accounts whose source account schema sets `configuration.inboundEntitlements`, matches those values to ISC entitlements, and persists one result-source account per machine identity that has entitlements to add; plus a bundled Account Created workflow that patches those entitlements onto the machine identity and may delete the trigger account. Out: changing existing SoD/risk operations, generic identity (human) entitlement sync, and registering std account commands on this connector.

## Language

**Inbound entitlements attribute** (`promote`):
The account-schema `configuration.inboundEntitlements` string: the name of the account attribute that holds entitlement values (STRING, single or multi) used as the inbound list for a machine identity.
_Avoid_: inbound entitlements config key as if it were the entitlement ids themselves; schema feature flag; entitlement mapping.

**Machine identity persist identity** (`promote`):
The result-source native identity for one machine identity’s evaluation output, `{requestId}:{machineIdentityId}`.
_Avoid_: child persist identity (that term is reserved for access-model SoD); risk persist identity.

**Entitlements to add** (`promote`):
The deduped ISC entitlement ids (with source ids) matched from inbound values that are not already on the machine identity’s `userEntitlements`.
_Avoid_: all matched entitlements (includes already assigned); inbound values (raw account strings, not catalog ids).

**Trigger account** (`promote`):
The result-source account created by persist for this operation, which fires the bundled Account Created workflow.
_Avoid_: underlying account (those are the machine identity’s source accounts); machine account as a synonym for the result row.

**Underlying account** (`promote`):
An ISC account correlated to the machine identity (`identityId` equals the CIS identity id), from which inbound entitlement values are read when the source schema opts in.
_Avoid_: trigger account; result account.

**User entitlements** (`draft` — ISC API field name, not new jargon):
The machine-identity `userEntitlements` collection (`sourceId` + `entitlementId`) patched by the bundled workflow.
_Avoid_: calling this “identity entitlements” without the machine-identity context.

No conflicts found in `openspec/specs/ubiquitous-language/spec.md`. **Child persist identity**, **risk persist identity**, and **operationName core attribute** stay as they are; this change adds a sibling persist-identity spelling, it does not reuse those terms.

## Decisions

Context: operators need machine identities to pick up entitlements whose values already sit on correlated source accounts. The connector already persists per-entity result accounts so ISC Account Created workflows can act; it does not register std create/update. `SchemaPayload.configuration` already exists on the sources client.

Q1 — evaluate in the connector, apply in a workflow? Yes. The operation only evaluates and persists. A bundled Account Created workflow finds the machine identity and PATCHes `userEntitlements`, matching how access-model notification already consumes Account Created on `operationName`.

Q2 — one persist account per machine identity, not one blob? Yes. `{requestId}:{machineIdentityId}` so each create event is one identity’s work. A scan therefore emits as many trigger accounts as machine identities with entitlements to add.

Q3 — when is an underlying account processable? Only when its source account schema `configuration.inboundEntitlements` is a non-blank attribute name. Missing, blank, or unknown attribute → skip that account, do not fail the scan.

Q4 — single vs multi-valued inbound attribute? Both. Normalize to a string list (trim, drop blanks), then match.

Q5 — how to match catalog entitlements? `EntitlementsApi.listEntitlementsV1` with `value eq "{value}"` (tenant-wide). Deduplicate by entitlement id. Unmatched values are skipped with a warning, not a failed invoke.

Q6 — “to add” vs already assigned? Delta against current machine-identity `userEntitlements`. Empty delta → no persist for that identity (no no-op Account Created storm).

Q7 — how does the workflow apply? HTTP PATCH `/machine-identities/v1/{id}` (experimental header as required) adding the persisted entitlement refs to `userEntitlements`. Optional workflow variable deletes the trigger account after a successful patch.

Q8 — optional identity filter on invoke? Yes. Optional `identityId` limits the scan to one machine identity (by MIS id or `cisIdentityId`); omit to paginate all.

## Open questions

- Confirm at implementation which machine-identity field is the Accounts API `identityId` (`id` vs `cisIdentityId`). Default: prefer `cisIdentityId` when present, else `id`. Document the observed mapping in the operation README.
- If one inbound value matches several entitlements on different sources, include all unique ids (collision risk accepted unless a later change scopes match by account `sourceId`).

## Scenarios discussed

- Schema with no `inboundEntitlements` — skip the account.
- `inboundEntitlements` names a missing attribute — skip the account.
- Single-valued attribute `"CN=Admins"` — one value to match.
- Multi-valued attribute with blanks — blanks dropped.
- Value matches no entitlement — skip that value; other values still apply.
- Value already on `userEntitlements` — omitted from entitlements to add.
- Two processable accounts on one machine identity — values unioned, then matched, then delta’d.
- Two machine identities in one invoke — two persist accounts, two Account Created runs.
- Optional `identityId` unknown — fail that invoke with ConnectorError (targeted run), do not silently succeed.
- Full scan with zero machine identities or zero deltas — success, empty `responses`, no persist besides an optional framework failure account (none on success).
- Workflow `Delete Trigger Account` false — trigger account remains.
- Workflow `Delete Trigger Account` true — delete the result-source account after a successful user-entitlements patch.
- Offline invoke — canned machine identities, schemas, accounts, and entitlements; same persist shape.
