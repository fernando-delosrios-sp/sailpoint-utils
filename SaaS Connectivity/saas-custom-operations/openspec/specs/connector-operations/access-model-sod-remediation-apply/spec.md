# connector-operations/access-model-sod-remediation-apply Specification

## Purpose

Apply a completed access-model SoD remediation form decision to the ISC catalog by detaching nested access profiles from roles or removing direct entitlements, updating access profile definitions when the violated item is an AP, and appending an audit line to the access item description.

## Requirements

### Requirement: Access model SOD remediation apply command registration

The connector SHALL register a custom command `custom:access-model-sod-remediation-apply` that reads a completed access-model SoD remediation form instance and mutates the referenced catalog access item. Implementation SHALL reside under `src/operations/access-model-sod-remediation-apply/` with entry module `index.ts`.

#### Scenario: Command declared for codegen

- **GIVEN** `src/operations/access-model-sod-remediation-apply/index.ts` declares `command: 'custom:access-model-sod-remediation-apply'` on its OperationSignature interface
- **WHEN** codegen runs
- **THEN** `custom:access-model-sod-remediation-apply` SHALL be registered in auto-registry.ts and listed in connector-spec.json commands

### Requirement: Access model SOD remediation apply form instance list and pick

The access-model-sod-remediation-apply operation SHALL load the form instance by listing tenant form instances filtered to `formDefinitionId`, paginating until a row whose `id` equals `formInstanceId` is found or pages are exhausted. The handler SHALL NOT call `getFormInstanceByKeyV1` (or `getFormInstanceById`) on the apply path. When a prior terminal apply persist exists for `{formInstanceId}`, the handler SHALL skip the list. When the instance is not found after the last page, the handler SHALL fail with a validation error and SHALL NOT invoke Roles or Access Profiles PATCH APIs.

#### Scenario: List filtered by form definition id

- **GIVEN** connected invoke with `formInstanceId` `fi-1` and `formDefinitionId` `fd-1`
- **AND** no prior terminal apply persist for `fi-1`
- **WHEN** `custom:access-model-sod-remediation-apply` loads the form instance
- **THEN** the handler SHALL call `searchFormInstancesByTenantV1` with filters equivalent to `formDefinitionId eq "fd-1"`
- **AND** SHALL NOT call `getFormInstanceByKeyV1`

#### Scenario: Instance found on a later page

- **GIVEN** the first list page for `fd-1` does not include instance `fi-1`
- **AND** a later page includes instance `fi-1` with `formInput` and `formData`
- **WHEN** the handler paginates the tenant form instance list
- **THEN** it SHALL continue with offset/limit until `fi-1` is found
- **AND** SHALL parse that row as the form instance

#### Scenario: Missing instance after last page

- **GIVEN** connected invoke with `formInstanceId` `fi-missing` and `formDefinitionId` `fd-1`
- **AND** no listed instance has id `fi-missing`
- **WHEN** pagination completes
- **THEN** the handler SHALL fail with a validation error
- **AND** SHALL NOT invoke Roles or Access Profiles PATCH APIs

#### Scenario: Prior apply skips list

- **GIVEN** a prior terminal apply persist exists for `formInstanceId` `fi-1`
- **WHEN** `custom:access-model-sod-remediation-apply` is invoked with `fi-1` and a `formDefinitionId`
- **THEN** the handler SHALL NOT call `searchFormInstancesByTenantV1`
- **AND** SHALL return `skipped-already-applied` per existing persist idempotency

### Requirement: Access model SOD remediation apply minimal input

The access-model-sod-remediation-apply operation SHALL accept required input fields `formInstanceId` and `formDefinitionId`. The handler SHALL load the form instance from the tenant form instance list and SHALL NOT require workflow pass-through of `formInput` or `formData` fields.

#### Scenario: Workflow invoke binding

- **GIVEN** a workflow Custom Command step after form completion
- **WHEN** the step invokes `custom:access-model-sod-remediation-apply`
- **THEN** input SHALL require `formInstanceId` and `formDefinitionId` bound from the form trigger
- **AND** SHALL NOT require workflow pass-through of `formInput` or `formData` fields

### Requirement: Access model SOD remediation apply form instance validation

The access-model-sod-remediation-apply operation SHALL load the form instance via the Custom Forms tenant list and validate it before catalog mutation.

#### Scenario: Completed form required

- **GIVEN** form instance `fi-1` has state other than `COMPLETED`
- **WHEN** `custom:access-model-sod-remediation-apply` executes with `formInstanceId` `fi-1` and `formDefinitionId` `fd-1`
- **THEN** the handler SHALL fail with a validation error
- **AND** SHALL NOT invoke Roles or Access Profiles PATCH APIs

#### Scenario: Required launch and submit fields

