# connector-operations/machine-identity-entitlements Delta

## ADDED Requirements

### Requirement: Machine identity entitlements operation

The connector SHALL register a custom command `custom:machine-identity-entitlements` that evaluates machine identities, reads entitlement values from processable **underlying accounts**, matches ISC entitlements, and persists **entitlements to add** on one **trigger account** per machine identity that has a non-empty add list.

#### Scenario: Auto-discovery registration

- **GIVEN** `src/operations/machine-identity-entitlements/index.ts` declares `command: 'custom:machine-identity-entitlements'` on its OperationSignature interface
- **WHEN** codegen runs
- **THEN** `custom:machine-identity-entitlements` SHALL be registered in auto-registry.ts and listed in connector-spec.json commands

#### Scenario: Full scan persists one trigger account per identity with work

- **GIVEN** two machine identities each have at least one entitlement to add
- **AND** invoke input omits `identityId`
- **WHEN** `custom:machine-identity-entitlements` executes
- **THEN** the handler SHALL persist two result-source accounts
- **AND** each native identity SHALL be the **machine identity persist identity** `{requestId}:{machineIdentityId}`
- **AND** the operation response **response id list** SHALL contain those two identities

#### Scenario: Empty delta skips persist

- **GIVEN** a machine identity whose matched entitlements are already on `userEntitlements`
- **WHEN** the handler evaluates that identity
- **THEN** the handler SHALL NOT persist a trigger account for that identity

#### Scenario: Tenant scan with no work succeeds

- **GIVEN** a connected invoke with no `identityId`
- **AND** no machine identity has entitlements to add
- **WHEN** the command completes
- **THEN** the handler SHALL succeed
- **AND** SHALL persist no trigger accounts for this command

#### Scenario: Targeted unknown identity rejected

- **GIVEN** invoke input `identityId` does not match a machine identity `id` or `cisIdentityId`
- **WHEN** `custom:machine-identity-entitlements` executes
- **THEN** the handler SHALL fail with a ConnectorError indicating the machine identity was not found

#### Scenario: Optional identityId limits the scan

- **GIVEN** invoke input `identityId` matches one machine identity
- **WHEN** the command executes
- **THEN** the handler SHALL evaluate only that machine identity
- **AND** SHALL NOT list all machine identities as the working set

#### Scenario: Operation README documents contract

- **GIVEN** the auto-discovered operation at `src/operations/machine-identity-entitlements/index.ts`
- **WHEN** a developer reads `src/operations/machine-identity-entitlements/README.md`
- **THEN** the README SHALL document the command name, optional `identityId`, persist identity, namespaced output keys, inbound entitlements attribute, workflow integration, and token scopes

#### Scenario: Offline invoke supported

- **GIVEN** invocation input has no `apiUrl` and no `token` (offline test mode)
- **WHEN** `custom:machine-identity-entitlements` executes
- **THEN** the handler SHALL use canned machine identities, accounts, schemas, and entitlements without calling ISC APIs
- **AND** SHALL persist the same namespaced output shape as connected mode

### Requirement: Inbound entitlements schema opt-in

The operation SHALL process an **underlying account** only when that account’s source account schema `configuration.inboundEntitlements` is a non-blank attribute name present on the schema. Missing configuration, a blank value, or a named attribute that is absent SHALL skip that account and SHALL NOT fail the invoke.

#### Scenario: Schema without inboundEntitlements is skipped

- **GIVEN** an underlying account whose source account schema has no `configuration.inboundEntitlements`
- **WHEN** the handler evaluates the owning machine identity
- **THEN** the handler SHALL NOT read entitlement values from that account
- **AND** SHALL NOT fail the invoke solely for that skip

#### Scenario: Unknown attribute name is skipped

- **GIVEN** `configuration.inboundEntitlements` is `groups`
- **AND** the account schema has no attribute named `groups`
- **WHEN** the handler evaluates the account
- **THEN** the handler SHALL skip the account
- **AND** SHALL NOT fail the invoke solely for that skip

#### Scenario: Single-valued inbound attribute is read

- **GIVEN** `configuration.inboundEntitlements` is `appRole`
- **AND** the account attribute `appRole` is the string `CN=Admins`
- **WHEN** the handler collects inbound values
- **THEN** the value list SHALL include `CN=Admins`

#### Scenario: Multi-valued inbound attribute drops blanks

- **GIVEN** `configuration.inboundEntitlements` is `groups`
- **AND** the account attribute `groups` is `["CN=A", " ", "CN=B"]`
- **WHEN** the handler collects inbound values
- **THEN** the value list SHALL equal `["CN=A", "CN=B"]` after trim
- **AND** SHALL NOT include blank entries

