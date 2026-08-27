## ADDED Requirements

### Requirement: Access model scan summary on invoke response

The access-model-sod-remediation operation SHALL return scan rollup counters on the successful command response via `ctx.res.send`. The handler SHALL NOT persist rollup counters on result-source identity `requestId`.

#### Scenario: Successful scan returns summary on res.send

- **GIVEN** a scan evaluates 50 access items and finds 3 violations creating 3 forms (2 skipped by idempotency)
- **WHEN** the handler completes successfully
- **THEN** `ctx.res.send` SHALL be called with `status: 'success'`
- **AND** the payload SHALL include `access-model-sod-remediation:access-items-scanned` equal to 50
- **AND** `access-model-sod-remediation:violations-found` equal to 3
- **AND** `access-model-sod-remediation:forms-skipped` equal to 2
- **AND** the handler SHALL NOT call `ctx.persist` with identity `requestId` for rollup counters

#### Scenario: Zero violations summary only

- **GIVEN** a scan evaluates 10 access items and finds no violations
- **WHEN** the handler completes successfully
- **THEN** `ctx.res.send` SHALL include `access-model-sod-remediation:access-items-scanned` equal to 10
- **AND** `access-model-sod-remediation:violations-found` equal to 0
- **AND** SHALL NOT persist any result-source account on identity `requestId`

#### Scenario: Optional failure counter on res.send

- **GIVEN** a scan creates forms where at least one child persist fails
- **WHEN** the handler completes successfully
- **THEN** `ctx.res.send` SHALL include `access-model-sod-remediation:forms-persist-failed` equal to the failure count
- **AND** SHALL omit `access-model-sod-remediation:forms-persist-failed` when the count is zero

---

## MODIFIED Requirements

### Requirement: Access model SOD remediation scan operation

The connector SHALL register a custom command `custom:access-model-sod-remediation` that scans enabled roles and/or access profiles in scope, detects intrinsic SoD policy violations by entitlement intersection against policy side definitions, and creates standalone remediation form instances for policy owners. Implementation SHALL reside under `src/operations/access-model-sod-remediation/` with entry module `index.ts`. The operation SHALL NOT use the SoD predict API.

#### Scenario: Operation invoked with required formName

- **GIVEN** `custom:access-model-sod-remediation` is declared in connector-spec.json and registered
- **WHEN** ISC invokes the command with input containing `formName` and standard `requestId`
- **THEN** the handler SHALL list access items per `searchIndices`, evaluate each against policies matching `policyScope`, create remediation forms for violations, return scan rollup counters via `ctx.res.send`, and persist per-form output on child identities `` `${requestId}:${accessItemId}:${policyId}` ``

#### Scenario: Default scope and searchIndices

- **GIVEN** input omits `scope` and `searchIndices`
- **WHEN** the handler discovers access items
- **THEN** `scope` SHALL default to `"*"` (no additional search filter)
- **AND** `searchIndices` SHALL default to `['accessprofiles', 'roles']`
- **AND** only enabled roles and access profiles SHALL be included

#### Scenario: searchIndices validation

- **GIVEN** input includes `searchIndices` with a value other than `accessprofiles` and/or `roles`
- **WHEN** `custom:access-model-sod-remediation` executes
- **THEN** the handler SHALL fail with ConnectorError indicating invalid search index values

#### Scenario: Non-wildcard scope filter

- **GIVEN** input includes `scope` set to `name sw "SAP-"`
- **WHEN** the handler lists roles and access profiles
- **THEN** the list APIs SHALL apply the scope string as an additional filter alongside the enabled filter

#### Scenario: Default policyScope

- **GIVEN** input omits `policyScope`
- **WHEN** the handler loads SoD policies
- **THEN** policies SHALL be filtered with `state eq "ENFORCED"`

#### Scenario: Scan summary on invoke response

- **GIVEN** a scan evaluates 50 access items and finds 3 violations creating 3 forms (2 skipped by idempotency)
- **WHEN** the handler completes
- **THEN** `ctx.res.send` SHALL include `access-model-sod-remediation:access-items-scanned` equal to 50
- **AND** `access-model-sod-remediation:violations-found` equal to 3
- **AND** `access-model-sod-remediation:forms-skipped` equal to 2
- **AND** SHALL NOT persist rollup counters on identity `requestId`
- **AND** SHALL NOT persist `access-model-sod-remediation:forms-created`

#### Scenario: Parent persist rollup

- **GIVEN** a scan evaluates 50 access items and finds 3 violations creating 3 forms (2 skipped by idempotency)
- **WHEN** the handler completes
- **THEN** `ctx.res.send` SHALL include `access-model-sod-remediation:access-items-scanned` equal to 50
- **AND** `access-model-sod-remediation:violations-found` equal to 3
- **AND** `access-model-sod-remediation:forms-skipped` equal to 2
- **AND** SHALL NOT persist rollup counters on identity `requestId`
- **AND** SHALL NOT persist `access-model-sod-remediation:forms-created`

