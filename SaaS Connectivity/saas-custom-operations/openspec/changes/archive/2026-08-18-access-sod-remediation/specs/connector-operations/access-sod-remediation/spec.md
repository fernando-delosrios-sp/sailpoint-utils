## ADDED Requirements

### Requirement: Access SOD remediation scan operation

The connector SHALL register a custom command `custom:access-sod-remediation` that scans enabled roles and/or access profiles in scope, detects intrinsic SoD policy violations by entitlement intersection against policy side definitions, and creates standalone remediation form instances for policy owners. Implementation SHALL reside under `src/operations/access-sod-remediation/` with entry module `index.ts`. The operation SHALL NOT use the SoD predict API.

#### Scenario: Operation invoked with required formName

- **GIVEN** `custom:access-sod-remediation` is declared in connector-spec.json and registered
- **WHEN** ISC invokes the command with input containing `formName` and standard `requestId`
- **THEN** the handler SHALL list access items per `searchIndices`, evaluate each against policies matching `policyScope`, create remediation forms for violations, persist parent rollup on `requestId`, and persist per-form output on child identities `` `${requestId}:${accessItemId}:${policyId}` ``

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
- **AND** child output SHALL include `access-sod-remediation:form-url`, `access-sod-remediation:access-item-id`, `access-sod-remediation:access-item-type`, `access-sod-remediation:access-item-name`, `access-sod-remediation:policy-id`, `access-sod-remediation:policy-name`, and `access-sod-remediation:recipient-id`

#### Scenario: Form cap per invocation

- **GIVEN** the scan would create more than 100 forms
- **WHEN** the handler reaches the 100-form limit
- **THEN** it SHALL stop creating additional forms
- **AND** SHALL log a warning indicating the cap was reached

#### Scenario: Auto-discovery registration

- **GIVEN** `src/operations/access-sod-remediation/index.ts` declares `command: 'custom:access-sod-remediation'` on its OperationSignature interface
- **WHEN** codegen runs
- **THEN** `custom:access-sod-remediation` SHALL be registered in auto-registry.ts and listed in connector-spec.json commands

### Requirement: Intrinsic policy violation detection

The access-sod-remediation operation SHALL detect violations by expanding each access item to entitlement ids and testing intersection with both sides of each policy definition. Side membership SHALL be resolved from `policyQuery` when parseable, with fallback to `conflictingAccessCriteria`.

#### Scenario: policyQuery AND separates sides

- **GIVEN** a policy with `policyQuery` `@access(id:ent-a OR id:ent-b) AND @access(id:ent-c OR id:ent-d)`
- **AND** access item entitlements include `ent-a` and `ent-c`
- **WHEN** violation detection runs
- **THEN** the item SHALL be flagged as violating that policy
- **AND** `groupAIds` SHALL include `ent-a`
- **AND** `groupBIds` SHALL include `ent-c`

#### Scenario: No violation when only one side matches

- **GIVEN** a policy with sides `{ent-a}` and `{ent-c}`
- **AND** access item entitlements include only `ent-a`
- **WHEN** violation detection runs
- **THEN** the item SHALL NOT be flagged as violating that policy

#### Scenario: conflictingAccessCriteria fallback

- **GIVEN** a policy with missing or unparseable `policyQuery`
- **AND** `conflictingAccessCriteria.leftCriteria` entitlements `{ent-a}` and `conflictingAccessCriteria.rightCriteria` entitlements `{ent-c}`
- **WHEN** violation detection runs
- **THEN** sides SHALL be resolved from structured criteria

#### Scenario: Role expansion includes nested AP entitlements

- **GIVEN** role `role-r` contains access profile `ap-x` whose entitlements include `ent-c`
- **AND** role direct entitlements include `ent-a`
- **AND** a policy requires `ent-a` on side A and `ent-c` on side B
- **WHEN** role `role-r` is evaluated
- **THEN** the role SHALL be flagged as violating that policy

#### Scenario: Independent role and AP evaluation

- **GIVEN** role `role-r` contains access profile `ap-x`
- **AND** both `role-r` and `ap-x` are in scope via `searchIndices`
- **WHEN** the scan completes
- **THEN** each access item SHALL be evaluated independently
- **AND** separate forms MAY be created for role and AP violations of the same policy

### Requirement: Access SOD remediation form launch

The access-sod-remediation operation SHALL ensure a shared form definition by `formName`, populate launch-time `formInput` with access item and policy context plus group entitlement id lists and HTML summaries, and create standalone form instances for the policy owner. The form SHALL expose Correct-only side selection without an action selector or Mitigate path.

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
- **AND** SHALL increment `access-sod-remediation:forms-skipped` on the parent persist

#### Scenario: No sod-remediation violation fields

- **GIVEN** a successful form launch
- **WHEN** the handler completes
- **THEN** operation output SHALL NOT require `violationId`, `sod-remediation:*` fields, or compensating control options

### Requirement: Access SOD remediation offline invoke

The access-sod-remediation operation SHALL support offline/testMode invocation with deterministic canned policies, access items, and form responses suitable for local `call:op` testing.

#### Scenario: Offline scan produces parent and child persist

- **GIVEN** invoke runs without `apiUrl` and `token` (or testMode)
- **WHEN** `custom:access-sod-remediation` completes
- **THEN** the handler SHALL use offline fixtures
- **AND** SHALL persist parent rollup and at least one child form output without live ISC API calls
