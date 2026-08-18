# connector-operations/access-model-sod-remediation Specification

## Purpose

Proactive catalog hygiene: scan enabled roles and/or access profiles in scope, detect intrinsic SoD policy violations by entitlement intersection, and create standalone remediation forms for policy owners. Distinct from `custom:sod-remediation`, which remediates existing identity violations.

## Requirements

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

### Requirement: Access model SOD remediation form email notification outputs

The access-model-sod-remediation operation SHALL persist workflow-oriented email fields on each child result-source identity when a remediation form is created. Recipient emails SHALL be persisted as a multi-value string array suitable for ISC Send Email `recipientEmailList` consumption.

#### Scenario: Child persist includes form email fields

- **GIVEN** role `role-a` violates policy `policy-p` and a form is created
- **WHEN** the handler persists per-form output on child identity `` `${requestId}:role-a:policy-p` ``
- **THEN** child output SHALL include `access-model-sod-remediation:form-email-header`, `access-model-sod-remediation:form-email-body`, and `access-model-sod-remediation:form-email-recipients`

#### Scenario: Policy owner email as recipients array

- **GIVEN** policy `policy-p` owner identity `owner-z` resolves to email `owner-z@example.com`
- **WHEN** a form is created for a violation of `policy-p`
- **THEN** persisted output `access-model-sod-remediation:form-email-recipients` SHALL be `['owner-z@example.com']`

#### Scenario: Recipients attribute is multi-value string

- **GIVEN** a successful child persist for access-model-sod-remediation
- **WHEN** operation output schema is inferred for account aggregation
- **THEN** `access-model-sod-remediation:form-email-recipients` SHALL be typed `string[]` with account schema `STRING` and `isMulti: true`

### Requirement: Intrinsic policy violation detection

The access-model-sod-remediation operation SHALL detect violations by expanding each access item to entitlement ids and testing intersection with both sides of each policy definition. Side membership SHALL be resolved from `policyQuery` when parseable, with fallback to `conflictingAccessCriteria`.

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

### Requirement: Child persist account idempotency

The access-model-sod-remediation operation SHALL skip form launch and child persist for a violation when a result-source account already exists on the operation source for child persist identity `` `${requestId}:{accessItemId}:{policyId}` ``. The handler SHALL NOT search form instances for scan idempotency. When skipping, the handler SHALL increment `access-model-sod-remediation:forms-skipped` in the final `ctx.res.send` summary and SHALL NOT overwrite the existing child account.

#### Scenario: Existing child account skips form and persist

- **GIVEN** invoke `requestId` `scan-001` detects violation for access item `role-r` and policy `policy-p`
- **AND** a result-source account already exists with native identity `scan-001:role-r:policy-p`
- **WHEN** the scan evaluates that violation on the same invoke or a retry with `requestId` `scan-001`
- **THEN** the handler SHALL NOT create a form instance for that violation
- **AND** SHALL NOT call persist for identity `scan-001:role-r:policy-p`
- **AND** SHALL increment `access-model-sod-remediation:forms-skipped` in the final `ctx.res.send` summary

#### Scenario: Different parent request does not skip

- **GIVEN** invoke `requestId` `scan-002` detects violation for access item `role-r` and policy `policy-p`
- **AND** a result-source account exists with native identity `scan-001:role-r:policy-p`
- **WHEN** the scan runs with `requestId` `scan-002`
- **THEN** the handler SHALL create a new form instance for the violation
- **AND** SHALL NOT increment `access-model-sod-remediation:forms-skipped` for that violation solely because of the `scan-001` child account

#### Scenario: No form instance search for idempotency

- **GIVEN** a connected scan evaluates one or more violations
- **WHEN** child persist account idempotency runs
- **THEN** the handler SHALL NOT call `searchFormInstancesByTenantV1` for dedupe purposes

#### Scenario: Offline bypass unchanged

- **GIVEN** invoke runs in offline or test mode without live account lookup
- **WHEN** the scan evaluates violations
- **THEN** the handler SHALL NOT perform child persist account lookup for idempotency
- **AND** SHALL follow existing offline fixture behavior

### Requirement: Access model SOD remediation form launch

The access-model-sod-remediation operation SHALL ensure a shared form definition by `formName`, populate launch-time `formInput` with access item and policy context plus group entitlement id lists and HTML summaries, and create standalone form instances for the policy owner. The form SHALL expose Correct-only side selection without an action selector or Mitigate path. Launch-time `formInput` SHALL include `parentRequestId` set to the scan invoke `requestId` (declared in the form definition, no UI element).

#### Scenario: Form recipient is policy owner

- **GIVEN** policy `policy-p` has `ownerRef` identity `owner-z`
- **WHEN** a form is created for a violation of `policy-p`
- **THEN** the form instance recipient SHALL be identity `owner-z`

#### Scenario: Form input carries access item context