#### Scenario: Child persist per form

- **GIVEN** role `role-a` violates policy `policy-p` and a form is created
- **WHEN** the handler persists per-form output
- **THEN** it SHALL call persist with identity `` `${requestId}:role-a:policy-p` ``
- **AND** child output SHALL include `access-model-sod-remediation:form-url`, `access-model-sod-remediation:access-item-id`, `access-model-sod-remediation:access-item-type`, `access-model-sod-remediation:access-item-name`, `access-model-sod-remediation:policy-id`, `access-model-sod-remediation:policy-name`, `access-model-sod-remediation:recipient-id`, `access-model-sod-remediation:form-email-header`, `access-model-sod-remediation:form-email-body`, and `access-model-sod-remediation:form-email-recipients`

#### Scenario: Form cap per invocation

- **GIVEN** the scan would create more than 100 forms
- **WHEN** the handler reaches the 100-form limit
- **THEN** it SHALL stop creating additional forms
- **AND** SHALL log a warning indicating the cap was reached

#### Scenario: Auto-discovery registration

- **GIVEN** `src/operations/access-model-sod-remediation/index.ts` declares `command: 'custom:access-model-sod-remediation'` on its OperationSignature interface
- **WHEN** codegen runs
- **THEN** `custom:access-model-sod-remediation` SHALL be registered in auto-registry.ts and listed in connector-spec.json commands

### Requirement: Access model SOD remediation form launch

The access-model-sod-remediation operation SHALL ensure a shared form definition by `formName`, populate launch-time `formInput` with access item and policy context plus group entitlement id lists and HTML summaries, and create standalone form instances for the policy owner. The form SHALL expose Correct-only side selection without an action selector or Mitigate path.

#### Scenario: Form recipient is policy owner

- **GIVEN** policy `policy-p` has `ownerRef` identity `owner-z`
- **WHEN** a form is created for a violation of `policy-p`
- **THEN** the form instance recipient SHALL be identity `owner-z`

#### Scenario: Form input carries access item context

- **GIVEN** role `role-r` named `Finance Role` violates policy `policy-p` named `AP/AR Separation`
- **WHEN** the form instance is created
- **THEN** `formInput` SHALL include `accessItemId` `role-r`, `accessItemType` `ROLE`, `accessItemName` `Finance Role`, `policyId` `policy-p`, and `policyName` `AP/AR Separation`
- **AND** the role SHALL NOT appear as a line item in group A or group B HTML columns

#### Scenario: Group ids are entitlement ids only

- **GIVEN** a violating access item with group intersections `ent-a` and `ent-c`
- **WHEN** the form instance is created
- **THEN** `formInput.groupAIds` SHALL be `['ent-a']`
- **AND** `formInput.groupBIds` SHALL be `['ent-c']`
- **AND** nested access profile ids SHALL NOT appear in group id lists even when HTML groups entitlements under an AP label

#### Scenario: Form submit returns remediation side

- **GIVEN** a submitted form with `formData.remediationSide` set to `groupA`
- **WHEN** a downstream workflow reads the form instance
- **THEN** it SHALL use `groupAIds` from `formInput` to determine entitlements to remove from the access item definition
- **AND** the form SHALL NOT include `formData.action` or Mitigate fields

#### Scenario: Idempotent form creation

- **GIVEN** an ASSIGNED standalone form instance already exists for form definition `{formName}` with `formInput.accessItemId` `role-r` and `formInput.policyId` `policy-p`
- **WHEN** the scan detects the same violation again
- **THEN** the handler SHALL NOT create a duplicate form instance
- **AND** SHALL increment `access-model-sod-remediation:forms-skipped` in the final `ctx.res.send` summary

#### Scenario: No sod-remediation violation fields

- **GIVEN** a successful form launch
- **WHEN** the handler completes
- **THEN** operation output SHALL NOT require `violationId`, `sod-remediation:*` fields, or compensating control options

### Requirement: Access model SOD remediation offline invoke

The access-model-sod-remediation operation SHALL support offline/testMode invocation with deterministic canned policies, access items, and form responses suitable for local `call:op` testing.

#### Scenario: Offline scan produces parent and child persist

- **GIVEN** invoke runs without `apiUrl` and `token` (or testMode)
- **WHEN** `custom:access-model-sod-remediation` completes
- **THEN** the handler SHALL use offline fixtures
- **AND** SHALL return scan rollup counters via `ctx.res.send`
- **AND** SHALL persist at least one child form output without live ISC API calls when violations are detected
- **AND** SHALL NOT persist rollup counters on identity `requestId`

---

## REMOVED Requirements

_(none)_
