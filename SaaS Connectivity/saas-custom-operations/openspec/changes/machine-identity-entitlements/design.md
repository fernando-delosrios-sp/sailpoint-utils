## Context

The connector is an ISC custom-operations host: handlers loop back with `ctx.sdk`, persist typed output onto a DelimitedFile result source, and leave apply/notify work to bundled workflows. Sources expose native connector configuration through `connectorAttributes`, and Machine Accounts expose the authoritative `machineIdentity` link plus raw `connectorAttributes`. `sailpoint-api-client` ships both APIs and entitlement filters on `value`.

Discovery locked evaluate-in-connector / apply-in-workflow, one persist account per machine identity with work to do, schema opt-in, and optional trigger-account delete.

## Architecture

[Container diagram](./diagrams/machine-identity-entitlements.drawio)

## Goals / Non-Goals

**Goals:**

- Register `custom:machine-identity-entitlements` with optional `identityId`
- Process a machine account only when its source has a non-blank `connectorAttributes.userEntitlements` setting
- Normalize single- and multi-valued attribute values, match catalog entitlements by `value`, compute entitlements to add vs current `userEntitlements`
- Persist one trigger account per machine identity that has a non-empty add list, keyed by machine identity persist identity
- Bundle an Account Created workflow that PATCHes `userEntitlements` and optionally deletes the trigger account
- Offline fixtures for local `call:op`

**Non-Goals:**

- Std command handlers on this connector
- Human identity entitlement sync
- Access-request grant as the apply path (PATCH machine identity is the apply path)
- Failing the whole scan for unconfigured sources or unmatched values
- Changing SoD/risk operations

## Decisions

### D1: Split evaluate vs apply

- **Choice**: The operation only evaluates and persists. A bundled Account Created workflow applies `userEntitlements`.
- **Reason**: Matches access-model notification (`operationName` filter). Keeps this connector free of std create. Each trigger account is one identity’s work.
- **Considered alternatives**: Apply inside the handler — rejected; user asked for an account-create workflow and optional delete of the trigger account. A second custom apply command — extra hop with no extra contract value for a PATCH.

### D2: Persist identity and cardinality

- **Choice**: Native identity `{requestId}:{machineIdentityId}`. Persist only when entitlements to add is non-empty. Scan-wide success with empty `responses` when nobody has a delta.
- **Reason**: One Account Created per identity with work; avoids empty-list storms. Still “as many accounts as machine identities” that need entitlements.
- **Considered alternatives**: One account for the whole scan — rejected; workflow could not process identities independently. Persist empty lists — rejected as no-op event load.

### D3: Source connector configuration

- **Choice**: Read the entitlement attribute name from source `connectorAttributes.userEntitlements`, then read that key from each machine account's `connectorAttributes`. Cache source configuration by `sourceId`; skip missing or blank settings.
- **Reason**: This is the connector's native configuration. On `Microsoft Entra ID @emea-tes-team.cloud (NHI)` it is `spn_app_groups`.
- **Considered alternatives**: Custom account-schema `configuration.inboundEntitlements` — rejected because it duplicates native connector configuration and was absent on the live source.

### D4: Value extraction

- **Choice**: Treat the named attribute as string or `string[]`. Trim, drop blanks, union across processable accounts on the same identity.
- **Reason**: User required single- and multi-valued. Union is the only way two sources can contribute.
- **Considered alternatives**: First processable account only — rejected; under-collects.

### D5: Catalog match

- **Choice**: `listEntitlementsV1` with `value eq "{escaped}"`, then keep only records whose `source.id` equals the machine account source. Deduplicate by entitlement id. Unmatched values: warn, continue.
- **Reason**: The live Entra Users and NHI sources contain distinct entitlement records with identical values; retaining both would assign the machine identity an entitlement from the wrong source.
- **Considered alternatives**: Tenant-wide value match — rejected after live validation exposed cross-source duplicates.

### D6: Delta vs assigned

