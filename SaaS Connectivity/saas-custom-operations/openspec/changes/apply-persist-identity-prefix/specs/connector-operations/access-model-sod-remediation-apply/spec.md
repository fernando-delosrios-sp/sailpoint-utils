## ADDED Requirements

### Requirement: Access model SOD remediation apply prior apply identity fallback

The access-model-sod-remediation-apply operation SHALL read a prior terminal apply from the result-source account at `access-model-sod-remediation-apply:{formInstanceId}` and, only when no such account exists, SHALL fall back to the legacy account at bare `{formInstanceId}`. Both lookups SHALL apply identical terminal-status and required-field validation. The handler SHALL NOT update, delete, or otherwise mutate the legacy account.

#### Scenario: Prefixed account short-circuits the apply path

- **GIVEN** an account at `access-model-sod-remediation-apply:fi-1` with `access-model-sod-remediation-apply:status` `applied`
- **WHEN** `custom:access-model-sod-remediation-apply` is invoked with `formInstanceId` `fi-1` and a `formName`
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

---

## MODIFIED Requirements

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

### Requirement: Access model SOD remediation apply persist and invoke response

The access-model-sod-remediation-apply operation SHALL persist outputs on result-source identity `access-model-sod-remediation-apply:{formInstanceId}` and return the same fields on successful `ctx.res.send`. The handler SHALL derive that identity from `formInstanceId` in code and SHALL NOT use the invoke `requestId` as the persist identity. The replay path for a prior terminal apply SHALL persist on the same identity.

#### Scenario: Persist on form instance id

- **GIVEN** successful apply for form instance `fi-1` correcting role `role-r`
- **WHEN** the handler completes
- **THEN** it SHALL persist on identity `access-model-sod-remediation-apply:fi-1` with `access-model-sod-remediation-apply:status` `applied`
- **AND** SHALL include `access-model-sod-remediation-apply:access-item-id` `role-r`
- **AND** optional `access-model-sod-remediation-apply:removed-entitlement-ids` and `access-model-sod-remediation-apply:detached-access-profile-ids` as multi-value string arrays when non-empty
- **AND** SHALL NOT persist on the bare identity `fi-1`

#### Scenario: Persist identity ignores invoke requestId

- **GIVEN** an invoke with `formInstanceId` `fi-1` and `requestId` `access-model-sod-remediation-apply-fi-1`
- **WHEN** the handler persists outputs
- **THEN** the persist identity SHALL be `access-model-sod-remediation-apply:fi-1`

#### Scenario: Replay persists on prefixed identity

- **GIVEN** a prior terminal apply is found for form instance `fi-1`
- **WHEN** the handler replays the prior outputs
- **THEN** it SHALL persist `access-model-sod-remediation-apply:status` `skipped-already-applied` on identity `access-model-sod-remediation-apply:fi-1`

### Requirement: Access model SOD remediation apply offline invoke

The access-model-sod-remediation-apply operation SHALL support offline/testMode invocation with deterministic canned form instances and catalog fixtures suitable for local `call:op` testing without live PATCH calls.

#### Scenario: Offline apply simulates success

- **GIVEN** invoke runs without live ISC credentials (offline or testMode)
- **WHEN** `custom:access-model-sod-remediation-apply` completes for a fixture `formInstanceId` with a non-empty `formName`
- **THEN** the handler SHALL use offline fixtures keyed by `formInstanceId`
- **AND** SHALL NOT call `searchFormDefinitionsByTenantV1`
- **AND** SHALL NOT call `searchFormInstancesByTenantV1`
- **AND** SHALL return `access-model-sod-remediation-apply:status` `applied` or `skipped-already-clean`
- **AND** SHALL persist outputs on `access-model-sod-remediation-apply:{formInstanceId}` when persist is enabled
