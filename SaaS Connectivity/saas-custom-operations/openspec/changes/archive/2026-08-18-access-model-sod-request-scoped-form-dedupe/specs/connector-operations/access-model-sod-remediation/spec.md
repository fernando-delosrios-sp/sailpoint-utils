## ADDED Requirements

### Requirement: Request-scoped pending form dedupe

The access-model-sod-remediation operation SHALL treat a remediation form instance as pending when its state is `ASSIGNED`. Before creating a form for a violation, the handler SHALL search instances of the remediation form definition and skip creation when an ASSIGNED instance exists with matching `formInput.parentRequestId`, `formInput.accessItemId`, and `formInput.policyId` for the current scan invoke. Dedupe SHALL NOT consider ASSIGNED instances from other parent request ids or instances missing `formInput.parentRequestId`.

#### Scenario: Same parent request skips duplicate pending form

- **GIVEN** invoke `requestId` `scan-001` detects violation for access item `role-r` and policy `policy-p`
- **AND** an ASSIGNED standalone form instance already exists for form definition `{formName}` with `formInput.parentRequestId` `scan-001`, `formInput.accessItemId` `role-r`, and `formInput.policyId` `policy-p`
- **WHEN** the scan detects the same violation again on the same invoke or a retry with `requestId` `scan-001`
- **THEN** the handler SHALL NOT create a duplicate form instance
- **AND** SHALL increment `access-model-sod-remediation:forms-skipped` in the final `ctx.res.send` summary

#### Scenario: Different parent request does not skip

- **GIVEN** invoke `requestId` `scan-002` detects violation for access item `role-r` and policy `policy-p`
- **AND** an ASSIGNED standalone form instance exists for form definition `{formName}` with `formInput.parentRequestId` `scan-001`, `formInput.accessItemId` `role-r`, and `formInput.policyId` `policy-p`
- **WHEN** the scan runs with `requestId` `scan-002`
- **THEN** the handler SHALL create a new form instance for the violation
- **AND** SHALL NOT increment `access-model-sod-remediation:forms-skipped` for that violation solely because of the `scan-001` instance

#### Scenario: Legacy instance without parentRequestId does not skip

- **GIVEN** invoke `requestId` `scan-003` detects violation for access item `role-r` and policy `policy-p`
- **AND** an ASSIGNED standalone form instance exists for form definition `{formName}` with `formInput.accessItemId` `role-r` and `formInput.policyId` `policy-p` but no `formInput.parentRequestId`
- **WHEN** the scan runs
- **THEN** the handler SHALL create a new form instance with `formInput.parentRequestId` `scan-003`

#### Scenario: Non-assigned instance does not skip

- **GIVEN** invoke `requestId` `scan-004` detects violation for access item `role-r` and policy `policy-p`
- **AND** a SUBMITTED or COMPLETED form instance exists with matching `formInput.parentRequestId`, `formInput.accessItemId`, and `formInput.policyId`
- **WHEN** the scan runs
- **THEN** the handler SHALL create a new form instance

#### Scenario: One search per scan for pending instances

- **GIVEN** a connected scan evaluates multiple violations
- **WHEN** pending-form dedupe runs
- **THEN** the handler SHALL load assigned remediation instances for the form definition at most once per scan invocation
- **AND** SHALL reuse that data for each violation's request-scoped dedupe check

---

## MODIFIED Requirements

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

- **GIVEN** invoke `requestId` `scan-parent-1`
- **AND** an ASSIGNED standalone form instance already exists for form definition `{formName}` with `formInput.parentRequestId` `scan-parent-1`, `formInput.accessItemId` `role-r`, and `formInput.policyId` `policy-p`
- **WHEN** the scan detects the same violation again for `scan-parent-1`
- **THEN** the handler SHALL NOT create a duplicate form instance
- **AND** SHALL increment `access-model-sod-remediation:forms-skipped` in the final `ctx.res.send` summary

#### Scenario: No sod-remediation violation fields

- **GIVEN** a successful form launch
- **WHEN** the handler completes
- **THEN** operation output SHALL NOT require `violationId`, `sod-remediation:*` fields, or compensating control options

---

## REMOVED Requirements

_(none)_
