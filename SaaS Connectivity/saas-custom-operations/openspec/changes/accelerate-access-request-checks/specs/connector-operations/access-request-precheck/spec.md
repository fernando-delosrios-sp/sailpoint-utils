# connector-operations/evaluate-access-request Specification

## Purpose

Scores access-request risk and/or preventive SoD in one invoke for Access Request Submitted pre-check and Dynamic Approver wrappers. Workflows read the indexed result account; `waitForPersist` defaults to true.

## Requirements

### Requirement: Unified evaluate-access-request command

The connector SHALL register `custom:evaluate-access-request` under `src/operations/evaluate-access-request/`. The handler SHALL evaluate each enabled check for the supplied access request. `evaluateRisk` SHALL default to true. `evaluateSod` SHALL default to false. When both are true, the handler SHALL run the two evaluations concurrently with a shared entitlement expansion cache. A check set to false SHALL be omitted from the persisted account and from `ctx.respond` summary. Setting both to false SHALL fail the invoke without running either evaluation. `identityId` SHALL be required when `evaluateSod` is true. `waitForPersist` SHALL default to true.

#### Scenario: Successful combined evaluation

- **GIVEN** an invoke with `accessRequestId`, `identityId`, `requestedItems`, `evaluateSod` true, and `requestId` `access-request-precheck:req-1:submitted`
- **WHEN** both evaluations succeed
- **THEN** the operation SHALL persist one account at that `requestId` carrying the six namespaced attributes from risk and preventive SoD
- **AND** `ctx.respond` summary SHALL include `tier`, `situationSummary`, `contributingIds`, `hasViolation`, `sodSituationSummary`, and `violatedPolicyNames`

#### Scenario: Default persist waits for verification

- **GIVEN** an invoke that omits `waitForPersist` or sets it `true`
- **WHEN** the operation persists
- **THEN** it SHALL wait for provisioning-task completion and indexed-account verification before returning

#### Scenario: Risk-only invoke omits SoD

- **GIVEN** an invoke that omits `evaluateSod` or sets it false
- **WHEN** risk evaluation succeeds
- **THEN** the summary SHALL include `tier`, `situationSummary`, and `contributingIds`
- **AND** the summary and persisted account SHALL omit SoD attributes
- **AND** preventive SoD prediction SHALL NOT be called

#### Scenario: SoD-only invoke omits risk

- **GIVEN** an invoke with `evaluateRisk` false and `evaluateSod` true
- **WHEN** preventive SoD evaluation succeeds
- **THEN** the summary SHALL include `hasViolation`, `sodSituationSummary`, and `violatedPolicyNames`
- **AND** the summary and persisted account SHALL omit risk attributes

#### Scenario: Both checks disabled

- **GIVEN** an invoke with `evaluateRisk` false and `evaluateSod` false
- **WHEN** the operation runs
- **THEN** it SHALL fail without evaluating risk or preventive SoD

#### Scenario: Failure persists failed account

- **GIVEN** an enabled risk or SoD evaluation throws
- **WHEN** the operation terminates
- **THEN** the framework SHALL upsert a failed account on the invoke `requestId`

### Requirement: Bundled wrappers use the unified command

The shipped Access Request Pre-Check and Dynamic Approver workflows SHALL invoke `custom:evaluate-access-request` and SHALL branch on the indexed result account rather than parsing the HTTP body for tier or violation fields.

#### Scenario: Pre-check request id

- **GIVEN** the shipped Access Request Pre-Check workflow JSON
- **WHEN** its invoke `requestId` is read
- **THEN** it SHALL be `access-request-precheck:{{$.trigger.accessRequestId}}:submitted`
- **AND** `evaluateSod` SHALL be `true`
- **AND** the workflow SHALL Get Accounts on that nativeIdentity after the invoke

#### Scenario: Dynamic Approver request ids

- **GIVEN** the shipped Dynamic Approver Risk analysis workflows
- **WHEN** their invoke `requestId` values are read
- **THEN** they SHALL use `evaluate-access-request-risk:{{$.trigger.accessRequestId}}:dynamic` and `:dynamic-approval`
- **AND** `evaluateSod` SHALL be omitted (risk only)
