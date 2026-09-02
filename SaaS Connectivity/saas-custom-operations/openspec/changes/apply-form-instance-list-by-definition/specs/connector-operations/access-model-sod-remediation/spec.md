## MODIFIED Requirements

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
- **THEN** it SHALL invoke `custom:access-model-sod-remediation-apply` with `formInstanceId` and `formDefinitionId`
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
