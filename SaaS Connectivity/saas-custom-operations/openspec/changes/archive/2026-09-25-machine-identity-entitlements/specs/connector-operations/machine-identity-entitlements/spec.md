# connector-operations/machine-identity-entitlements Delta

## ADDED Requirements

### Requirement: Machine identity entitlements operation

The connector SHALL register one custom command `custom:machine-identity-entitlements` that lists machine accounts, follows each account's `machineIdentity` node, reads configured connector entitlement values, matches ISC entitlements, PATCHes each machine identity's `userEntitlements` union, and persists one **scan summary account** per invoke.

#### Scenario: Auto-discovery registration

-   **GIVEN** `src/operations/machine-identity-entitlements/index.ts` declares `command: 'custom:machine-identity-entitlements'` on its OperationSignature interface
-   **WHEN** codegen runs
-   **THEN** `custom:machine-identity-entitlements` SHALL be registered in auto-registry.ts and listed in connector-spec.json commands

#### Scenario: Full scan patches every identity with work

-   **GIVEN** two machine identities each have at least one entitlement to add
-   **AND** invoke input omits `identityId`
-   **WHEN** `custom:machine-identity-entitlements` executes
-   **THEN** the handler SHALL PATCH each identity with the union of its existing and matched entitlement refs
-   **AND** SHALL persist exactly one scan summary account keyed by `requestId`

#### Scenario: Empty delta skips patch

-   **GIVEN** a machine identity whose matched entitlements are already on `userEntitlements`
-   **WHEN** the handler evaluates that identity
-   **THEN** the handler SHALL NOT call the machine identity update API for that identity
-   **AND** SHALL increment the summary skipped count

#### Scenario: Tenant scan with no work succeeds

-   **GIVEN** a connected invoke with no `identityId`
-   **AND** no machine identity has entitlements to add
-   **WHEN** the command completes
-   **THEN** the handler SHALL succeed
-   **AND** SHALL persist one zero-update scan summary account with status `success`

#### Scenario: Targeted unknown identity rejected

-   **GIVEN** invoke input `identityId` does not match a machine identity `id` or `cisIdentityId`
-   **WHEN** `custom:machine-identity-entitlements` executes
-   **THEN** the handler SHALL fail with a ConnectorError indicating the machine identity was not found

#### Scenario: Optional identityId limits the scan

-   **GIVEN** invoke input `identityId` matches one machine identity
-   **WHEN** the command executes
-   **THEN** the handler SHALL process only machine accounts whose `machineIdentity.id` equals that machine identity id

#### Scenario: Operation README documents contract

-   **GIVEN** the auto-discovered operation at `src/operations/machine-identity-entitlements/index.ts`
-   **WHEN** a developer reads `src/operations/machine-identity-entitlements/README.md`
-   **THEN** the README SHALL document the command name, optional `identityId`, direct PATCH behavior, summary account, partial-failure behavior, wrapper workflow, and token scopes

#### Scenario: Offline invoke supported

-   **GIVEN** invocation input has no `apiUrl` and no `token` (offline test mode)
-   **WHEN** `custom:machine-identity-entitlements` executes
-   **THEN** the handler SHALL use canned machine identities, machine accounts, sources, and entitlements without calling ISC APIs
-   **AND** SHALL exercise one inhibited scan-summary persist

### Requirement: Source-configured machine-account entitlement attribute

The operation SHALL process a machine account only when its source `connectorAttributes.userEntitlements` is a non-blank connector attribute name. It SHALL read values from that key in the machine account's `connectorAttributes`. Missing or blank source configuration, or an absent machine-account connector attribute, SHALL skip that account and SHALL NOT fail the invoke.

#### Scenario: Source without connectorAttributes.userEntitlements is skipped

-   **GIVEN** a machine account whose source has no `connectorAttributes.userEntitlements`
-   **WHEN** the handler evaluates the owning machine identity
-   **THEN** the handler SHALL NOT read entitlement values from that account
-   **AND** SHALL NOT fail the invoke solely for that skip

#### Scenario: Single-valued inbound attribute is read

-   **GIVEN** source `connectorAttributes.userEntitlements` is `appRole`
-   **AND** machine account `connectorAttributes.appRole` is the string `CN=Admins`
-   **WHEN** the handler collects inbound values
-   **THEN** the value list SHALL include `CN=Admins`

#### Scenario: Multi-valued inbound attribute drops blanks

-   **GIVEN** source `connectorAttributes.userEntitlements` is `groups`
-   **AND** machine account `connectorAttributes.groups` is `["CN=A", " ", "CN=B"]`
-   **WHEN** the handler collects inbound values
-   **THEN** the value list SHALL equal `["CN=A", "CN=B"]` after trim
-   **AND** SHALL NOT include blank entries

#### Scenario: Values union across linked machine accounts

-   **GIVEN** two machine accounts have `machineIdentity.id` `mi-1` and configured values `CN=A` and `CN=B`
-   **WHEN** the handler collects inbound values for that identity
-   **THEN** the value list SHALL include both `CN=A` and `CN=B`

### Requirement: Entitlement match and entitlements to add

The operation SHALL match inbound values to ISC entitlements by `value` equality **across every source**, deduplicate by entitlement id, and compute **entitlements to add** as those matched refs not already on the machine identity `userEntitlements`. Unmatched values SHALL be skipped with a warning and SHALL NOT fail the invoke.

#### Scenario: Value matches catalog entitlement

-   **GIVEN** inbound value `CN=Admins` matches an entitlement with id `ent-1` and source id `src-1`
-   **AND** that ref is not on the machine identity `userEntitlements`
-   **WHEN** the handler computes entitlements to add
-   **THEN** the add list SHALL include entitlement id `ent-1` and source id `src-1` at the same index