- **GIVEN** a completed form instance with valid `formData.remediationSide` `groupA` or `groupB`
- **WHEN** the handler parses the instance
- **THEN** it SHALL read `formInput.accessItemId`, `formInput.accessItemType`, `formInput.policyId`, `formInput.policyName`, JSON-string `formInput.groupAIds`, and JSON-string `formInput.groupBIds`
- **AND** SHALL read optional `formData.comments`

### Requirement: Access model SOD remediation apply role remediation semantics

When `formInput.accessItemType` is `ROLE`, the access-model-sod-remediation-apply operation SHALL apply the selected side's entitlement ids by detaching nested access profiles from the role or removing direct role entitlements. The operation SHALL NOT patch entitlement lists on nested access profile definitions.

#### Scenario: Direct entitlement removed from role

- **GIVEN** completed form with `accessItemType` `ROLE`, `remediationSide` `groupA`, and `groupAIds` containing direct role entitlement `ent-a`
- **WHEN** `custom:access-model-sod-remediation-apply` applies the correction
- **THEN** the handler SHALL remove `ent-a` from the role entitlement list via role PATCH
- **AND** SHALL NOT patch nested access profile entitlement definitions

#### Scenario: Nested access profile detached from role

- **GIVEN** completed form with `accessItemType` `ROLE`, `remediationSide` `groupB`, and `groupBIds` containing entitlement `ent-c` granted only via nested access profile `ap-x` on the role
- **WHEN** `custom:access-model-sod-remediation-apply` applies the correction
- **THEN** the handler SHALL detach access profile `ap-x` from the role via role PATCH
- **AND** SHALL NOT remove `ent-c` from access profile `ap-x` entitlement list

### Requirement: Access model SOD remediation apply access profile remediation semantics

When `formInput.accessItemType` is `ACCESS_PROFILE`, the access-model-sod-remediation-apply operation SHALL remove selected-side entitlement ids from that access profile's entitlement list.

#### Scenario: Entitlements removed from access profile under review

- **GIVEN** completed form with `accessItemType` `ACCESS_PROFILE`, `accessItemId` `ap-v`, and `remediationSide` `groupA`
- **WHEN** `custom:access-model-sod-remediation-apply` applies the correction
- **THEN** the handler SHALL remove group A entitlement ids from access profile `ap-v` via access profile PATCH

### Requirement: Access model SOD remediation apply description audit

The access-model-sod-remediation-apply operation SHALL append an audit line to the corrected catalog item description documenting the policy, remediation side, detached access profiles, removed entitlements, form instance id, and optional submitter comments.

#### Scenario: Description appended on apply

- **GIVEN** a successful apply that removes or detaches access
- **WHEN** the handler completes catalog PATCH
- **THEN** the access item description SHALL include a new appended line referencing policy name and id
- **AND** SHALL NOT replace the entire prior description

### Requirement: Access model SOD remediation apply idempotent re-invoke

The access-model-sod-remediation-apply operation SHALL treat an already-corrected catalog item as success without error when selected-side entitlements are already absent and nested access profiles to detach are already removed from the role.

#### Scenario: Second invoke skips patch

- **GIVEN** a prior successful apply for form instance `fi-1`
- **WHEN** `custom:access-model-sod-remediation-apply` is invoked again with the same `formInstanceId`
- **THEN** output `access-model-sod-remediation-apply:status` SHALL be `skipped-already-clean`
- **AND** the handler SHALL NOT invoke redundant PATCH requests

### Requirement: Access model SOD remediation apply persist and invoke response

The access-model-sod-remediation-apply operation SHALL persist outputs on result-source identity `{formInstanceId}` and return the same fields on successful `ctx.res.send`.

#### Scenario: Persist on form instance id

- **GIVEN** successful apply for form instance `fi-1` correcting role `role-r`
- **WHEN** the handler completes
- **THEN** it SHALL persist on identity `fi-1` with `access-model-sod-remediation-apply:status` `applied`
- **AND** SHALL include `access-model-sod-remediation-apply:access-item-id` `role-r`
- **AND** optional `access-model-sod-remediation-apply:removed-entitlement-ids` and `access-model-sod-remediation-apply:detached-access-profile-ids` as multi-value string arrays when non-empty

### Requirement: Access model SOD remediation apply offline invoke

The access-model-sod-remediation-apply operation SHALL support offline/testMode invocation with deterministic canned form instances and catalog fixtures suitable for local `call:op` testing without live PATCH calls.

#### Scenario: Offline apply simulates success

- **GIVEN** invoke runs without live ISC credentials (offline or testMode)
- **WHEN** `custom:access-model-sod-remediation-apply` completes for a fixture `formInstanceId` with a non-empty `formDefinitionId`
- **THEN** the handler SHALL use offline fixtures keyed by `formInstanceId`
- **AND** SHALL NOT call `searchFormInstancesByTenantV1`
- **AND** SHALL return `access-model-sod-remediation-apply:status` `applied` or `skipped-already-clean`
- **AND** SHALL persist outputs on `{formInstanceId}` when persist is enabled
