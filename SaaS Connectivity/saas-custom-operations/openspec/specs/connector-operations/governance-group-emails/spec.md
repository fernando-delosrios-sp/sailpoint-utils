# connector-operations/governance-group-emails Specification

## Purpose
TBD - created by archiving change governance-group-emails. Update Purpose after archive.
## Requirements
### Requirement: Governance group emails operation

The connector SHALL register a custom command `custom:governance-group-emails` that resolves a governance group (workgroup) by name and persists member email addresses for downstream workflow use.

#### Scenario: Operation invoked with required input

- **GIVEN** `custom:governance-group-emails` is declared in connector-spec.json and registered
- **WHEN** ISC invokes the command with input containing `groupName` and standard envelope fields (`requestId`, `apiUrl`, `token`)
- **THEN** the handler SHALL look up the workgroup by name, list members, extract non-empty email addresses, and persist namespaced output field `governance-group-emails:emails`

#### Scenario: Output contract is emails array

- **GIVEN** a successful resolution for group `{groupName}`
- **WHEN** the handler completes
- **THEN** operation output persisted via `ctx.persist` SHALL include `governance-group-emails:emails` as a string array
- **AND** each entry SHALL be a non-empty email address
- **AND** output keys SHALL use the `governance-group-emails:` namespace prefix per the namespaced persist output keys requirement

#### Scenario: Missing groupName rejected

- **GIVEN** input omits `groupName` or provides a blank string
- **WHEN** `custom:governance-group-emails` executes
- **THEN** the handler SHALL fail with a ConnectorError describing the missing required input

#### Scenario: Unknown group name rejected

- **GIVEN** no workgroup exists with name `{groupName}`
- **WHEN** `custom:governance-group-emails` executes
- **THEN** the handler SHALL fail with a ConnectorError indicating the group was not found

#### Scenario: Auto-discovery registration

- **GIVEN** `src/operations/governance-group-emails/index.ts` declares `command: 'custom:governance-group-emails'` on its OperationSignature interface
- **WHEN** codegen runs
- **THEN** `custom:governance-group-emails` SHALL be registered in auto-registry.ts and listed in connector-spec.json commands

#### Scenario: Operation README documents contract

- **GIVEN** the auto-discovered operation at `src/operations/governance-group-emails/index.ts`
- **WHEN** a developer reads `src/operations/governance-group-emails/README.md`
- **THEN** the README SHALL document command name, required input `groupName`, output `governance-group-emails:emails`, invoke payload examples, and workflow integration steps

#### Scenario: Offline invoke supported

- **GIVEN** invocation input has no `apiUrl` and no `token` (offline test mode)
- **WHEN** `custom:governance-group-emails` executes with a known offline `groupName`
- **THEN** the handler SHALL return canned member emails without calling ISC APIs
- **AND** SHALL persist the same `governance-group-emails:emails` output shape as connected mode

