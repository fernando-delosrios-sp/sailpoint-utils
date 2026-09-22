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

### Requirement: Access model SOD remediation apply form definition lookup by name

The access-model-sod-remediation-apply operation SHALL resolve required input `formName` to a form definition id by searching existing tenant form definitions. The handler SHALL NOT call `ensureFormDefinitionByName` and SHALL NOT create or patch a form definition. When no definition matches `formName`, the handler SHALL fail with a validation error and SHALL NOT list form instances or invoke Roles or Access Profiles PATCH APIs.

#### Scenario: Name resolves to definition id then list

- **GIVEN** connected invoke with `formInstanceId` `fi-1` and `formName` `Access Model SOD Remediation`
- **AND** no prior terminal apply persist for `fi-1`
- **AND** form definition search returns id `fd-1` for that name
- **WHEN** `custom:access-model-sod-remediation-apply` loads the form instance
- **THEN** the handler SHALL call `searchFormDefinitionsByTenantV1` with filters equivalent to `name eq "Access Model SOD Remediation"`
- **AND** SHALL call `searchFormInstancesByTenantV1` with filters equivalent to `formDefinitionId eq "fd-1"`
- **AND** SHALL NOT call `ensureFormDefinitionByName`
- **AND** SHALL NOT call `getFormInstanceByKeyV1`

#### Scenario: Missing form definition by name

- **GIVEN** connected invoke with `formInstanceId` `fi-1` and `formName` `Unknown Form`
- **AND** no prior terminal apply persist for `fi-1`
- **AND** form definition search returns no matching definition
- **WHEN** `custom:access-model-sod-remediation-apply` loads the form instance
- **THEN** the handler SHALL fail with a validation error naming `formName`
- **AND** SHALL NOT call `searchFormInstancesByTenantV1`
- **AND** SHALL NOT invoke Roles or Access Profiles PATCH APIs

### Requirement: Access model SOD remediation apply form instance list and pick

The access-model-sod-remediation-apply operation SHALL load the form instance by resolving `formName` to a **form definition id**, then listing tenant form instances filtered to that id, paginating until a row whose `id` equals `formInstanceId` is found or pages are exhausted. The handler SHALL NOT call `getFormInstanceByKeyV1` (or `getFormInstanceById`) on the apply path. When a prior terminal apply persist exists for `{formInstanceId}`, the handler SHALL skip definition lookup and the instance list. When the instance is not found after the last page, the handler SHALL fail with a validation error and SHALL NOT invoke Roles or Access Profiles PATCH APIs.

#### Scenario: List filtered by form definition id

- **GIVEN** connected invoke with `formInstanceId` `fi-1` and `formName` that resolves to `fd-1`
- **AND** no prior terminal apply persist for `fi-1`
- **WHEN** `custom:access-model-sod-remediation-apply` loads the form instance
- **THEN** the handler SHALL call `searchFormInstancesByTenantV1` with filters equivalent to `formDefinitionId eq "fd-1"`
- **AND** SHALL NOT call `getFormInstanceByKeyV1`

#### Scenario: Instance found on a later page

- **GIVEN** the first list page for resolved definition `fd-1` does not include instance `fi-1`
- **AND** a later page includes instance `fi-1` with `formInput` and `formData`
- **WHEN** the handler paginates the tenant form instance list
- **THEN** it SHALL continue with offset/limit until `fi-1` is found
- **AND** SHALL parse that row as the form instance

#### Scenario: Missing instance after last page

- **GIVEN** connected invoke with `formInstanceId` `fi-missing` and `formName` that resolves to `fd-1`
- **AND** no listed instance has id `fi-missing`
- **WHEN** pagination completes
- **THEN** the handler SHALL fail with a validation error
- **AND** SHALL NOT invoke Roles or Access Profiles PATCH APIs

#### Scenario: Prior apply skips list

- **GIVEN** a prior terminal apply persist exists for `formInstanceId` `fi-1`
- **WHEN** `custom:access-model-sod-remediation-apply` is invoked with `fi-1` and a `formName`
- **THEN** the handler SHALL NOT call `searchFormDefinitionsByTenantV1`
- **AND** SHALL NOT call `searchFormInstancesByTenantV1`
- **AND** SHALL return `skipped-already-applied` per existing persist idempotency

### Requirement: Access model SOD remediation apply minimal input

The access-model-sod-remediation-apply operation SHALL accept required input fields `formInstanceId` and `formName`. The handler SHALL load the form instance from the tenant form instance list after resolving `formName` and SHALL NOT require workflow pass-through of `formInput` or `formData` fields. The handler SHALL NOT accept `formDefinitionId` as an invoke input.

#### Scenario: Workflow invoke binding

