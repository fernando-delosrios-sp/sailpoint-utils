## ADDED Requirements

### Requirement: Child persist account idempotency term

The glossary SHALL define **child persist account idempotency** as skipping launch of an access-model SoD remediation form and skipping child persist when a result-source account already exists for child persist identity `` `${requestId}:{accessItemId}:{policyId}` `` on the operation source — without querying form instance state.

#### Scenario: Child persist idempotency naming

- **GIVEN** specs describe access-model scan idempotency on retry or concurrent invoke
- **WHEN** normative text names the skip signal
- **THEN** it SHALL use **child persist account idempotency**
- **AND** SHALL NOT describe idempotency as dependent on ASSIGNED form instance state

### Requirement: Child persist identity term

The glossary SHALL define **child persist identity** as the result-source native identity `` `${requestId}:{accessItemId}:{policyId}` `` where per-violation access-model SoD remediation outputs are persisted after form launch.

#### Scenario: Child persist identity naming

- **GIVEN** specs or code refer to per-violation result-source account keys for the access-model scan
- **WHEN** normative text names that key pattern
- **THEN** it SHALL use **child persist identity**

---

## MODIFIED Requirements

### Requirement: Parent request id term

The glossary SHALL define **parent request id** as the `requestId` supplied on a `custom:access-model-sod-remediation` invoke. It prefixes child persist identities `` `${requestId}:{accessItemId}:{policyId}` `` and is stored on form instances as `formInput.parentRequestId` for traceability.

#### Scenario: Parent request id naming

- **GIVEN** specs or code correlate access-model scan forms to their launching invoke
- **WHEN** normative text names the scan invoke identifier on form instances
- **THEN** it SHALL use **parent request id** for the scan `requestId` concept
- **AND** the form field SHALL be spelled `parentRequestId`

### Requirement: Access model scan summary term

The glossary SHALL define **scan summary** as the rollup counters returned on the successful `custom:access-model-sod-remediation` invoke response via `ctx.res.send`, comprising `access-model-sod-remediation:access-items-scanned`, `access-model-sod-remediation:violations-found`, and optional `access-model-sod-remediation:forms-skipped` and `access-model-sod-remediation:forms-persist-failed`. Optional `forms-skipped` SHALL count violations skipped because the child persist account already exists. The scan summary SHALL NOT be persisted as a result-source account on `requestId`.

#### Scenario: Scan summary term

- **GIVEN** specs or code refer to rollup counts from an access-model scan invoke
- **WHEN** normative text names the delivery mechanism
- **THEN** it SHALL use **scan summary** for the invoke response payload
- **AND** SHALL NOT describe rollup counters as a parent or summary result-source account on `requestId`

---

## REMOVED Requirements

### Requirement: Request-scoped form dedupe term

**Reason**: Replaced by **child persist account idempotency**; scan idempotency no longer uses ASSIGNED form instance matching.

**Migration**: Update normative text and operator docs to reference child persist account existence instead of request-scoped form dedupe.

---

## RENAMED Requirements

_(none)_
