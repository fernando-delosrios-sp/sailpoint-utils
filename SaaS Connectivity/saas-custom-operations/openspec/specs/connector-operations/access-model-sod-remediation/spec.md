# connector-operations/access-model-sod-remediation Specification

## Purpose

Proactive catalog hygiene: scan enabled roles and/or access profiles in scope, detect intrinsic SoD policy violations by entitlement intersection, and create standalone remediation forms for access item owners; when `formInstanceId` is set, apply a completed form decision to the ISC catalog. Distinct from `custom:sod-remediation`, which remediates existing identity violations.
## Requirements
### Requirement: Access model scan summary on invoke response

The access-model-sod-remediation operation SHALL return scan rollup counters on the successful command response via `ctx.res.send` as the operation response envelope `summary`. The handler SHALL NOT persist rollup counters on result-source identity `requestId`. The scan-summary counters SHALL be declared under `OperationSignature['response']` and SHALL NOT be declared in `OperationSignature['output']`; consequently they SHALL NOT appear as attributes on the result-source account schema. Only persisted child attributes SHALL be declared in `output`.

#### Scenario: Successful scan returns summary on res.send

- **GIVEN** a scan evaluates 50 access items and finds 3 violations creating 3 forms (2 skipped by idempotency)
- **WHEN** the handler completes successfully
- **THEN** `ctx.res.send` SHALL be called with `status: 'success'`
- **AND** `payload.summary['access-model-sod-remediation:access-items-scanned']` SHALL equal 50
- **AND** `payload.summary['access-model-sod-remediation:violations-found']` SHALL equal 3
- **AND** `payload.summary['access-model-sod-remediation:forms-skipped']` SHALL equal 2
- **AND** the handler SHALL NOT call `ctx.persist` with identity `requestId` for rollup counters

#### Scenario: Zero violations summary only

- **GIVEN** a scan evaluates 10 access items and finds no violations
- **WHEN** the handler completes successfully
- **THEN** `payload.summary['access-model-sod-remediation:access-items-scanned']` SHALL equal 10
- **AND** `payload.summary['access-model-sod-remediation:violations-found']` SHALL equal 0
- **AND** SHALL NOT persist any result-source account on identity `requestId`

#### Scenario: Optional failure counter on res.send

- **GIVEN** a scan creates forms where at least one child persist fails
- **WHEN** the handler completes successfully
- **THEN** `payload.summary['access-model-sod-remediation:forms-persist-failed']` SHALL equal the failure count
- **AND** SHALL omit `payload.summary['access-model-sod-remediation:forms-persist-failed']` when the count is zero

#### Scenario: Scan-summary counters excluded from output and account schema

- **GIVEN** the operation declares scan-summary counters `access-items-scanned`, `violations-found`, `forms-skipped`, `forms-launch-failed`, and `forms-persist-failed`
- **WHEN** its `OperationSignature` is authored and codegen derives the account schema
- **THEN** these counters SHALL be declared under `response`
- **AND** SHALL NOT be declared under `output`
- **AND** SHALL NOT appear as attributes on the result-source account schema
- **AND** the persist-output guard SHALL pass for the operation

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
- **THEN** it SHALL invoke `custom:access-model-sod-remediation-apply` with `formInstanceId` and the same `formName` used by the scan
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

The access-model-sod-remediation operation SHALL render group A and group B entitlement columns using shared sod-form-html builders. Columns SHALL use type tags and selection-gated outcome panels. When UI origin is available, line display names SHALL link to ISC admin UI routes. The operation SHALL NOT render revocability emojis or an emoji legend in group column HTML.

#### Scenario: Six group HTML formInput fields

- **WHEN** `custom:access-model-sod-remediation` assembles form input for a violation
- **THEN** formInput SHALL include `groupColumnsHtmlPlain`, `groupColumnsHtmlWhenGroupARemoved`, and `groupColumnsHtmlWhenGroupBRemoved`
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
- **THEN** plain group column HTML SHALL be visible
- **AND** outcome panel variants SHALL be hidden

#### Scenario: Outcome panels after side selection

- **GIVEN** the recipient selects `remediationSide` value `groupA`
- **WHEN** formConditions evaluate
- **THEN** Group A SHALL display removed outcome panel styling
- **AND** Group B SHALL display kept outcome panel styling

#### Scenario: No side-identity colored panels

