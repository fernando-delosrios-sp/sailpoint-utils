## Context

The connector is an ISC custom-operations host: handlers loop back with `ctx.sdk`, persist typed output onto a DelimitedFile result source, and leave apply/notify work to bundled workflows. Account schemas already expose `configuration` (`SchemaPayload`). `sailpoint-api-client` already ships `MachineIdentitiesApi` and entitlement filters on `value`. Nothing in this repo evaluates machine identities or writes `userEntitlements`.

Discovery locked evaluate-in-connector / apply-in-workflow, one persist account per machine identity with work to do, schema opt-in, and optional trigger-account delete.

## Architecture

[Container diagram](./diagrams/machine-identity-entitlements.drawio)

## Goals / Non-Goals

**Goals:**

- Register `custom:machine-identity-entitlements` with optional `identityId`
- Process an underlying account only when its source account schema has a non-blank inbound entitlements attribute
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

### D3: Schema opt-in

- **Choice**: `configuration.inboundEntitlements` on the source **account** schema is the attribute name. Cache schema by `sourceId`. Skip the account when missing, blank, or the named attribute is absent.
- **Reason**: Operators opt in per source without connector config. Existing `getAccountSchema` already returns `configuration`.
- **Considered alternatives**: Invoke-config map of source → attribute — rejected; user specified account schema configuration.

### D4: Value extraction

- **Choice**: Treat the named attribute as string or `string[]`. Trim, drop blanks, union across processable accounts on the same identity.
- **Reason**: User required single- and multi-valued. Union is the only way two sources can contribute.
- **Considered alternatives**: First processable account only — rejected; under-collects.

### D5: Catalog match

- **Choice**: `listEntitlementsV1` with `value eq "{escaped}"`. Deduplicate by entitlement id. Keep `sourceId` from each entitlement record. Unmatched values: warn, continue.
- **Reason**: Entitlements API documents `value` eq/in/sw. Tenant-wide match matches “in the system”.
- **Considered alternatives**: Match also on account `sourceId` — safer against collisions, but would miss values that name entitlements on another source. Deferred unless collisions appear.

### D6: Delta vs assigned

- **Choice**: Compare matched `{sourceId, entitlementId}` to machine identity `userEntitlements`. Persist only the remainder as parallel multi-value STRING attributes (`entitlement-ids`, `entitlement-source-ids`).
- **Reason**: “To add” is a delta. Parallel arrays stay under the 256-char-per-value STRING cap; JSON blobs would not.
- **Considered alternatives**: Persist raw inbound values for the workflow to resolve — duplicates catalog work and races. Persist JSON array — exceeds STRING limits and is awkward on DelimitedFile.

### D7: SDK layout

- **Choice**: `ctx.sdk.machineIdentities` (`MachineIdentitiesApi`). New `src/isc/machine-identities/` (list/get, pagination, experimental header) and `src/isc/entitlements/` (list by value). Reuse `src/isc/accounts` and `src/isc/sources`.
- **Reason**: target-client per-API folders. EntitlementsApi is already on `ctx.sdk`; it lacked a dedicated isc wrapper.
- **Considered alternatives**: Inline SDK in the operation — rejected; breaks isc boundaries.

### D8: Identity correlation for underlying accounts

- **Choice**: `listAccounts` `identityId eq "{cisIdentityId ?? machineIdentity.id}"`. Optional invoke `identityId` filters machine identities by `id eq` then `cisIdentityId eq`; unknown → `ConnectorError`.
- **Reason**: Accounts API filters `identityId`. MIS objects may use `cisIdentityId` as the CIS cube id.
- **Considered alternatives**: Search identities index `type:MACHINE` — bypasses Machine Identity Security `userEntitlements`.

### D9: Authentication and errors

- **Choice**: Standard invoke envelope. Connected path requires PAT scopes for machine identities (experimental), accounts, sources, entitlements. Required API failures fail the invoke. Per-account skip is non-fatal. Offline: fixtures, no live calls.
- **Reason**: Same loopback as other operations. Schema opt-out must not fail a tenant-wide scan.

### D10: Bundled workflow

- **Choice**: Trigger Account Created on the result source, advanced filter `operationName == custom:machine-identity-entitlements`. Steps: read persisted ids; GET machine identity; PATCH `userEntitlements` as union; if workflow variable **Delete Trigger Account** is true, delete the trigger account by native identity / account id from the event.
- **Reason**: User required optional delete of the trigger account after apply.
- **Considered alternatives**: Always delete — not optional. Delete before PATCH — loses the payload if PATCH fails.

### D11: Operation response

- **Choice**: Persist remains the workflow contract. Optional response summary counts (identities scanned, trigger accounts written) are `OperationSignature.response` only — not account schema fields.
- **Reason**: Aligns with scan summary vs operation output.

## Risks / Trade-offs

- [Risk] `cisIdentityId` vs `id` mismatch → Mitigation: prefer `cisIdentityId`; document observed mapping; fixture both shapes
- [Risk] Duplicate entitlement `value` across sources → Mitigation: persist all unique ids; revisit source-scoped match if operators see false grants
- [Risk] Parallel arrays desync in workflows → Mitigation: tests assert equal length; README says zip by index
- [Risk] Experimental Machine Identities API drift → Mitigation: isolate in `src/isc/machine-identities/`
- [Risk] Large tenants / N+1 schema reads → Mitigation: cache schema by sourceId; paginate lists
- [Trade-off] Skip empty deltas vs persist every MI → Accept: fewer Account Created events; operators still get one account per MI that needs entitlements
- [Trade-off] Workflow PATCH vs access request → Accept: `userEntitlements` is the MIS field; access request would grant account entitlements, not this collection

## Migration Plan

New command and workflow. No breaking change to existing operations.

1. Implement, codegen (`connector-spec.json`, auto-registry), tests
2. Publish connector; import workflow; point Account Created at the result source; set Delete Trigger Account
3. On each opted-in source, set account schema `configuration.inboundEntitlements` to the attribute name
4. Invoke without `identityId` for a full scan, or with `identityId` for one identity

Rollback: disable/delete the workflow; previous connector builds simply lack the command.

## Open Questions

- Confirm Accounts `identityId` field mapping on a live tenant (default in D8).
- Confirm PATCH replace-vs-add semantics for `userEntitlements` (workflow MUST GET then union, never replace with only the add list).
