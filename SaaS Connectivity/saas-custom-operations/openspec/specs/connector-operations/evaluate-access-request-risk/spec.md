# connector-operations/evaluate-access-request-risk Specification

## Purpose
Scores requested ISC access items and persists the highest risk tier on a result-source account keyed by **risk persist identity**, so bundled Risk Approval workflows can read that tier back.
## Requirements
### Requirement: Risk persist identity is derived from the command slug

The evaluate-access-request-risk operation SHALL persist outputs on result-source identity `evaluate-access-request-risk:{requestId}`, where `{requestId}` is the invoke `requestId`. The handler SHALL derive that identity in code through a builder under `src/operations/evaluate-access-request-risk/` and SHALL NOT pass the raw invoke `requestId` to `ctx.persist`. The builder SHALL be idempotent: a `requestId` that already begins with `evaluate-access-request-risk:` SHALL be returned unchanged rather than prefixed a second time.

#### Scenario: Successful evaluation persists on the prefixed identity

- **GIVEN** an invoke with `requestId` `req-abc:dynamic` whose requested items score `High`
- **WHEN** the operation completes successfully
- **THEN** it SHALL call persist with identity `evaluate-access-request-risk:req-abc:dynamic`
- **AND** SHALL NOT call persist with identity `req-abc:dynamic`

#### Scenario: Persisted attribute keys are unchanged by the prefix

- **GIVEN** an invoke with `requestId` `req-abc:dynamic` that scores `Medium`
- **WHEN** the operation persists its result
- **THEN** the written account SHALL carry `evaluate-access-request-risk:tier`, `evaluate-access-request-risk:situation-summary`, and `evaluate-access-request-risk:contributing-ids`
- **AND** the attribute names SHALL NOT change because the identity gained a prefix

#### Scenario: Already-prefixed request id is not prefixed twice

- **GIVEN** an invoke whose `requestId` is `evaluate-access-request-risk:req-abc:dynamic`
- **WHEN** the operation persists its result
- **THEN** it SHALL call persist with identity `evaluate-access-request-risk:req-abc:dynamic`
- **AND** SHALL NOT call persist with identity `evaluate-access-request-risk:evaluate-access-request-risk:req-abc:dynamic`

#### Scenario: Request id without a wrapper discriminator still gets the prefix

- **GIVEN** a caller invokes the command directly with `requestId` `manual-001` and no wrapper discriminator
- **WHEN** the operation persists its result
- **THEN** it SHALL call persist with identity `evaluate-access-request-risk:manual-001`

#### Scenario: Wrapper discriminators keep the three bundled workflows separate

- **GIVEN** access request `req-abc` is scored by all three bundled workflows
- **WHEN** each workflow invokes the command with its own wrapper discriminator
- **THEN** the persisted identities SHALL be `evaluate-access-request-risk:req-abc:submitted`, `evaluate-access-request-risk:req-abc:dynamic`, and `evaluate-access-request-risk:req-abc:dynamic-approval`
- **AND** no wrapper SHALL overwrite another wrapper's result account

### Requirement: Failed risk evaluation persists on the same prefixed identity

The evaluate-access-request-risk operation SHALL declare its result identity builder to the framework so automatic failed-account persist targets `evaluate-access-request-risk:{requestId}`, the same identity the success path writes. A lookup failure SHALL therefore remain discoverable at the identity the bundled workflows query, rather than producing a silent `Low` or an account the workflows cannot find.

#### Scenario: Handler throw persists a failed account on the prefixed identity

- **GIVEN** an invoke with `requestId` `req-abc:dynamic`
- **AND** the entitlement lookup rejects with `entitlement not found`
- **WHEN** the operation terminates with a failure
- **THEN** the framework SHALL upsert an account with identity `evaluate-access-request-risk:req-abc:dynamic`, status `failed`, and details containing `entitlement not found`
- **AND** SHALL NOT upsert an account with identity `req-abc:dynamic`

#### Scenario: Missing requested items persists a failed account on the prefixed identity

- **GIVEN** an invoke with `requestId` `req-abc:dynamic` and neither `requestedItems` nor `accessRequestId`
- **WHEN** the operation rejects the input
- **THEN** the framework SHALL upsert a failed account with identity `evaluate-access-request-risk:req-abc:dynamic`
- **AND** the details SHALL describe the missing input

### Requirement: Bundled risk workflows read back the prefixed identity

Each bundled Risk Approval workflow SHALL filter its `Read Risk Result` step on the same identity the handler writes. The `Read Risk Result` `nativeIdentity` value SHALL equal the risk persist identity built from that workflow's `Call Evaluate Risk` `requestId` input, for `Risk Approval - Auto Approve or Deny`, `Risk Approval - Dynamic Approver`, and `Risk Approval - Dynamic approval workflow`. A test SHALL assert this pairing against the shipped workflow JSON so the handler and workflow sides cannot drift independently.

#### Scenario: Auto approve or deny reads the prefixed identity

- **GIVEN** the shipped `Risk Approval - Auto Approve or Deny.json`
- **WHEN** its `Read Risk Result` step filter value is read
- **THEN** it SHALL be `evaluate-access-request-risk:{{$.trigger.accessRequestId}}:submitted`

#### Scenario: Dynamic approver reads the prefixed identity

- **GIVEN** the shipped `Risk Approval - Dynamic Approver.json`
- **WHEN** its `Read Risk Result` step filter value is read
- **THEN** it SHALL be `evaluate-access-request-risk:{{$.trigger.accessRequestId}}:dynamic`

#### Scenario: Dynamic approval workflow reads the prefixed identity

- **GIVEN** the shipped `Risk Approval - Dynamic approval workflow.json`
- **WHEN** its `Read Risk Result` step filter value is read
- **THEN** it SHALL be `evaluate-access-request-risk:{{$.trigger.accessRequestId}}:dynamic-approval`

#### Scenario: Workflow read filter is derived from the handler's builder

- **GIVEN** each bundled Risk Approval workflow's `Call Evaluate Risk` `input.requestId` template
- **WHEN** the risk persist identity builder is applied to that template string
- **THEN** the result SHALL equal that workflow's `Read Risk Result` filter value
- **AND** the test SHALL fail if either side is changed without the other

### Requirement: Pre-rename risk accounts are left in place

The evaluate-access-request-risk operation SHALL NOT read, backfill, update, or delete result-source accounts written on the bare `{requestId}` identity before the prefix was introduced. No legacy-identity fallback lookup SHALL be performed, because the operation never reads its own result account.

#### Scenario: No legacy lookup on invoke

- **GIVEN** a result-source account exists at bare identity `req-abc:dynamic` from a pre-rename invoke
- **WHEN** the operation is invoked again with `requestId` `req-abc:dynamic`
- **THEN** it SHALL persist on `evaluate-access-request-risk:req-abc:dynamic`
- **AND** SHALL NOT read the account at `req-abc:dynamic`
- **AND** the account at `req-abc:dynamic` SHALL be left unchanged