- **WHEN** group column HTML is rendered for access-model-sod-remediation
- **THEN** the output SHALL NOT use always-on blue or purple side-identity panel backgrounds
- **AND** colored backgrounds SHALL appear only in asKept or asRemoved variants after selection

#### Scenario: No emojis on access catalog form

- **WHEN** access-model-sod-remediation group column HTML is rendered
- **THEN** lines SHALL NOT include revocability, keep, or privileged emoji suffixes
- **AND** group column HTML SHALL NOT include an emoji legend footer

#### Scenario: Linked column line names when online

- **GIVEN** UI origin is available
- **WHEN** group column HTML is rendered
- **THEN** entitlement and access profile display names SHALL be wrapped in the corresponding ISC admin UI links

#### Scenario: Side-by-side column layout preserved

- **GIVEN** the bundled access-model-sod-remediation seed
- **WHEN** the Correct section is inspected
- **THEN** Group A and Group B contents SHALL remain in a side-by-side two-column layout

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

### Requirement: Optional disableLinks input for access-model SOD remediation

The access-model-sod-remediation operation SHALL accept an optional boolean input `disableLinks`. When `disableLinks` is `true`, the handler SHALL omit UI origin for form HTML assembly so ISC UI links are not rendered in `situationSummaryHtml` or group column HTML, even when invoke `apiUrl` would otherwise resolve a UI origin. When `disableLinks` is omitted or `false`, link behavior SHALL match existing rules (links when UI origin is available). The flag SHALL NOT remove `access-model-sod-remediation:form-url` or the remediation form CTA from `access-model-sod-remediation:form-email-body`.

#### Scenario: Omitted disableLinks keeps admin links online

- **GIVEN** invoke has resolvable `apiUrl` and input omits `disableLinks`
- **WHEN** form HTML is assembled for a violation
- **THEN** `situationSummaryHtml` and group column HTML SHALL include ISC UI links for linked entity display names

#### Scenario: disableLinks false keeps admin links online

- **GIVEN** invoke has resolvable `apiUrl` and input sets `disableLinks` to `false`
- **WHEN** form HTML is assembled for a violation
- **THEN** `situationSummaryHtml` and group column HTML SHALL include ISC UI links for linked entity display names

#### Scenario: disableLinks true omits admin links online

- **GIVEN** invoke has resolvable `apiUrl` and input sets `disableLinks` to `true`
- **WHEN** form HTML is assembled for a violation
- **THEN** entity display names in `situationSummaryHtml` and group column HTML SHALL render as plain escaped text
- **AND** those fields SHALL NOT include ISC admin UI `<a href=` anchors

#### Scenario: disableLinks does not remove form URL or email CTA

- **GIVEN** input sets `disableLinks` to `true` and a remediation form is created
- **WHEN** the handler persists child form output
- **THEN** child output SHALL still include `access-model-sod-remediation:form-url`
- **AND** `access-model-sod-remediation:form-email-body` SHALL still include the remediation form CTA link

### Requirement: Access model SOD remediation apply branch

When invoke input includes a non-empty `formInstanceId`, `custom:access-model-sod-remediation` SHALL run the catalog apply path and SHALL NOT scan roles, access profiles, or SoD policies. When `formInstanceId` is omitted or blank, the handler SHALL run the scan path.

#### Scenario: formInstanceId selects apply

- **GIVEN** invoke includes `formInstanceId` `fi-1` and `formName`
- **WHEN** `custom:access-model-sod-remediation` executes
- **THEN** the handler SHALL apply the completed form decision
- **AND** SHALL NOT list enabled roles or access profiles for a catalog scan

#### Scenario: omitted formInstanceId selects scan

- **GIVEN** invoke omits `formInstanceId` and includes `formName`
- **WHEN** `custom:access-model-sod-remediation` executes
- **THEN** the handler SHALL run the scan path


### Requirement: Access model SOD remediation apply path

When `formInstanceId` is set, `custom:access-model-sod-remediation` SHALL read a completed access-model SoD remediation form instance and mutates the referenced catalog access item. Implementation SHALL reside under `src/operations/access-model-sod-remediation/` with entry module `index.ts`.

#### Scenario: Command declared for codegen