#### Scenario: Unmatched value is skipped

-   **GIVEN** inbound value `no-such-entitlement` matches no ISC entitlement
-   **AND** another inbound value matches an entitlement to add
-   **WHEN** the handler completes for that machine identity
-   **THEN** the handler SHALL PATCH the matched entitlement as part of the union
-   **AND** SHALL NOT fail the invoke for the unmatched value

#### Scenario: Entitlement value matches across every source that carries it

-   **GIVEN** one value identifies entitlements on a Users source and an NHI source
-   **AND** the machine account belongs to the NHI source
-   **WHEN** the handler computes entitlements to add
-   **THEN** both the Users source and NHI source entitlements SHALL be included, each paired with its own source id

#### Scenario: Already assigned entitlement omitted

-   **GIVEN** inbound value matches entitlement `ent-1` on source `src-1`
-   **AND** the machine identity `userEntitlements` already contains `{ sourceId: src-1, entitlementId: ent-1 }`
-   **WHEN** the handler computes entitlements to add
-   **THEN** `ent-1` SHALL NOT count as an added entitlement
-   **AND** SHALL remain present in the PATCH union when another ref is added

#### Scenario: Duplicate values collapse

-   **GIVEN** two inbound values equal `CN=Admins` that match the same entitlement id
-   **WHEN** the handler computes entitlements to add
-   **THEN** that entitlement id SHALL appear once in the PATCH union

### Requirement: Direct union patch

For each machine identity with entitlements to add, the operation SHALL re-read current `userEntitlements`, union existing and matched refs by `{sourceId, entitlementId}`, and PATCH the complete union. It SHALL preserve existing refs and skip the update API when the delta is empty.

#### Scenario: Existing refs are preserved

-   **GIVEN** a machine identity currently holds `{ sourceId: src-1, entitlementId: ent-a }`
-   **AND** matching finds `{ sourceId: src-3, entitlementId: ent-c }`
-   **WHEN** the operation applies the identity
-   **THEN** the patched `userEntitlements` SHALL contain both refs

#### Scenario: Current refs are re-read before patch

-   **GIVEN** the scan snapshot did not contain a ref added concurrently
-   **WHEN** the operation prepares the PATCH
-   **THEN** it SHALL GET the current machine identity
-   **AND** SHALL include the concurrently added ref in the union

#### Scenario: Patches use bounded concurrency

-   **GIVEN** more identities need updates than the configured patch-concurrency limit
-   **WHEN** the operation applies them
-   **THEN** simultaneous PATCH attempts SHALL NOT exceed that limit
-   **AND** more than one PATCH MAY run concurrently

### Requirement: Continue and summarize patch failures

An identity PATCH failure SHALL NOT prevent remaining identities from being attempted. The operation SHALL collect the failed identity id and error detail. Mixed success/failure SHALL return operation success with summary status `partial`. If every attempted PATCH fails, the operation SHALL persist the failed summary before returning operation failure.

#### Scenario: Mixed patch outcomes are partial success

-   **GIVEN** three identities need updates
-   **AND** two PATCHes succeed and one PATCH fails
-   **WHEN** the operation completes
-   **THEN** all three identities SHALL have been attempted
-   **AND** the summary account status SHALL be `partial`
-   **AND** the invoke SHALL report success
-   **AND** the failed identity id and error detail SHALL be recorded

#### Scenario: Every attempted patch fails

-   **GIVEN** two identities need updates
-   **AND** both PATCHes fail
-   **WHEN** the operation completes
-   **THEN** the summary account status SHALL be `failed`
-   **AND** the failed summary SHALL be persisted before the invoke reports failure

### Requirement: One scan summary account

Every completed evaluation SHALL persist exactly one result-source account whose native identity is `requestId`. It SHALL contain namespaced INT counts for identities scanned, updated, skipped, and failed and entitlements added, plus aligned STRING multi fields for failed identity ids and failure details. Framework core `status` SHALL be `success`, `partial`, or `failed`, and `operationName` SHALL be `custom:machine-identity-entitlements`.

#### Scenario: Successful scan summary

-   **GIVEN** a scan updates two identities and skips one
-   **WHEN** all identity attempts finish
-   **THEN** one account keyed by `requestId` SHALL be persisted
-   **AND** its namespaced counts SHALL record two updated, one skipped, zero failed, and the number of refs added
-   **AND** its status SHALL be `success`

#### Scenario: Summary response mirrors persisted counts

-   **GIVEN** the summary account has been persisted
-   **WHEN** the operation responds
-   **THEN** `OperationSignature.response` SHALL include the same scanned, updated, skipped, failed, and entitlements-added counts
-   **AND** the response id list SHALL contain only `requestId`

### Requirement: Interactive Scan workflow is presentation-only

The repository SHALL ship the interactive Scan workflow that invokes only `custom:machine-identity-entitlements` and presents no-work, successful-update, partial, and failed outcomes from its response summary. The repository SHALL NOT register `custom:machine-identity-entitlements-apply` or ship an Account Created Apply workflow for this capability.

#### Scenario: Scan wrapper reports a partial run

-   **GIVEN** the operation response reports one or more failed identities and at least one updated identity
-   **WHEN** the Scan workflow evaluates the invoke body
-   **THEN** it SHALL show a partial-completion warning with updated and failed counts

#### Scenario: Standalone apply path is absent

-   **GIVEN** schema codegen and workflow contract tests run
-   **WHEN** generated commands and workflow exports are inspected
-   **THEN** `custom:machine-identity-entitlements-apply` SHALL NOT be registered
-   **AND** `Machine Identity Entitlements - Apply.json` SHALL NOT exist
