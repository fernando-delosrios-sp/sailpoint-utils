## MODIFIED Requirements

### Requirement: Access model SOD remediation scan operation

The connector SHALL register a custom command `custom:access-model-sod-remediation` that scans enabled roles and/or access profiles in scope, detects intrinsic SoD policy violations by entitlement intersection against policy side definitions, and creates standalone remediation form instances for access item owners. Implementation SHALL reside under `src/operations/access-model-sod-remediation/` with entry module `index.ts`. The operation SHALL NOT use the SoD predict API.

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

- **GIVEN** violating access item `role-a` has primary owner identity `item-owner-1` resolving to email `item-owner-1@example.com`
- **AND** policy `policy-p` owner identity resolves to a different email
- **WHEN** a form is created for that violation of `policy-p`
- **THEN** persisted output `access-model-sod-remediation:form-email-recipients` SHALL be `['item-owner-1@example.com']`
- **AND** SHALL NOT use the SoD policy owner email as the recipients array value

#### Scenario: Recipients attribute is multi-value string

- **GIVEN** a successful child persist for access-model-sod-remediation
- **WHEN** operation output schema is inferred for account aggregation
- **THEN** `access-model-sod-remediation:form-email-recipients` SHALL be typed `string[]` with account schema `STRING` and `isMulti: true`

### Requirement: Access model SOD remediation form launch

The access-model-sod-remediation operation SHALL ensure a shared form definition by `formName`, populate launch-time `formInput` with access item and policy context plus group entitlement id lists and HTML summaries, and create standalone form instances for the access item owner. The form SHALL expose Correct-only side selection without an action selector or Mitigate path. Launch-time `formInput` SHALL include `parentRequestId` set to the scan invoke `requestId` (declared in the form definition, no UI element).

#### Scenario: Form recipient is policy owner

- **GIVEN** role `role-a` has primary owner identity `item-owner-1`
- **AND** policy `policy-p` has `ownerRef` identity `policy-owner-z`
- **WHEN** a form is created for a violation of `policy-p` on `role-a`
- **THEN** the form instance recipient SHALL be identity `item-owner-1`
- **AND** SHALL NOT be identity `policy-owner-z`

#### Scenario: Missing access item owner fails form launch

- **GIVEN** a detected violation whose access item has no primary owner identity id
- **WHEN** the handler attempts to create the remediation form
- **THEN** that form launch SHALL fail
- **AND** the scan SHALL continue for remaining violations
- **AND** `access-model-sod-remediation:forms-launch-failed` SHALL increment in the final `ctx.res.send` summary

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

### Requirement: Access model context panel HTML

The access-model-sod-remediation operation SHALL assemble launch-time `situationSummaryHtml` for in-form DESCRIPTION rendering. The summary SHALL use the same “What we found” / “What we need from you” structure as sod-remediation context panels. When UI origin is available, the summary SHALL link the access item and policy display names to ISC admin UI routes. The bundled seed SHALL interpolate `situationSummaryHtml` in a single context-panel DESCRIPTION and SHALL NOT rely on static-only access item metadata for situation explanation.

#### Scenario: Form input includes situationSummaryHtml

- **WHEN** `custom:access-model-sod-remediation` creates a form instance
- **THEN** `formInput` SHALL include `situationSummaryHtml` with HTML suitable for DESCRIPTION interpolation

#### Scenario: Linked access item and policy

- **GIVEN** UI origin is available, role id `role-r`, and policy id `policy-p`
- **WHEN** `situationSummaryHtml` is assembled
- **THEN** the access item display name SHALL link to the role admin UI route
- **AND** the policy display name SHALL link to the SoD policy admin UI route

#### Scenario: Access profile item links correctly

- **GIVEN** UI origin is available and violating access item type is `ACCESS_PROFILE`
- **WHEN** `situationSummaryHtml` is assembled
- **THEN** the access item display name SHALL link to the access profile admin UI route

#### Scenario: Call to action for policy owner

- **WHEN** `situationSummaryHtml` is assembled
- **THEN** the “What we need from you” block SHALL instruct the recipient to select which side’s entitlements to remove from the access item definition

#### Scenario: Offline context panel omits links

- **GIVEN** invoke runs without `apiUrl`
- **WHEN** `situationSummaryHtml` is assembled
- **THEN** names SHALL render as plain escaped text without admin links

#### Scenario: Seed single context DESCRIPTION

- **GIVEN** the bundled access-model-sod-remediation seed
- **WHEN** the context section is inspected
- **THEN** exactly one DESCRIPTION element SHALL interpolate `{{$.form.input.situationSummaryHtml}}`
- **AND** the seed SHALL NOT define static-only element id `ctx-item` for situation content