- **GIVEN** `src/operations/access-model-sod-remediation/index.ts` declares `command: 'custom:access-model-sod-remediation'` and optional input `formInstanceId`
- **WHEN** codegen runs
- **THEN** `custom:access-model-sod-remediation` SHALL remain registered; `custom:access-model-sod-remediation-apply` SHALL NOT appear in auto-registry.ts or connector-spec.json commands

### Requirement: Access model SOD remediation apply form definition lookup by name

The apply path of access-model-sod-remediation SHALL resolve required input `formName` to a form definition id by searching existing tenant form definitions. The handler SHALL NOT call `ensureFormDefinitionByName` and SHALL NOT create or patch a form definition. When no definition matches `formName`, the handler SHALL fail with a validation error and SHALL NOT list form instances or invoke Roles or Access Profiles PATCH APIs.

#### Scenario: Name resolves to definition id then list

- **GIVEN** connected invoke with `formInstanceId` `fi-1` and `formName` `Access Model SOD Remediation`
- **AND** no prior terminal apply persist for `fi-1`
- **AND** form definition search returns id `fd-1` for that name
- **WHEN** `custom:access-model-sod-remediation` with `formInstanceId` loads the form instance
- **THEN** the handler SHALL call `searchFormDefinitionsByTenantV1` with filters equivalent to `name eq "Access Model SOD Remediation"`
- **AND** SHALL call `searchFormInstancesByTenantV1` with filters equivalent to `formDefinitionId eq "fd-1" and id eq "fi-1"`
- **AND** SHALL NOT call `ensureFormDefinitionByName`
- **AND** SHALL NOT call `getFormInstanceByKeyV1`

#### Scenario: Missing form definition by name

- **GIVEN** connected invoke with `formInstanceId` `fi-1` and `formName` `Unknown Form`
- **AND** no prior terminal apply persist for `fi-1`
- **AND** form definition search returns no matching definition
- **WHEN** `custom:access-model-sod-remediation` with `formInstanceId` loads the form instance
- **THEN** the handler SHALL fail with a validation error naming `formName`
- **AND** SHALL NOT call `searchFormInstancesByTenantV1`
- **AND** SHALL NOT invoke Roles or Access Profiles PATCH APIs

### Requirement: Access model SOD remediation apply form instance list and pick

The apply path of access-model-sod-remediation SHALL load the form instance by resolving `formName` to a **form definition id**, then searching tenant form instances filtered to that id and `formInstanceId` (`limit` 1). When the combined filter is rejected with HTTP 400, the handler SHALL fall back to listing by definition id and paginating until a match is found. The handler SHALL NOT call `getFormInstanceByKeyV1` (or `getFormInstanceById`) on the apply path. When a prior terminal apply persist exists for `{formInstanceId}`, the handler SHALL skip definition lookup and the instance list. When the instance is not found after the last page, the handler SHALL fail with a validation error and SHALL NOT invoke Roles or Access Profiles PATCH APIs.

#### Scenario: List filtered by form definition id

- **GIVEN** connected invoke with `formInstanceId` `fi-1` and `formName` that resolves to `fd-1`
- **AND** no prior terminal apply persist for `fi-1`
- **WHEN** `custom:access-model-sod-remediation` with `formInstanceId` loads the form instance
- **THEN** the handler SHALL call `searchFormInstancesByTenantV1` with filters equivalent to `formDefinitionId eq "fd-1" and id eq "fi-1"`
- **AND** SHALL NOT call `getFormInstanceByKeyV1`

#### Scenario: Instance found on a later page

- **GIVEN** the first list page for resolved definition `fd-1` does not include instance `fi-1`
- **AND** a later page includes instance `fi-1` with `formInput` and `formData`
- **WHEN** the handler paginates the tenant form instance list
- **THEN** it SHALL continue with offset/limit until `fi-1` is found
- **AND** SHALL parse that row as the form instance

#### Scenario: Missing instance after last page

- **GIVEN** connected invoke with `formInstanceId` `fi-missing` and `formName` that resolves to `fd-1`
- **AND** no listed instance has id `fi-missing`
- **WHEN** pagination completes
- **THEN** the handler SHALL fail with a validation error
- **AND** SHALL NOT invoke Roles or Access Profiles PATCH APIs

#### Scenario: Prior apply skips list

- **GIVEN** a prior terminal apply persist exists for `formInstanceId` `fi-1`
- **WHEN** `custom:access-model-sod-remediation` with `formInstanceId` is invoked with `fi-1` and a `formName`
- **THEN** the handler SHALL NOT call `searchFormDefinitionsByTenantV1`
- **AND** SHALL NOT call `searchFormInstancesByTenantV1`
- **AND** SHALL return `skipped-already-applied` per existing persist idempotency