- **GIVEN** role `role-r` named `Finance Role` violates policy `policy-p` named `AP/AR Separation`
- **WHEN** the form instance is created
- **THEN** `formInput` SHALL include `accessItemId` `role-r`, `accessItemType` `ROLE`, `accessItemName` `Finance Role`, `policyId` `policy-p`, and `policyName` `AP/AR Separation`
- **AND** the role SHALL NOT appear as a line item in group A or group B HTML columns

#### Scenario: Form input carries parent request id

- **GIVEN** invoke `requestId` `scan-parent-1` creates a remediation form for a violation
- **WHEN** the form instance is created
- **THEN** `formInput.parentRequestId` SHALL be `scan-parent-1`
- **AND** `parentRequestId` SHALL be declared in the form definition `formInput` without a corresponding form element

#### Scenario: Group ids are entitlement ids only

- **GIVEN** a violating access item with group intersections `ent-a` and `ent-c`
- **WHEN** the form instance is created
- **THEN** `formInput.groupAIds` SHALL be `['ent-a']`
- **AND** `formInput.groupBIds` SHALL be `['ent-c']`
- **AND** nested access profile ids SHALL NOT appear in group id lists even when HTML groups entitlements under an AP label

#### Scenario: Form submit returns remediation side

- **GIVEN** a submitted form with `formData.remediationSide` set to `groupA`
- **WHEN** a downstream workflow applies the decision
- **THEN** it SHALL invoke `custom:access-model-sod-remediation-apply` with `formInstanceId` only
- **AND** the correct operation SHALL interpret `groupAIds` from `formInput` to detach nested access profiles or remove direct role entitlements per side entitlement ids
- **AND** the form SHALL NOT include `formData.action` or Mitigate fields

#### Scenario: Idempotent form creation

- **GIVEN** invoke `requestId` `scan-parent-1` detects violation for access item `role-r` and policy `policy-p`
- **AND** a result-source account already exists with native identity `scan-parent-1:role-r:policy-p`
- **WHEN** the scan detects the same violation again for `scan-parent-1`
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

### Requirement: Access model SOD group column HTML styling

The access-model-sod-remediation operation SHALL render group A and group B entitlement columns using shared sod-form-html builders. Columns SHALL use type tags and selection-gated outcome panels. The operation SHALL NOT render revocability emojis or an emoji legend.

#### Scenario: Six group HTML formInput fields

- **WHEN** `custom:access-model-sod-remediation` assembles form input for a violation
- **THEN** formInput SHALL include `groupAContentsHtml`, `groupAContentsHtmlAsKept`, `groupAContentsHtmlAsRemoved`, `groupBContentsHtml`, `groupBContentsHtmlAsKept`, and `groupBContentsHtmlAsRemoved`
- **AND** plain variants SHALL NOT include outcome panel wrappers

#### Scenario: Flat access profile lines with offending entitlement mention

- **GIVEN** a violating role with entitlements granted via nested access profiles on a policy side
- **WHEN** group column HTML is rendered
- **THEN** each nested access profile on that side SHALL appear as a single flat list row
- **AND** the row SHALL include an offending entitlement mention naming the side-matching entitlement display names
- **AND** nested entitlement bullets under the access profile SHALL NOT be used
- **AND** direct role entitlements on that side SHALL remain single flat entitlement rows with type tags

#### Scenario: Outcome panels apply to whole access profile rows

- **GIVEN** group column HTML includes a flat access profile line on Group B
- **WHEN** the recipient selects `remediationSide` value `groupA`
- **THEN** the entire Group B access profile row SHALL appear in the green kept outcome panel variant
- **AND** SHALL NOT apply outcome styling only to a nested entitlement sub-row

#### Scenario: Plain variants before selection

- **GIVEN** the bundled access-model-sod-remediation seed with formConditions for group columns
- **WHEN** the recipient has not selected `remediationSide`
- **THEN** plain `groupAContentsHtml` and `groupBContentsHtml` SHALL be visible
- **AND** outcome panel variants SHALL be hidden

#### Scenario: Outcome panels after side selection

- **GIVEN** the recipient selects `remediationSide` value `groupA`
- **WHEN** formConditions evaluate
- **THEN** Group A SHALL display `groupAContentsHtmlAsRemoved` with red outcome panel styling
- **AND** Group B SHALL display `groupBContentsHtmlAsKept` with green outcome panel styling

#### Scenario: No side-identity colored panels

- **WHEN** group column HTML is rendered for access-model-sod-remediation
- **THEN** the output SHALL NOT use always-on blue or purple side-identity panel backgrounds
- **AND** colored backgrounds SHALL appear only in asKept or asRemoved variants after selection

#### Scenario: No emojis on access catalog form

- **WHEN** access-model-sod-remediation group HTML is rendered
- **THEN** lines SHALL NOT include revocability, keep, or privileged emoji suffixes
- **AND** SHALL NOT include an emoji legend footer

#### Scenario: Side-by-side column layout preserved

- **GIVEN** the bundled access-model-sod-remediation seed
- **WHEN** the Correct section is inspected
- **THEN** Group A and Group B contents SHALL remain in a two-column COLUMN_SET layout
