## ADDED Requirements

### Requirement: Form name vocabulary

The glossary SHALL define **form name** as the tenant-visible Custom Forms definition name (`formName`) shared by `custom:access-model-sod-remediation` (ensure-from-seed) and `custom:access-model-sod-remediation-apply` (lookup). The same string selects the same form definition.

#### Scenario: Form name term

- **GIVEN** specs describe apply or scan identifying the shared remediation form definition
- **WHEN** normative text names the operator-facing field
- **THEN** it SHALL use **form name**
- **AND** SHALL map it to the input field `formName`
- **AND** SHALL NOT treat `formDefinitionId` as the apply invoke field

---

## MODIFIED Requirements

### Requirement: Form definition id vocabulary

The glossary SHALL define **form definition id** as the ISC Custom Forms identifier of the form definition that spawned a form instance (`formDefinitionId`). It is the only supported filter on the tenant form instance list. For `custom:access-model-sod-remediation-apply`, the handler SHALL obtain it by looking up **form name**; it SHALL NOT be a required apply invoke input.

#### Scenario: Form definition id term

- **GIVEN** specs describe listing form instances for apply
- **WHEN** normative text names the list filter
- **THEN** it SHALL use **form definition id**
- **AND** SHALL describe it as the resolved list filter, not the apply invoke field
- **AND** SHALL NOT use `formId` as the preferred spelling

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
- **THEN** it SHALL require `formInstanceId` and **form name** (`formName`)
- **AND** SHALL note persist identity remains `{formInstanceId}`
- **AND** SHALL NOT require `formDefinitionId` as invoke input

---

## Term entries

### Term: Form name
**Context**: connector-operations / access-model-sod-remediation / access-model-sod-remediation-apply
**Definition**: The tenant-visible Custom Forms definition name (`formName`) that identifies the shared access-model SoD remediation form.
**Aliases**: formDefinitionId (rejected as apply invoke input)
**Notes**: Scan ensures the definition from seed; apply looks up the existing definition by this name then lists instances by the resolved form definition id.

### Term: Form definition id
**Context**: connector-operations / access-model-sod-remediation-apply / target-client/forms
**Definition**: The ISC Custom Forms identifier of the form definition that spawned a form instance (`formDefinitionId`).
**Aliases**: formId (rejected shorthand)
**Notes**: Internal list filter for tenant form instances. Apply obtains it via form name lookup; it is not an apply invoke field. Distinct from `formInstanceId`.

### Term: Access model SoD remediation apply
**Context**: connector-operations / access-model-sod-remediation-apply
**Definition**: The custom operation that reads a completed access-model SoD remediation form instance and mutates the referenced role or access profile in the ISC catalog per `remediationSide`.
**Aliases**: none
**Notes**: Required inputs are `formInstanceId` and `formName`; persist identity is `{formInstanceId}`.