### Requirement: Access model SOD remediation apply minimal input

The apply path of access-model-sod-remediation SHALL accept required input fields `formInstanceId` and `formName`. The handler SHALL load the form instance from the tenant form instance list after resolving `formName` and SHALL NOT require workflow pass-through of `formInput` or `formData` fields. The handler SHALL NOT accept `formDefinitionId` as an invoke input.

#### Scenario: Workflow invoke binding

- **GIVEN** a workflow Custom Command step after form completion
- **WHEN** the step invokes `custom:access-model-sod-remediation` with `formInstanceId`
- **THEN** input SHALL require `formInstanceId` from the form trigger
- **AND** SHALL require `formName` matching the scan operation's form definition name
- **AND** SHALL NOT require `formDefinitionId`
- **AND** SHALL NOT require workflow pass-through of `formInput` or `formData` fields

#### Scenario: Missing formName validation

- **GIVEN** invoke omits `formName` or supplies only whitespace
- **WHEN** `custom:access-model-sod-remediation` with `formInstanceId` executes
- **THEN** the handler SHALL fail with a validation error naming `formName`
- **AND** SHALL NOT call Custom Forms search APIs
- **AND** SHALL NOT invoke Roles or Access Profiles PATCH APIs

### Requirement: Access model SOD remediation apply form instance validation

The apply path of access-model-sod-remediation SHALL load the form instance via the Custom Forms tenant list and validate it before catalog mutation.

#### Scenario: Completed form required

- **GIVEN** form instance `fi-1` has state other than `COMPLETED`
- **WHEN** `custom:access-model-sod-remediation` with `formInstanceId` executes with `formInstanceId` `fi-1` and a resolvable `formName`
- **THEN** the handler SHALL fail with a validation error
- **AND** SHALL NOT invoke Roles or Access Profiles PATCH APIs

#### Scenario: Required launch and submit fields

- **GIVEN** a completed form instance with valid `formData.remediationSide` `groupA` or `groupB`
- **WHEN** the handler parses the instance
- **THEN** it SHALL read `formInput.accessItemId`, `formInput.accessItemType`, `formInput.policyId`, `formInput.policyName`, JSON-string `formInput.groupAIds`, and JSON-string `formInput.groupBIds`
- **AND** SHALL read optional `formData.comments`

### Requirement: Access model SOD remediation apply role remediation semantics

When `formInput.accessItemType` is `ROLE`, the access-model-sod-remediation-apply operation SHALL apply the selected side's entitlement ids by detaching nested access profiles from the role or removing direct role entitlements. The operation SHALL NOT patch entitlement lists on nested access profile definitions.

#### Scenario: Direct entitlement removed from role

- **GIVEN** completed form with `accessItemType` `ROLE`, `remediationSide` `groupA`, and `groupAIds` containing direct role entitlement `ent-a`
- **WHEN** `custom:access-model-sod-remediation` with `formInstanceId` applies the correction
- **THEN** the handler SHALL remove `ent-a` from the role entitlement list via role PATCH
- **AND** SHALL NOT patch nested access profile entitlement definitions

#### Scenario: Nested access profile detached from role

- **GIVEN** completed form with `accessItemType` `ROLE`, `remediationSide` `groupB`, and `groupBIds` containing entitlement `ent-c` granted only via nested access profile `ap-x` on the role
- **WHEN** `custom:access-model-sod-remediation` with `formInstanceId` applies the correction
- **THEN** the handler SHALL detach access profile `ap-x` from the role via role PATCH
- **AND** SHALL NOT remove `ent-c` from access profile `ap-x` entitlement list

### Requirement: Access model SOD remediation apply access profile remediation semantics

When `formInput.accessItemType` is `ACCESS_PROFILE`, the access-model-sod-remediation-apply operation SHALL remove selected-side entitlement ids from that access profile's entitlement list.

#### Scenario: Entitlements removed from access profile under review

- **GIVEN** completed form with `accessItemType` `ACCESS_PROFILE`, `accessItemId` `ap-v`, and `remediationSide` `groupA`
- **WHEN** `custom:access-model-sod-remediation` with `formInstanceId` applies the correction
- **THEN** the handler SHALL remove group A entitlement ids from access profile `ap-v` via access profile PATCH

