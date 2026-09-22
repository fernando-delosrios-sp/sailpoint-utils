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

### Requirement: Risk situation summary reports counts, not identifiers

The **risk situation summary** persisted at `evaluate-access-request-risk:situation-summary` SHALL describe the evaluation as counts of distinct evaluated objects grouped by object type. It SHALL NOT contain role, access profile, or entitlement names, and SHALL NOT contain their ids. Identifiers of the winning **risk drivers** SHALL remain available on `evaluate-access-request-risk:contributing-ids`, which this requirement leaves unchanged.

#### Scenario: Summary omits names and identifiers

- **GIVEN** a request for role `role-1` named `Business Process Users` whose entitlement `ent-9` scores `High`
- **WHEN** the operation builds the risk situation summary
- **THEN** the summary SHALL NOT contain `Business Process Users`
- **AND** SHALL NOT contain `role-1` or `ent-9`
- **AND** `evaluate-access-request-risk:contributing-ids` SHALL still contain `ent-9`

#### Scenario: Summary length does not grow with request size

- **GIVEN** a request whose evaluation produces fifty entitlement risk drivers at the winning tier
- **WHEN** the operation builds the risk situation summary
- **THEN** the summary SHALL be at most 256 characters
- **AND** SHALL report the drivers as a count rather than as a list

### Requirement: Risk situation summary states the deciding rule

For a `Medium` or `High` result, the risk situation summary SHALL open with the tier, the count of winning **risk drivers** out of the distinct objects evaluated for each contributing type, and a parenthesized split of those drivers by **deciding rule**. The split SHALL name only rules with a non-zero count, ordered effective privilege before Risk metadata. A driver SHALL be attributed to exactly one rule.

#### Scenario: High result splits drivers across both rules

- **GIVEN** an evaluation of one role, two access profiles, and six entitlements
- **AND** one entitlement scores `High` on effective privilege and another scores `High` on Risk metadata
- **WHEN** the operation builds the risk situation summary
- **THEN** the summary SHALL be `High: 2 of 6 entitlements scored High (1 by effective privilege, 1 by Risk metadata). Evaluated 1 role, 2 access profiles, 6 entitlements.`

#### Scenario: Single deciding rule omits the zero-count rule

- **GIVEN** an evaluation where the only `Medium` driver is an access profile whose Risk metadata is medium
- **WHEN** the operation builds the risk situation summary
- **THEN** the deciding-rule split SHALL read `(1 by Risk metadata)`
- **AND** SHALL NOT mention effective privilege

#### Scenario: Entitlement matching both rules is attributed to effective privilege

- **GIVEN** an entitlement whose effective privilege is `HIGH` and whose Risk metadata is `critical`
- **WHEN** the operation attributes that risk driver to a deciding rule
- **THEN** it SHALL attribute the driver to effective privilege
- **AND** the counts in the deciding-rule split SHALL sum to the number of winning risk drivers

#### Scenario: Privilege is not credited when considerPrivilege is false

- **GIVEN** an invoke with `considerPrivilege` `false`
- **AND** an entitlement whose effective privilege is `HIGH` and whose Risk metadata is absent
- **WHEN** the operation builds the risk situation summary
- **THEN** the summary SHALL NOT attribute any driver to effective privilege

### Requirement: Low risk situation summary states what was evaluated

For a `Low` result the risk situation summary SHALL state that nothing scored `Medium` or `High` and SHALL report the tally of distinct objects evaluated. It SHALL NOT be the bare string `Low`.

#### Scenario: Low result reports the tally

- **GIVEN** an evaluation of one role, two access profiles, and six entitlements where every object scores `Low`
- **WHEN** the operation builds the risk situation summary
- **THEN** the summary SHALL be `Low: nothing scored Medium or High. Evaluated 1 role, 2 access profiles, 6 entitlements.`

#### Scenario: Low result still writes no contributing ids

- **GIVEN** an evaluation whose highest tier is `Low`
- **WHEN** the operation persists its result
- **THEN** `evaluate-access-request-risk:contributing-ids` SHALL be empty

### Requirement: Evaluated tally counts distinct objects by type

The tally sentence SHALL count distinct `type:id` pairs, SHALL order types role, access profile, entitlement, SHALL omit a type with a zero count, and SHALL pluralize each count. A container SHALL be counted in the tally at the tier its own attributes earn, so a clean role holding a risky entitlement SHALL NOT appear as a winning **risk driver**.

#### Scenario: Role requested twice is counted once

- **GIVEN** a request naming the same role id twice
- **WHEN** the operation builds the tally
- **THEN** the tally SHALL report `1 role`

#### Scenario: Entitlement shared by two access profiles is counted once

- **GIVEN** a role whose two access profiles both contain entitlement `ent-shared`
- **WHEN** the operation builds the tally
- **THEN** `ent-shared` SHALL contribute `1` to the entitlement count

#### Scenario: Absent type is omitted from the tally

- **GIVEN** a request for two entitlements and no role or access profile
- **WHEN** the operation builds the tally
- **THEN** the tally SHALL read `Evaluated 2 entitlements.`
- **AND** SHALL NOT mention roles or access profiles

#### Scenario: Clean role holding a High entitlement is not a driver

- **GIVEN** a role whose own Risk metadata is absent and whose entitlement scores `High`
- **WHEN** the operation builds the risk situation summary
- **THEN** the winning counts SHALL attribute the tier to the entitlement only
- **AND** the role SHALL appear in the tally but SHALL NOT be reported as having scored `High`

#### Scenario: Counts are pluralized

- **GIVEN** an evaluation of exactly one role and one entitlement
- **WHEN** the operation builds the tally
- **THEN** the tally SHALL read `Evaluated 1 role, 1 entitlement.`
