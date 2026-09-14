## ADDED Requirements

### Requirement: Apply persist identity term

The glossary SHALL define **apply persist identity** as the result-source account identity holding `custom:access-model-sod-remediation-apply` outputs, `access-model-sod-remediation-apply:{formInstanceId}`. Normative text SHALL use the same term for the identity the prior-apply idempotency check reads. The glossary SHALL define **legacy apply persist identity** as a bare `{formInstanceId}` account written before the prefix was introduced, read-only input to that check.

#### Scenario: Apply persist identity term

- **GIVEN** specs or README describe where access model SoD remediation apply writes its outputs
- **WHEN** normative text names the account identity
- **THEN** it SHALL use **apply persist identity** spelled `access-model-sod-remediation-apply:{formInstanceId}`
- **AND** SHALL NOT describe the persist identity as bare `{formInstanceId}`

#### Scenario: Legacy apply persist identity term

- **GIVEN** specs describe idempotency for form instances applied before the prefix existed
- **WHEN** normative text names the pre-rename account
- **THEN** it SHALL use **legacy apply persist identity**
- **AND** SHALL describe it as read-only fallback input, never written or deleted

### Requirement: Description audit line term

The glossary SHALL define **description audit line** as the single line `custom:access-model-sod-remediation-apply` appends to a corrected role or access profile description, opening with `[access-model-sod-remediation-apply {timestamp}]`.

#### Scenario: Description audit line term

- **GIVEN** specs or README describe the text appended to a corrected catalog item description
- **WHEN** normative text names that text
- **THEN** it SHALL use **description audit line**
- **AND** the label SHALL name the writing command
- **AND** SHALL NOT use the label `SOD remediation`, which does not distinguish apply from `custom:sod-remediation`

---

## MODIFIED Requirements

### Requirement: Access model SoD remediation apply term

The glossary SHALL define **access model SoD remediation apply** as the custom operation `custom:access-model-sod-remediation-apply` that applies a completed access-model SoD remediation form decision to the ISC catalog access item under review.

#### Scenario: Preferred command spelling

- **GIVEN** specs or README describe applying a completed access-model SoD remediation form
- **WHEN** normative text names the apply operation
- **THEN** the preferred command SHALL be `custom:access-model-sod-remediation-apply`
- **AND** persist output keys SHALL use prefix `access-model-sod-remediation-apply:`

#### Scenario: Distinct from identity sod remediation

- **GIVEN** documentation lists SoD remediation operations
- **WHEN** access model catalog apply is described
- **THEN** it SHALL distinguish **access model SoD remediation apply** from `custom:sod-remediation` identity violation response
- **AND** the **description audit line** label SHALL name the apply command so catalog descriptions do not read as `custom:sod-remediation` output

#### Scenario: Apply inputs

- **GIVEN** specs describe invoke input for access model SoD remediation apply
- **WHEN** normative text names required fields
- **THEN** it SHALL require `formInstanceId` and **form name** (`formName`)
- **AND** SHALL note the **apply persist identity** is `access-model-sod-remediation-apply:{formInstanceId}`
- **AND** SHALL NOT require `formDefinitionId` as invoke input

---

## Term entries

### Term: Apply persist identity
**Context**: connector-operations / access-model-sod-remediation-apply
**Definition**: The result-source account identity holding `custom:access-model-sod-remediation-apply` outputs: `access-model-sod-remediation-apply:{formInstanceId}`.
**Aliases**: bare `{formInstanceId}` identity (superseded)
**Notes**: Derived from `formInstanceId` in code, not from invoke `requestId`, so retries with different request ids stay deduped. Same identity the prior-apply check reads and the replay path writes.

### Term: Legacy apply persist identity
**Context**: connector-operations / access-model-sod-remediation-apply
**Definition**: A bare `{formInstanceId}` result-source account written by apply before the **apply persist identity** prefix was introduced.
**Aliases**: none
**Notes**: Read-only fallback for the prior-apply idempotency check. Never written, updated, or deleted; superseded when the replay path persists under the prefixed identity.

### Term: Description audit line
**Context**: connector-operations / access-model-sod-remediation-apply / target-client/roles / target-client/access-profiles
**Definition**: The single line appended to a corrected role or access profile description by apply, opening with `[access-model-sod-remediation-apply {timestamp}]`.
**Aliases**: `[SOD remediation {timestamp}]` label (deprecated)
**Notes**: Body carries policy name and id, remediation side, detached access profiles, removed entitlements, form instance id, and optional submitter and comments. Appended, never replacing prior description text, and persisted as `access-model-sod-remediation-apply:description-appended`.

### Term: Access model SoD remediation apply
**Context**: connector-operations / access-model-sod-remediation-apply
**Definition**: The custom operation that reads a completed access-model SoD remediation form instance and mutates the referenced role or access profile in the ISC catalog per `remediationSide`.
**Aliases**: none
**Notes**: Required inputs are `formInstanceId` and `formName`; the **apply persist identity** is `access-model-sod-remediation-apply:{formInstanceId}`, with a read-only fallback to the **legacy apply persist identity**.