### Requirement: Access model SOD remediation apply description audit

The apply path of access-model-sod-remediation SHALL append an audit line to the corrected catalog item description documenting the writing command, policy, remediation side, detached access profiles, removed entitlements, form instance id, and optional submitter comments. The audit line SHALL open with `[access-model-sod-remediation-apply {timestamp}]`, where `{timestamp}` is the ISO-8601 apply time. The label SHALL name the writing command and SHALL NOT use `SOD remediation`, which does not distinguish apply from `custom:sod-remediation`.

#### Scenario: Description appended on apply

- **GIVEN** a successful apply that removes or detaches access
- **WHEN** the handler completes catalog PATCH
- **THEN** the access item description SHALL include a new appended line referencing policy name and id
- **AND** SHALL NOT replace the entire prior description

#### Scenario: Audit line label names the writing command

- **GIVEN** a successful apply for form instance `fi-1` at ISO-8601 time `{timestamp}`
- **WHEN** the handler builds the description audit line
- **THEN** the line SHALL start with `[access-model-sod-remediation-apply {timestamp}]`
- **AND** SHALL NOT start with `[SOD remediation`
- **AND** the remainder SHALL still carry policy name and id, remediation side, detached access profiles, removed entitlements, form instance id, and optional submitter and comments

#### Scenario: Persisted audit attribute carries the same line

- **GIVEN** a successful apply that appends a description audit line
- **WHEN** the handler persists outputs
- **THEN** `access-model-sod-remediation-apply:description-appended` SHALL equal the appended line including its command label

### Requirement: Access model SOD remediation apply idempotent re-invoke

The apply path of access-model-sod-remediation SHALL treat an already-corrected catalog item as success without error when selected-side entitlements are already absent and nested access profiles to detach are already removed from the role.

#### Scenario: Second invoke skips patch

- **GIVEN** a prior successful apply for form instance `fi-1`
- **WHEN** `custom:access-model-sod-remediation` with `formInstanceId` is invoked again with the same `formInstanceId`
- **THEN** output `access-model-sod-remediation-apply:status` SHALL be `skipped-already-clean`
- **AND** the handler SHALL NOT invoke redundant PATCH requests

### Requirement: Access model SOD remediation apply persist and invoke response

The apply path of access-model-sod-remediation SHALL persist outputs on result-source identity `{requestId}:{formInstanceId}` and return the same fields on successful `ctx.res.send`. The bundled Access Model SOD - Remediation workflow SHALL set `requestId` to `access-model-sod-remediation-apply`. The replay path for a prior terminal apply SHALL persist on the same `{requestId}:{formInstanceId}` identity.

#### Scenario: Persist on request id colon form instance id

- **GIVEN** successful apply for form instance `fi-1` correcting role `role-r`
- **AND** invoke `requestId` `access-model-sod-remediation-apply`
- **WHEN** the handler completes
- **THEN** it SHALL persist on identity `access-model-sod-remediation-apply:fi-1` with `access-model-sod-remediation-apply:status` `applied`
- **AND** SHALL include `access-model-sod-remediation-apply:access-item-id` `role-r`
- **AND** optional `access-model-sod-remediation-apply:removed-entitlement-ids` and `access-model-sod-remediation-apply:detached-access-profile-ids` as multi-value string arrays when non-empty
- **AND** SHALL NOT persist on the bare identity `fi-1`

#### Scenario: Persist identity uses the invoke request id

- **GIVEN** an invoke with `formInstanceId` `fi-1` and `requestId` `access-model-sod-remediation-apply-fi-1`
- **WHEN** the handler persists outputs
- **THEN** the persist identity SHALL be `access-model-sod-remediation-apply-fi-1:fi-1`

#### Scenario: Replay persists on request id colon form instance id

- **GIVEN** a prior terminal apply is found for form instance `fi-1`
- **AND** invoke `requestId` `access-model-sod-remediation-apply`
- **WHEN** the handler replays the prior outputs
- **THEN** it SHALL persist `access-model-sod-remediation-apply:status` `skipped-already-applied` on identity `access-model-sod-remediation-apply:fi-1`

#### Scenario: Bundled workflow request id names the operation

