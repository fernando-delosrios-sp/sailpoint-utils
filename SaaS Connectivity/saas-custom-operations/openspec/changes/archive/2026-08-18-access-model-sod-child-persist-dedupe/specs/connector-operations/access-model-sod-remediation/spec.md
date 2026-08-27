## ADDED Requirements

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

- **GIVEN** invoke `requestId` `scan-parent-1` detects violation for access item `role-r` and policy `policy-p`
- **AND** a result-source account already exists with native identity `scan-parent-1:role-r:policy-p`
- **WHEN** the scan detects the same violation again for `scan-parent-1`
- **THEN** the handler SHALL NOT create a duplicate form instance
- **AND** SHALL increment `access-model-sod-remediation:forms-skipped` in the final `ctx.res.send` summary

#### Scenario: No sod-remediation violation fields

- **GIVEN** a successful form launch
- **WHEN** the handler completes
- **THEN** operation output SHALL NOT require `violationId`, `sod-remediation:*` fields, or compensating control options

---

## REMOVED Requirements

### Requirement: Request-scoped pending form dedupe

**Reason**: Idempotency is keyed on existing child result-source accounts, not ASSIGNED form instance state. Form instance search is no longer used for scan dedupe.

**Migration**: Operators and tests should expect `forms-skipped` when a child account exists at `{requestId}:{accessItemId}:{policyId}`, regardless of form instance state. Retries no longer depend on `searchFormInstancesByTenantV1`.

---

## RENAMED Requirements

_(none)_
