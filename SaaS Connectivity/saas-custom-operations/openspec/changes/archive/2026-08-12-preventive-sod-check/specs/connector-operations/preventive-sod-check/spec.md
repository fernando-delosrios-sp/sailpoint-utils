## ADDED Requirements

### Requirement: Preventive SOD check operation

The connector SHALL register a custom command `custom:preventive-sod-check` that evaluates SoD violation state for an identity. Output semantics SHALL depend on whether optional input `accessRequestId` is provided. Implementation SHALL reside under `src/operations/preventive-sod-check/` with entry module `index.ts`.

#### Scenario: Operation invoked with required identityId

- **GIVEN** `custom:preventive-sod-check` is declared in connector-spec.json and registered
- **WHEN** ISC invokes the command with input containing `identityId`, standard `requestId`, and **no** `accessRequestId`
- **THEN** the handler SHALL list active SoD violations for the identity, list executing GRANT_ACCESS access requests, resolve access items, expand roles and access profiles to entitlements, call the SoD predict API for inflight grants, and persist namespaced output fields `preventive-sod-check:has-violation`, `preventive-sod-check:situation-summary`, and `preventive-sod-check:violated-policy-names`

#### Scenario: Request mode invoked with accessRequestId only

- **GIVEN** input includes `accessRequestId` and omits `identityId`
- **WHEN** `custom:preventive-sod-check` completes successfully
- **THEN** the handler SHALL resolve the target identity from the EXECUTING GRANT_ACCESS access request
- **AND** SHALL run request-mode differential predict scoped to that `accessRequestId`

#### Scenario: identityId ignored when accessRequestId is also provided

- **GIVEN** input includes both `identityId` and `accessRequestId`
- **WHEN** `custom:preventive-sod-check` executes
- **THEN** the handler SHALL log a warning that `identityId` is ignored
- **AND** SHALL resolve the target identity from the access request (not from input `identityId`)
- **AND** SHALL run request-mode differential predict

#### Scenario: Missing identityId and accessRequestId rejected

- **GIVEN** input omits both `identityId` and `accessRequestId`
- **WHEN** `custom:preventive-sod-check` executes
- **THEN** the handler SHALL fail with a ConnectorError indicating at least one is required

#### Scenario: Identity mode has-violation and policy names

- **GIVEN** input does not include `accessRequestId`
- **AND** the identity has active violation policy `Existing Control` and predict returns `Finance Control` and `Procurement Control` for inflight grants
- **WHEN** the handler persists operation output
- **THEN** `preventive-sod-check:has-violation` SHALL be `true`
- **AND** `preventive-sod-check:violated-policy-names` SHALL be the deduplicated union `["Existing Control", "Finance Control", "Procurement Control"]` in stable order

#### Scenario: Request mode scopes outputs to request delta

- **GIVEN** input includes `accessRequestId` matching an EXECUTING GRANT_ACCESS request
- **WHEN** `custom:preventive-sod-check` completes successfully
- **THEN** the handler SHALL run differential predict (full pending grants minus grants for the target `accessRequestId`)
- **AND** `preventive-sod-check:violated-policy-names` SHALL contain only policies introduced by the target request (predict delta)
- **AND** `preventive-sod-check:has-violation` SHALL be `true` only when the delta is non-empty

#### Scenario: Request mode pre-existing violation only

- **GIVEN** input includes `accessRequestId` that does not match any EXECUTING grant tracking number
- **OR** the target request introduces no new predictive violation beyond baseline pending grants
- **WHEN** the handler persists operation output
- **THEN** `preventive-sod-check:has-violation` SHALL be `false`
- **AND** `preventive-sod-check:violated-policy-names` SHALL be an empty array
- **AND** `preventive-sod-check:situation-summary` SHALL be `No violations found`

#### Scenario: No violations summary

- **GIVEN** identity mode with no active violations and predict returns zero violated policies
- **WHEN** the handler persists operation output
- **THEN** `preventive-sod-check:has-violation` SHALL be `false`
- **AND** `preventive-sod-check:situation-summary` SHALL be exactly `No violations found`
- **AND** `preventive-sod-check:violated-policy-names` SHALL be an empty array

