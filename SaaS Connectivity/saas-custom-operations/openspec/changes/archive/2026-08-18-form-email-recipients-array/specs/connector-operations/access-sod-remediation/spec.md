## ADDED Requirements

### Requirement: Access SOD remediation form email notification outputs

The access-sod-remediation operation SHALL persist workflow-oriented email fields on each child result-source identity when a remediation form is created. Recipient emails SHALL be persisted as a multi-value string array suitable for ISC Send Email `recipientEmailList` consumption.

#### Scenario: Child persist includes form email fields

- **GIVEN** role `role-a` violates policy `policy-p` and a form is created
- **WHEN** the handler persists per-form output on child identity `` `${requestId}:role-a:policy-p` ``
- **THEN** child output SHALL include `access-sod-remediation:form-email-header`, `access-sod-remediation:form-email-body`, and `access-sod-remediation:form-email-recipients`

#### Scenario: Policy owner email as recipients array

- **GIVEN** policy `policy-p` owner identity `owner-z` resolves to email `owner-z@example.com`
- **WHEN** a form is created for a violation of `policy-p`
- **THEN** persisted output `access-sod-remediation:form-email-recipients` SHALL be `['owner-z@example.com']`

#### Scenario: Recipients attribute is multi-value string

- **GIVEN** a successful child persist for access-sod-remediation
- **WHEN** operation output schema is inferred for account aggregation
- **THEN** `access-sod-remediation:form-email-recipients` SHALL be typed `string[]` with account schema `STRING` and `isMulti: true`

## MODIFIED Requirements

### Requirement: Access SOD remediation scan operation

The connector SHALL register a custom command `custom:access-sod-remediation` that scans enabled roles and/or access profiles in scope, detects intrinsic SoD policy violations by entitlement intersection against policy side definitions, and creates standalone remediation form instances for policy owners. Implementation SHALL reside under `src/operations/access-sod-remediation/` with entry module `index.ts`. The operation SHALL NOT use the SoD predict API.

#### Scenario: Operation invoked with required formName

- **GIVEN** `custom:access-sod-remediation` is declared in connector-spec.json and registered
- **WHEN** ISC invokes the command with input containing `formName` and standard `requestId`
- **THEN** the handler SHALL list access items per `searchIndices`, evaluate each against policies matching `policyScope`, create remediation forms for violations, persist parent rollup on `requestId`, and persist per-form output on child identities `` `${requestId}:{accessItemId}:{policyId}` ``

#### Scenario: Default scope and searchIndices

- **GIVEN** input omits `scope` and `searchIndices`
- **WHEN** the handler discovers access items
- **THEN** `scope` SHALL default to `"*"` (no additional search filter)
- **AND** `searchIndices` SHALL default to `['accessprofiles', 'roles']`
- **AND** only enabled roles and access profiles SHALL be included

#### Scenario: searchIndices validation

- **GIVEN** input includes `searchIndices` with a value other than `accessprofiles` and/or `roles`
- **WHEN** `custom:access-sod-remediation` executes
- **THEN** the handler SHALL fail with ConnectorError indicating invalid search index values

#### Scenario: Non-wildcard scope filter

- **GIVEN** input includes `scope` set to `name sw "SAP-"`
- **WHEN** the handler lists roles and access profiles
- **THEN** the list APIs SHALL apply the scope string as an additional filter alongside the enabled filter

#### Scenario: Default policyScope

- **GIVEN** input omits `policyScope`
- **WHEN** the handler loads SoD policies
- **THEN** policies SHALL be filtered with `state eq "ENFORCED"`

#### Scenario: Parent persist rollup

- **GIVEN** a scan evaluates 50 access items and finds 3 violations creating 3 forms (2 skipped by idempotency)
- **WHEN** the handler completes
- **THEN** parent persist on `requestId` SHALL include `access-sod-remediation:access-items-scanned` equal to 50
- **AND** `access-sod-remediation:violations-found` equal to 3
- **AND** `access-sod-remediation:forms-skipped` equal to 2
- **AND** SHALL NOT persist `access-sod-remediation:forms-created`

#### Scenario: Child persist per form

- **GIVEN** role `role-a` violates policy `policy-p` and a form is created
- **WHEN** the handler persists per-form output
- **THEN** it SHALL call persist with identity `` `${requestId}:role-a:policy-p` ``
- **AND** child output SHALL include `access-sod-remediation:form-url`, `access-sod-remediation:access-item-id`, `access-sod-remediation:access-item-type`, `access-sod-remediation:access-item-name`, `access-sod-remediation:policy-id`, `access-sod-remediation:policy-name`, `access-sod-remediation:recipient-id`, `access-sod-remediation:form-email-header`, `access-sod-remediation:form-email-body`, and `access-sod-remediation:form-email-recipients`

#### Scenario: Form cap per invocation

- **GIVEN** the scan would create more than 100 forms
- **WHEN** the handler reaches the 100-form limit
- **THEN** it SHALL stop creating additional forms
- **AND** SHALL log a warning indicating the cap was reached

#### Scenario: Auto-discovery registration

- **GIVEN** `src/operations/access-sod-remediation/index.ts` declares `command: 'custom:access-sod-remediation'` on its OperationSignature interface
- **WHEN** codegen runs
- **THEN** `custom:access-sod-remediation` SHALL be registered in auto-registry.ts and listed in connector-spec.json commands