- **GIVEN** a workflow Custom Command step after form completion
- **WHEN** the step invokes `custom:access-model-sod-remediation-apply`
- **THEN** input SHALL require `formInstanceId` from the form trigger
- **AND** SHALL require `formName` matching the scan operation's form definition name
- **AND** SHALL NOT require `formDefinitionId`
- **AND** SHALL NOT require workflow pass-through of `formInput` or `formData` fields

#### Scenario: Missing formName validation

- **GIVEN** invoke omits `formName` or supplies only whitespace
- **WHEN** `custom:access-model-sod-remediation-apply` executes
- **THEN** the handler SHALL fail with a validation error naming `formName`
- **AND** SHALL NOT call Custom Forms search APIs
- **AND** SHALL NOT invoke Roles or Access Profiles PATCH APIs

### Requirement: Access model SOD remediation apply form instance validation

The access-model-sod-remediation-apply operation SHALL load the form instance via the Custom Forms tenant list and validate it before catalog mutation.

#### Scenario: Completed form required

- **GIVEN** form instance `fi-1` has state other than `COMPLETED`
- **WHEN** `custom:access-model-sod-remediation-apply` executes with `formInstanceId` `fi-1` and a resolvable `formName`
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

The access-model-sod-remediation-apply operation SHALL append an audit line to the corrected catalog item description documenting the writing command, policy, remediation side, detached access profiles, removed entitlements, form instance id, and optional submitter comments. The audit line SHALL open with `[access-model-sod-remediation-apply {timestamp}]`, where `{timestamp}` is the ISO-8601 apply time. The label SHALL name the writing command and SHALL NOT use `SOD remediation`, which does not distinguish apply from `custom:sod-remediation`.

#### Scenario: Description appended on apply

- **GIVEN** a successful apply that removes or detaches access
- **WHEN** the handler completes catalog PATCH
- **THEN** the access item description SHALL include a new appended line referencing policy name and id
- **AND** SHALL NOT replace the entire prior description

#### Scenario: Audit line label names the writing command

- **GIVEN** a successful apply for form instance `fi-1` at ISO-8601 time `{timestamp}`
- **WHEN** the handler builds the description audit line
- **THEN** the line SHALL start with `[access-model-sod-remediation-apply {timestamp}]`
- **AND** SHALL NOT start with `[SOD remediation`
- **AND** the remainder SHALL still carry policy name and id, remediation side, detached access profiles, removed entitlements, form instance id, and optional submitter and comments

#### Scenario: Persisted audit attribute carries the same line

- **GIVEN** a successful apply that appends a description audit line
- **WHEN** the handler persists outputs
- **THEN** `access-model-sod-remediation-apply:description-appended` SHALL equal the appended line including its command label

### Requirement: Access model SOD remediation apply idempotent re-invoke

The access-model-sod-remediation-apply operation SHALL treat an already-corrected catalog item as success without error when selected-side entitlements are already absent and nested access profiles to detach are already removed from the role.

#### Scenario: Second invoke skips patch

- **GIVEN** a prior successful apply for form instance `fi-1`
- **WHEN** `custom:access-model-sod-remediation-apply` is invoked again with the same `formInstanceId`
- **THEN** output `access-model-sod-remediation-apply:status` SHALL be `skipped-already-clean`
- **AND** the handler SHALL NOT invoke redundant PATCH requests

### Requirement: Access model SOD remediation apply persist and invoke response

The access-model-sod-remediation-apply operation SHALL persist outputs on result-source identity `{requestId}:{formInstanceId}` and return the same fields on successful `ctx.res.send`. The bundled Access Model SOD - Remediation workflow SHALL set `requestId` to `access-model-sod-remediation-apply`. The replay path for a prior terminal apply SHALL persist on the same `{requestId}:{formInstanceId}` identity.

#### Scenario: Persist on request id colon form instance id

- **GIVEN** successful apply for form instance `fi-1` correcting role `role-r`
- **AND** invoke `requestId` `access-model-sod-remediation-apply`
- **WHEN** the handler completes
- **THEN** it SHALL persist on identity `access-model-sod-remediation-apply:fi-1` with `access-model-sod-remediation-apply:status` `applied`
- **AND** SHALL include `access-model-sod-remediation-apply:access-item-id` `role-r`
- **AND** optional `access-model-sod-remediation-apply:removed-entitlement-ids` and `access-model-sod-remediation-apply:detached-access-profile-ids` as multi-value string arrays when non-empty
- **AND** SHALL NOT persist on the bare identity `fi-1`

#### Scenario: Persist identity uses the invoke request id

- **GIVEN** an invoke with `formInstanceId` `fi-1` and `requestId` `access-model-sod-remediation-apply-fi-1`
- **WHEN** the handler persists outputs
- **THEN** the persist identity SHALL be `access-model-sod-remediation-apply-fi-1:fi-1`