#### Scenario: Values union across processable accounts

- **GIVEN** one machine identity has two processable underlying accounts with inbound values `CN=A` and `CN=B`
- **WHEN** the handler collects inbound values for that identity
- **THEN** the value list SHALL include both `CN=A` and `CN=B`

### Requirement: Entitlement match and entitlements to add

The operation SHALL match inbound values to ISC entitlements by `value` equality, deduplicate by entitlement id, and compute **entitlements to add** as those matched refs not already on the machine identity `userEntitlements`. Unmatched values SHALL be skipped with a warning and SHALL NOT fail the invoke.

#### Scenario: Value matches catalog entitlement

- **GIVEN** inbound value `CN=Admins` matches an entitlement with id `ent-1` and source id `src-1`
- **AND** that ref is not on the machine identity `userEntitlements`
- **WHEN** the handler computes entitlements to add
- **THEN** the add list SHALL include entitlement id `ent-1` and source id `src-1` at the same index

#### Scenario: Unmatched value is skipped

- **GIVEN** inbound value `no-such-entitlement` matches no ISC entitlement
- **AND** another inbound value matches an entitlement to add
- **WHEN** the handler completes for that machine identity
- **THEN** the handler SHALL persist the matched entitlement
- **AND** SHALL NOT fail the invoke for the unmatched value

#### Scenario: Already assigned entitlement omitted

- **GIVEN** inbound value matches entitlement `ent-1` on source `src-1`
- **AND** the machine identity `userEntitlements` already contains `{ sourceId: src-1, entitlementId: ent-1 }`
- **WHEN** the handler computes entitlements to add
- **THEN** `ent-1` SHALL NOT appear in the persisted entitlement-ids

#### Scenario: Duplicate values collapse

- **GIVEN** two inbound values equal `CN=Admins` that match the same entitlement id
- **WHEN** the handler computes entitlements to add
- **THEN** that entitlement id SHALL appear once in the persisted list

### Requirement: Namespaced persist output for machine identity entitlements

Successful persist for this command SHALL write namespaced attributes `machine-identity-entitlements:machine-identity-id` (STRING), `machine-identity-entitlements:entitlement-ids` (STRING multi), and `machine-identity-entitlements:entitlement-source-ids` (STRING multi) of equal length, plus framework core attributes including `operationName` `custom:machine-identity-entitlements`.

#### Scenario: Output contract is identity and parallel entitlement arrays

- **GIVEN** a machine identity `mi-1` with two entitlements to add
- **WHEN** the handler persists the trigger account
- **THEN** attributes SHALL include `machine-identity-entitlements:machine-identity-id` equal to `mi-1`
- **AND** `machine-identity-entitlements:entitlement-ids` SHALL be a string array of length 2
- **AND** `machine-identity-entitlements:entitlement-source-ids` SHALL be a string array of the same length
- **AND** corresponding indexes SHALL pair entitlement id with that entitlement’s source id

### Requirement: Bundled apply workflow

The repository SHALL ship an ISC workflow export triggered by Account Created on the result source with advanced filter `operationName == custom:machine-identity-entitlements`. The workflow SHALL GET the machine identity, PATCH `userEntitlements` as the union of existing refs and the persisted entitlements to add, and SHALL delete the **trigger account** only when workflow variable Delete Trigger Account is true, after a successful patch.

#### Scenario: Trigger filters on operationName

- **GIVEN** the bundled apply workflow JSON in `workflows/`
- **WHEN** the Account Created trigger is read
- **THEN** the advanced filter SHALL equal `operationName == custom:machine-identity-entitlements`

#### Scenario: Patch unions user entitlements

- **GIVEN** a trigger account with persisted entitlement ids and source ids
- **WHEN** the workflow apply path runs
- **THEN** the workflow SHALL GET the machine identity
- **AND** SHALL PATCH `userEntitlements` to the union of existing refs and the persisted add list
- **AND** SHALL NOT replace `userEntitlements` with only the add list

#### Scenario: Delete trigger account off by default

- **GIVEN** Delete Trigger Account is false or unset
- **WHEN** the workflow finishes a successful patch
- **THEN** the workflow SHALL NOT delete the trigger account

#### Scenario: Delete trigger account after successful patch

- **GIVEN** Delete Trigger Account is true
- **WHEN** the user-entitlements patch succeeds
- **THEN** the workflow SHALL delete the trigger account
- **AND** SHALL NOT delete it before the patch succeeds