- **GIVEN** the shipped `Access Model SOD - Remediation.json`
- **WHEN** its invoke `requestId` is read
- **THEN** it SHALL be `access-model-sod-remediation-apply`
- **AND** SHALL NOT embed `formInstanceId` in `requestId`

### Requirement: Access model SOD remediation apply prior apply identity fallback

The apply path of access-model-sod-remediation SHALL read a prior terminal apply from the result-source account at `{requestId}:{formInstanceId}` and, only when no such account exists, SHALL fall back to `access-model-sod-remediation-apply:{formInstanceId}` when that identity differs, then to the legacy account at bare `{formInstanceId}`. All lookups SHALL apply identical terminal-status and required-field validation. The handler SHALL NOT update, delete, or otherwise mutate the legacy account.

#### Scenario: Prefixed account short-circuits the apply path

- **GIVEN** an account at `access-model-sod-remediation-apply:fi-1` with `access-model-sod-remediation-apply:status` `applied`
- **WHEN** `custom:access-model-sod-remediation` with `formInstanceId` is invoked with `formInstanceId` `fi-1`, `requestId` `access-model-sod-remediation-apply`, and a `formName`
- **THEN** output `access-model-sod-remediation-apply:status` SHALL be `skipped-already-applied`
- **AND** the handler SHALL prefer outputs from `access-model-sod-remediation-apply:fi-1` over any legacy identity
- **AND** SHALL NOT call form definition or form instance search APIs
- **AND** SHALL NOT invoke Roles or Access Profiles PATCH APIs

#### Scenario: Legacy account keeps a pre-rename apply deduped

- **GIVEN** no account at `access-model-sod-remediation-apply:fi-1`
- **AND** a legacy account at `fi-1` with `access-model-sod-remediation-apply:status` `applied`
- **WHEN** `custom:access-model-sod-remediation` with `formInstanceId` is invoked with `formInstanceId` `fi-1` and a `formName`
- **THEN** output `access-model-sod-remediation-apply:status` SHALL be `skipped-already-applied`
- **AND** SHALL NOT invoke Roles or Access Profiles PATCH APIs
- **AND** SHALL NOT append a second description audit line
- **AND** SHALL persist the replayed outputs on `access-model-sod-remediation-apply:fi-1`
- **AND** SHALL leave the legacy account at `fi-1` unchanged

#### Scenario: Prefixed account wins when both exist

- **GIVEN** accounts at both `access-model-sod-remediation-apply:fi-1` and `fi-1` with terminal apply status
- **WHEN** the handler reads prior apply outputs
- **THEN** it SHALL return the outputs read from `access-model-sod-remediation-apply:fi-1`
- **AND** SHALL ignore the legacy account without error

#### Scenario: Non-terminal legacy account is not a prior apply

- **GIVEN** no account at `access-model-sod-remediation-apply:fi-1`
- **AND** a legacy account at `fi-1` whose `access-model-sod-remediation-apply:status` is neither `applied` nor `skipped-already-applied`
- **WHEN** the handler reads prior apply outputs
- **THEN** it SHALL treat the form instance as not yet applied
- **AND** SHALL continue to form definition lookup and form instance list

#### Scenario: No account under either identity

- **GIVEN** no account at `access-model-sod-remediation-apply:fi-1` and none at `fi-1`
- **WHEN** `custom:access-model-sod-remediation` with `formInstanceId` is invoked with `formInstanceId` `fi-1` and a resolvable `formName`
- **THEN** the handler SHALL resolve the form definition, list instances, and apply the correction as normal

### Requirement: Access model SOD remediation apply offline invoke

The apply path of access-model-sod-remediation SHALL support offline/testMode invocation with deterministic canned form instances and catalog fixtures suitable for local `call:op` testing without live PATCH calls.

#### Scenario: Offline apply simulates success

- **GIVEN** invoke runs without live ISC credentials (offline or testMode)
- **WHEN** `custom:access-model-sod-remediation` with `formInstanceId` completes for a fixture `formInstanceId` with a non-empty `formName`
- **THEN** the handler SHALL use offline fixtures keyed by `formInstanceId`
- **AND** SHALL NOT call `searchFormDefinitionsByTenantV1`
- **AND** SHALL NOT call `searchFormInstancesByTenantV1`
- **AND** SHALL return `access-model-sod-remediation-apply:status` `applied` or `skipped-already-clean`
- **AND** SHALL persist outputs on `{requestId}:{formInstanceId}` when persist is enabled
