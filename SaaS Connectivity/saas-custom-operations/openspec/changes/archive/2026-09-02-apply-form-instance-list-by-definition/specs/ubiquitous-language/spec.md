## ADDED Requirements

### Requirement: Form definition id vocabulary

The glossary SHALL define **form definition id** as the ISC Custom Forms identifier of the form definition that spawned a form instance (`formDefinitionId`). For `custom:access-model-sod-remediation-apply`, it is a required input used to filter the tenant form instance list.

#### Scenario: Form definition id term

- **GIVEN** specs describe listing form instances for apply
- **WHEN** normative text names the list filter
- **THEN** it SHALL use **form definition id**
- **AND** SHALL map it to the input field `formDefinitionId`
- **AND** SHALL NOT use `formId` as the preferred spelling

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

#### Scenario: Apply inputs

- **GIVEN** specs describe invoke input for access model SoD remediation apply
- **WHEN** normative text names required fields
- **THEN** it SHALL require `formInstanceId` and **form definition id** (`formDefinitionId`)
- **AND** SHALL note persist identity remains `{formInstanceId}`

---

## Term entries

### Term: Form definition id
**Context**: connector-operations / access-model-sod-remediation-apply
**Definition**: The ISC Custom Forms identifier of the form definition that spawned a form instance (`formDefinitionId`).
**Aliases**: formId (rejected shorthand)
**Notes**: Required apply input; only supported filter on the tenant form instance list. Distinct from `formInstanceId`.

### Term: Access model SoD remediation apply
**Context**: connector-operations / access-model-sod-remediation-apply
**Definition**: The custom operation that reads a completed access-model SoD remediation form instance and mutates the referenced role or access profile in the ISC catalog per `remediationSide`.
**Aliases**: none
**Notes**: Required inputs are `formInstanceId` and `formDefinitionId`; persist identity is `{formInstanceId}`.
