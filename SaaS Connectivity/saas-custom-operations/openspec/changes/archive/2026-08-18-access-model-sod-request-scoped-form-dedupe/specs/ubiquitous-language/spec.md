## ADDED Requirements

### Requirement: Parent request id term

The glossary SHALL define **parent request id** as the `requestId` supplied on a `custom:access-model-sod-remediation` invoke. It scopes child result-source identities `` `${requestId}:{accessItemId}:{policyId}` `` and, when stored on form instances as `formInput.parentRequestId`, scopes pending-form dedupe for that scan run.

#### Scenario: Parent request id naming

- **GIVEN** specs or code correlate access-model scan forms to their launching invoke
- **WHEN** normative text names the scan invoke identifier on form instances
- **THEN** it SHALL use **parent request id** for the scan `requestId` concept
- **AND** the form field SHALL be spelled `parentRequestId`

### Requirement: Request-scoped form dedupe term

The glossary SHALL define **request-scoped form dedupe** as skipping launch of an access-model SoD remediation form when an ASSIGNED instance already exists for the same form definition, parent request id, access item id, and policy id — rather than matching tenant-wide on access item and policy alone.

#### Scenario: Request-scoped dedupe naming

- **GIVEN** specs describe access-model scan idempotency for pending forms
- **WHEN** normative text contrasts tenant-wide versus per-scan dedupe
- **THEN** it SHALL use **request-scoped form dedupe** for the per-parent-request-id behavior

---

## MODIFIED Requirements

_(none)_

---

## REMOVED Requirements

_(none)_
