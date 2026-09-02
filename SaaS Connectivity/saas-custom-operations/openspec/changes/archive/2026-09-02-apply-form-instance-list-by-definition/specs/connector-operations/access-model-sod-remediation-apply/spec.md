## ADDED Requirements

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

---

## MODIFIED Requirements

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

### Requirement: Access model SOD remediation apply offline invoke

The access-model-sod-remediation-apply operation SHALL support offline/testMode invocation with deterministic canned form instances and catalog fixtures suitable for local `call:op` testing without live PATCH calls.

#### Scenario: Offline apply simulates success

- **GIVEN** invoke runs without live ISC credentials (offline or testMode)
- **WHEN** `custom:access-model-sod-remediation-apply` completes for a fixture `formInstanceId` with a non-empty `formDefinitionId`
- **THEN** the handler SHALL use offline fixtures keyed by `formInstanceId`
- **AND** SHALL NOT call `searchFormInstancesByTenantV1`
- **AND** SHALL return `access-model-sod-remediation-apply:status` `applied` or `skipped-already-clean`
- **AND** SHALL persist outputs on `{formInstanceId}` when persist is enabled
