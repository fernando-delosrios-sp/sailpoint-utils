# connector-operations/evaluate-access-request-risk Specification

## Purpose
Scores requested ISC access items and persists the highest risk tier on a result-source account keyed by **risk persist identity**, so bundled Risk Approval workflows can read that tier back.
## Requirements
### Requirement: Risk persist identity is the invoke request id

The evaluate-access-request-risk operation SHALL persist outputs on the invoke `requestId` verbatim. The handler SHALL pass `ctx.requestId` to `ctx.persist` and SHALL NOT prefix, rewrite, or otherwise transform that identity. Callers that want a command-named account SHALL put that name in `requestId`. Bundled Risk Approval workflows SHALL set `requestId` to `evaluate-access-request-risk:{{$.trigger.accessRequestId}}:{discriminator}`.

#### Scenario: Successful evaluation persists on the invoke request id

- **GIVEN** an invoke with `requestId` `evaluate-access-request-risk:req-abc:dynamic` whose requested items score `High`
- **WHEN** the operation completes successfully
- **THEN** it SHALL call persist with identity `evaluate-access-request-risk:req-abc:dynamic`

#### Scenario: Persisted attribute keys are independent of the account identity

- **GIVEN** an invoke with `requestId` `evaluate-access-request-risk:req-abc:dynamic` that scores `Medium`
- **WHEN** the operation persists its result
- **THEN** the written account SHALL carry `evaluate-access-request-risk:tier`, `evaluate-access-request-risk:situation-summary`, and `evaluate-access-request-risk:contributing-ids`

#### Scenario: Handler does not prefix the request id

- **GIVEN** an invoke whose `requestId` is `evaluate-access-request-risk:req-abc:dynamic`
- **WHEN** the operation persists its result
- **THEN** it SHALL call persist with identity `evaluate-access-request-risk:req-abc:dynamic`
- **AND** SHALL NOT call persist with identity `evaluate-access-request-risk:evaluate-access-request-risk:req-abc:dynamic`

#### Scenario: Direct invoke persists the request id it was given

- **GIVEN** a caller invokes the command directly with `requestId` `manual-001` and no wrapper discriminator
- **WHEN** the operation persists its result
- **THEN** it SHALL call persist with identity `manual-001`

#### Scenario: Wrapper discriminators keep the three bundled workflows separate

- **GIVEN** access request `req-abc` is scored by all three bundled workflows
- **WHEN** each workflow invokes the command with its own `requestId`
- **THEN** the persisted identities SHALL be `evaluate-access-request-risk:req-abc:submitted`, `evaluate-access-request-risk:req-abc:dynamic`, and `evaluate-access-request-risk:req-abc:dynamic-approval`
- **AND** no wrapper SHALL overwrite another wrapper's result account

### Requirement: Failed risk evaluation persists on the same request id

The evaluate-access-request-risk operation SHALL persist failed accounts on the invoke `requestId`, the same identity the success path writes. A lookup failure SHALL therefore remain discoverable at the identity the bundled workflows query, rather than producing a silent `Low` or an account the workflows cannot find.

#### Scenario: Handler throw persists a failed account on the invoke request id

- **GIVEN** an invoke with `requestId` `evaluate-access-request-risk:req-abc:dynamic`
- **AND** the entitlement lookup rejects with `entitlement not found`
- **WHEN** the operation terminates with a failure
- **THEN** the framework SHALL upsert an account with identity `evaluate-access-request-risk:req-abc:dynamic`, status `failed`, and details containing `entitlement not found`

#### Scenario: Missing requested items persists a failed account on the invoke request id

- **GIVEN** an invoke with `requestId` `evaluate-access-request-risk:req-abc:dynamic` and neither `requestedItems` nor `accessRequestId`
- **WHEN** the operation rejects the input
- **THEN** the framework SHALL upsert a failed account with identity `evaluate-access-request-risk:req-abc:dynamic`
- **AND** the details SHALL describe the missing input

### Requirement: Bundled risk workflows send and read the same request id

Each bundled Risk Approval workflow SHALL set `Call Evaluate Risk` `input.requestId` to the **risk persist identity** and SHALL filter `Read Risk Result` on that same value, for `Access Request Pre-Check - Risk analysis and in-flight SOD`, `Dynamic Approver - Risk analysis`, and `Dynamic Approval Workflow - Risk analysis`. A test SHALL assert this pairing against the shipped workflow JSON so the invoke and read-back sides cannot drift independently.

#### Scenario: Access Request Pre-Check - Risk analysis and in-flight SOD reads the prefixed identity

- **GIVEN** the shipped `Access Request Pre-Check - Risk analysis and in-flight SOD.json`
- **WHEN** its `Call Evaluate Risk` `requestId` and `Read Risk Result` filter value are read
- **THEN** both SHALL be `evaluate-access-request-risk:{{$.trigger.accessRequestId}}:submitted`

#### Scenario: Dynamic Approver - Risk analysis reads the prefixed identity

- **GIVEN** the shipped `Dynamic Approver - Risk analysis.json`
- **WHEN** its `Call Evaluate Risk` `requestId` and `Read Risk Result` filter value are read
- **THEN** both SHALL be `evaluate-access-request-risk:{{$.trigger.accessRequestId}}:dynamic`

#### Scenario: Dynamic Approval Workflow - Risk analysis reads the prefixed identity

- **GIVEN** the shipped `Dynamic Approval Workflow - Risk analysis.json`
- **WHEN** its `Call Evaluate Risk` `requestId` and `Read Risk Result` filter value are read
- **THEN** both SHALL be `evaluate-access-request-risk:{{$.trigger.accessRequestId}}:dynamic-approval`

#### Scenario: Workflow read filter equals the invoke request id

- **GIVEN** each bundled Risk Approval workflow's `Call Evaluate Risk` `input.requestId` template
- **WHEN** that workflow's `Read Risk Result` filter value is read
- **THEN** the two strings SHALL be equal
- **AND** the test SHALL fail if either side is changed without the other

### Requirement: Pre-rename risk accounts are left in place

The evaluate-access-request-risk operation SHALL NOT read, backfill, update, or delete result-source accounts written on a pre-convention identity. No legacy-identity fallback lookup SHALL be performed, because the operation never reads its own result account.

#### Scenario: No legacy lookup on invoke

- **GIVEN** a result-source account exists at bare identity `req-abc:dynamic` from a pre-convention invoke
- **WHEN** the operation is invoked again with `requestId` `evaluate-access-request-risk:req-abc:dynamic`
- **THEN** it SHALL persist on `evaluate-access-request-risk:req-abc:dynamic`
- **AND** SHALL NOT read the account at `req-abc:dynamic`
- **AND** the account at `req-abc:dynamic` SHALL be left unchanged