#### Scenario: Replay persists on request id colon form instance id

- **GIVEN** a prior terminal apply is found for form instance `fi-1`
- **AND** invoke `requestId` `access-model-sod-remediation-apply`
- **WHEN** the handler replays the prior outputs
- **THEN** it SHALL persist `access-model-sod-remediation-apply:status` `skipped-already-applied` on identity `access-model-sod-remediation-apply:fi-1`

#### Scenario: Bundled workflow request id names the operation

- **GIVEN** the shipped `Access Model SOD - Remediation.json`
- **WHEN** its invoke `requestId` is read
- **THEN** it SHALL be `access-model-sod-remediation-apply`
- **AND** SHALL NOT embed `formInstanceId` in `requestId`

### Requirement: Access model SOD remediation apply prior apply identity fallback

The access-model-sod-remediation-apply operation SHALL read a prior terminal apply from the result-source account at `{requestId}:{formInstanceId}` and, only when no such account exists, SHALL fall back to `access-model-sod-remediation-apply:{formInstanceId}` when that identity differs, then to the legacy account at bare `{formInstanceId}`. All lookups SHALL apply identical terminal-status and required-field validation. The handler SHALL NOT update, delete, or otherwise mutate the legacy account.

#### Scenario: Prefixed account short-circuits the apply path

- **GIVEN** an account at `access-model-sod-remediation-apply:fi-1` with `access-model-sod-remediation-apply:status` `applied`
- **WHEN** `custom:access-model-sod-remediation-apply` is invoked with `formInstanceId` `fi-1`, `requestId` `access-model-sod-remediation-apply`, and a `formName`
- **THEN** output `access-model-sod-remediation-apply:status` SHALL be `skipped-already-applied`
- **AND** the handler SHALL NOT look up the legacy identity `fi-1`
- **AND** SHALL NOT invoke Roles or Access Profiles PATCH APIs

#### Scenario: Legacy account keeps a pre-rename apply deduped

- **GIVEN** no account at `access-model-sod-remediation-apply:fi-1`
- **AND** a legacy account at `fi-1` with `access-model-sod-remediation-apply:status` `applied`
- **WHEN** `custom:access-model-sod-remediation-apply` is invoked with `formInstanceId` `fi-1` and a `formName`
- **THEN** output `access-model-sod-remediation-apply:status` SHALL be `skipped-already-applied`
- **AND** SHALL NOT invoke Roles or Access Profiles PATCH APIs
- **AND** SHALL NOT append a second description audit line
- **AND** SHALL persist the replayed outputs on `access-model-sod-remediation-apply:fi-1`
- **AND** SHALL leave the legacy account at `fi-1` unchanged

#### Scenario: Prefixed account wins when both exist

- **GIVEN** accounts at both `access-model-sod-remediation-apply:fi-1` and `fi-1` with terminal apply status
- **WHEN** the handler reads prior apply outputs
- **THEN** it SHALL return the outputs read from `access-model-sod-remediation-apply:fi-1`
- **AND** SHALL ignore the legacy account without error

#### Scenario: Non-terminal legacy account is not a prior apply

- **GIVEN** no account at `access-model-sod-remediation-apply:fi-1`
- **AND** a legacy account at `fi-1` whose `access-model-sod-remediation-apply:status` is neither `applied` nor `skipped-already-applied`
- **WHEN** the handler reads prior apply outputs
- **THEN** it SHALL treat the form instance as not yet applied
- **AND** SHALL continue to form definition lookup and form instance list

#### Scenario: No account under either identity

- **GIVEN** no account at `access-model-sod-remediation-apply:fi-1` and none at `fi-1`
- **WHEN** `custom:access-model-sod-remediation-apply` is invoked with `formInstanceId` `fi-1` and a resolvable `formName`
- **THEN** the handler SHALL resolve the form definition, list instances, and apply the correction as normal

### Requirement: Access model SOD remediation apply offline invoke

The access-model-sod-remediation-apply operation SHALL support offline/testMode invocation with deterministic canned form instances and catalog fixtures suitable for local `call:op` testing without live PATCH calls.

#### Scenario: Offline apply simulates success

- **GIVEN** invoke runs without live ISC credentials (offline or testMode)
- **WHEN** `custom:access-model-sod-remediation-apply` completes for a fixture `formInstanceId` with a non-empty `formName`
- **THEN** the handler SHALL use offline fixtures keyed by `formInstanceId`
- **AND** SHALL NOT call `searchFormDefinitionsByTenantV1`
- **AND** SHALL NOT call `searchFormInstancesByTenantV1`
- **AND** SHALL return `access-model-sod-remediation-apply:status` `applied` or `skipped-already-clean`
- **AND** SHALL persist outputs on `{requestId}:{formInstanceId}` when persist is enabled