#### Scenario: Violations without accessRequestId summary text

- **GIVEN** violated policy names `["Policy A", "Policy B"]` in identity mode
- **AND** input does not include `accessRequestId`
- **WHEN** the handler persists operation output
- **THEN** `preventive-sod-check:situation-summary` SHALL list all violating policy names in plain text

#### Scenario: Violations with accessRequestId summary text

- **GIVEN** request-mode delta policy names `["Finance Control"]`
- **AND** input includes `accessRequestId` set to `req-456`
- **WHEN** the handler persists operation output
- **THEN** `preventive-sod-check:situation-summary` SHALL attribute the violation context to access request `req-456`
- **AND** SHALL mention violated policy name `Finance Control`

#### Scenario: Output contract excludes approved field

- **GIVEN** a successful preventive check
- **WHEN** the handler completes
- **THEN** operation output persisted via `ctx.persist` SHALL include `preventive-sod-check:has-violation`, `preventive-sod-check:situation-summary`, and `preventive-sod-check:violated-policy-names` as typed output fields
- **AND** SHALL NOT persist an `approved` boolean or string field

#### Scenario: Auto-discovery registration

- **GIVEN** `src/operations/preventive-sod-check/index.ts` declares `command: 'custom:preventive-sod-check'` on its OperationSignature interface
- **WHEN** codegen runs
- **THEN** `custom:preventive-sod-check` SHALL be registered in auto-registry.ts and listed in connector-spec.json commands

### Requirement: Executing GRANT_ACCESS request filter

The preventive-sod-check operation SHALL discover pending grant impact by listing access request status in EXECUTING state and retaining only GRANT_ACCESS operations before resolving access items.

#### Scenario: EXECUTING grants only

- **GIVEN** identity `id-a` has one EXECUTING GRANT_ACCESS request and one completed GRANT_ACCESS request
- **WHEN** `custom:preventive-sod-check` runs for `id-a`
- **THEN** the handler SHALL include only the EXECUTING GRANT_ACCESS request when resolving items for prediction
- **AND** SHALL NOT include non-GRANT_ACCESS operations such as REVOKE_ACCESS

#### Scenario: No executing grants in identity mode

- **GIVEN** identity `id-a` has no EXECUTING GRANT_ACCESS requests and no active SoD violations
- **WHEN** `custom:preventive-sod-check` runs for `id-a` without `accessRequestId`
- **THEN** the handler SHALL skip predict when no pending entitlements exist
- **AND** SHALL persist `preventive-sod-check:has-violation` as `false`
- **AND** SHALL persist `preventive-sod-check:situation-summary` as `No violations found`
- **AND** SHALL persist `preventive-sod-check:violated-policy-names` as an empty array

#### Scenario: Active violations without pending grants

- **GIVEN** identity `id-a` has active SoD violation policy `Existing Control`
- **AND** identity `id-a` has no EXECUTING GRANT_ACCESS requests
- **WHEN** `custom:preventive-sod-check` runs for `id-a` without `accessRequestId`
- **THEN** `preventive-sod-check:has-violation` SHALL be `true`
- **AND** `preventive-sod-check:violated-policy-names` SHALL include `Existing Control`

### Requirement: Preventive situation summary builder

The preventive-sod-check operation SHALL build `preventive-sod-check:situation-summary` using a dedicated builder function fed the mode-appropriate violated policy name list and optional `accessRequestId`.

#### Scenario: Builder no violations

- **GIVEN** violated policy names `[]`
- **WHEN** the situation summary builder runs with any `accessRequestId`
- **THEN** the builder SHALL return `No violations found`

#### Scenario: Builder lists all policies without request context

- **GIVEN** violated policy names `["Finance Control", "Procurement Control"]`
- **AND** no `accessRequestId` is provided
- **WHEN** the situation summary builder runs
- **THEN** the builder SHALL return plain text that lists both policy names

#### Scenario: Builder attributes request when provided

- **GIVEN** violated policy names `["Finance Control"]`
- **AND** `accessRequestId` is `req-456`
- **WHEN** the situation summary builder runs
- **THEN** the builder SHALL return plain text that references access request `req-456`
- **AND** SHALL mention the violated policy name `Finance Control`