- **Choice**: Compare matched `{sourceId, entitlementId}` to machine identity `userEntitlements`. Persist only the remainder as parallel multi-value STRING attributes (`entitlement-ids`, `entitlement-source-ids`).
- **Reason**: “To add” is a delta. Parallel arrays stay under the 256-char-per-value STRING cap; JSON blobs would not.
- **Considered alternatives**: Persist raw inbound values for the workflow to resolve — duplicates catalog work and races. Persist JSON array — exceeds STRING limits and is awkward on DelimitedFile.

### D7: SDK layout

- **Choice**: `ctx.sdk.machineAccounts` (`MachineAccountsApi`) drives the scan; `ctx.sdk.machineIdentities` supplies current `userEntitlements`. Add `src/isc/machine-accounts/` pagination and retain dedicated machine-identities/entitlements wrappers.
- **Reason**: target-client per-API folders and the Machine Accounts response is the authoritative account-to-identity relation.
- **Considered alternatives**: Inline SDK in the operation — rejected; breaks isc boundaries.

### D8: Machine-account correlation

- **Choice**: List `/v2026/machine-accounts` and group by its authoritative `machineIdentity.id` node. Optional invoke `identityId` resolves one machine identity, then keeps only linked machine accounts; unknown → `ConnectorError`.
- **Reason**: Live tenant accounts did not correlate through Accounts `identityId`, while all 299 Entra NHI machine accounts had a `machineIdentity` node.
- **Considered alternatives**: Match by account name — only partial coverage and not authoritative. Accounts `identityId` → machine identity id — disproven on the live tenant.

### D9: Authentication and errors

- **Choice**: Standard invoke envelope. Connected path requires PAT scopes for machine identities, machine accounts, sources, entitlements, and result-source accounts. Required API failures fail the invoke. Per-account skip is non-fatal. Offline: fixtures, no live calls.
- **Reason**: Same loopback as other operations. Schema opt-out must not fail a tenant-wide scan.

### D10: Bundled workflow

- **Choice**: Trigger Account Created on the result source, advanced JSONPath filter `$.account.attributes[?(@.operationName == "custom:machine-identity-entitlements")]`. Steps: read persisted ids; GET machine identity; PATCH `userEntitlements` as union; if workflow variable **Delete Trigger Account** is true, delete the trigger account by native identity / account id from the event.
- **Reason**: User required optional delete of the trigger account after apply.
- **Considered alternatives**: Always delete — not optional. Delete before PATCH — loses the payload if PATCH fails.

### D11: Operation response

- **Choice**: Persist remains the workflow contract. Optional response summary counts (identities scanned, trigger accounts written) are `OperationSignature.response` only — not account schema fields.
- **Reason**: Aligns with scan summary vs operation output.

## Risks / Trade-offs

- [Risk] `cisIdentityId` vs `id` mismatch → Mitigation: prefer `cisIdentityId`; document observed mapping; fixture both shapes
- [Risk] Duplicate entitlement `value` across sources and membership types → Accept: each record is a distinct ISC entitlement, so all unique ids are persisted; the UI shows repeated display names for one Entra group
- [Risk] Parallel arrays desync in workflows → Mitigation: tests assert equal length; README says zip by index
- [Risk] Experimental Machine Identities API drift → Mitigation: isolate in `src/isc/machine-identities/`
- [Risk] Large tenants / N+1 source and entitlement reads → Mitigation: cache source configuration by sourceId and entitlement matches by value; paginate machine accounts
- [Trade-off] Skip empty deltas vs persist every MI → Accept: fewer Account Created events; operators still get one account per MI that needs entitlements
- [Trade-off] Workflow PATCH vs access request → Accept: `userEntitlements` is the MIS field; access request would grant account entitlements, not this collection

## Migration Plan

New command and workflow. No breaking change to existing operations.

1. Implement, codegen (`connector-spec.json`, auto-registry), tests
2. Publish connector; import workflow; point Account Created at the result source; set Delete Trigger Account
3. Confirm each source's native `connectorAttributes.userEntitlements` names the intended machine-account connector attribute
4. Invoke without `identityId` for a full scan, or with `identityId` for one identity

Rollback: disable/delete the workflow; previous connector builds simply lack the command.

## Open Questions

- Confirm PATCH replace-vs-add semantics for `userEntitlements` (workflow MUST GET then union, never replace with only the add list).
