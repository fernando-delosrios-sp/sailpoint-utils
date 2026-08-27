# connector-operations/sod-remediation Delta

## MODIFIED Requirements

### Requirement: SOD remediation launch operation

The connector SHALL register a custom command `custom:sod-remediation` that prepares an ISC form instance for SOD violation remediation and SHALL NOT execute corrective revokes or mitigating-control application. Implementation SHALL reside under `src/operations/sod-remediation/` with entry module `index.ts`.

#### Scenario: Operation invoked with required inputs

- **GIVEN** `custom:sod-remediation` is declared in connector-spec.json and registered
- **WHEN** ISC invokes the command with input containing `violationId`, `formName`, and standard `requestId`
- **THEN** the handler SHALL fetch the violation, ensure the form definition identified by `formName` exists, create a standalone form instance, and persist namespaced output fields `sod-remediation:form-url`, `sod-remediation:situation-header`, `sod-remediation:situation-summary`, and `sod-remediation:owner-email`

#### Scenario: Recipient defaults to violation owner

- **GIVEN** a violation whose owner identity ID is `owner-a`
- **AND** input does not include `owner`
- **WHEN** `custom:sod-remediation` creates a form instance
- **THEN** the form instance recipient SHALL be identity `owner-a`

#### Scenario: Recipient override via owner input

- **GIVEN** input includes `owner` set to identity ID `owner-b`
- **WHEN** `custom:sod-remediation` creates a form instance
- **THEN** the form instance recipient SHALL be identity `owner-b` regardless of the violation owner

#### Scenario: Form definition created once by name

- **GIVEN** no form definition named `{formName}` exists in the tenant
- **WHEN** `custom:sod-remediation` is invoked with that `formName`
- **THEN** the handler SHALL create a form definition from the bundled seed template in `src/operations/sod-remediation/seed/` using `{formName}` as the definition name
- **AND** subsequent invocations with the same `formName` SHALL reuse the existing definition without patching it

#### Scenario: Form definition owner is access token identity

- **GIVEN** connector config includes a valid access token whose resolved identity ID is `token-owner-id`
- **AND** no form definition named `{formName}` exists in the tenant
- **AND** the violation owner identity ID is `violation-owner-id` where `violation-owner-id` differs from `token-owner-id`
- **WHEN** `custom:sod-remediation` creates the form definition from seed
- **THEN** the form definition owner SHALL be identity `token-owner-id`
- **AND** SHALL NOT use `violation-owner-id` as the form definition owner

#### Scenario: Form definition owner offline fallback

- **GIVEN** invoke runs in offline mode without `apiUrl` and without `token`
- **AND** no form definition named `{formName}` exists
- **WHEN** `custom:sod-remediation` creates the form definition from seed
- **THEN** the form definition owner SHALL use the connector's offline canned owner identity
- **AND** SHALL NOT attempt JWT token identity resolution

#### Scenario: Owner email resolved for workflow delivery

- **GIVEN** the resolved form instance recipient identity ID is `owner-a`
- **AND** the public identity record for `owner-a` has email `owner-a@example.com`
- **WHEN** `custom:sod-remediation` completes successfully
- **THEN** persisted output `sod-remediation:owner-email` SHALL be `owner-a@example.com`

#### Scenario: Email subject header output

- **GIVEN** a violation for identity `Alice Example`
- **WHEN** `custom:sod-remediation` completes successfully
- **THEN** persisted output `sod-remediation:situation-header` SHALL be plain text suitable for workflow email subject lines
- **AND** SHALL include the violating identity display name

#### Scenario: Email summary includes remediation form link

- **GIVEN** a successful launch producing form URL `https://tenant.example/form/1`
- **WHEN** the handler persists operation output
- **THEN** `sod-remediation:situation-summary` SHALL include an HTML link to the remediation form URL
- **AND** form launch input `situationSummaryHtml` SHALL NOT include the remediation form link

#### Scenario: Output contract is minimal

- **GIVEN** a successful launch
- **WHEN** the handler completes
- **THEN** operation output persisted via `ctx.persist` SHALL include only `sod-remediation:form-url`, `sod-remediation:situation-header`, `sod-remediation:situation-summary`, and `sod-remediation:owner-email` as typed output fields
- **AND** SHALL NOT require output fields `formInstanceId`, `violationId`, `formName`, `formDefinitionId`, or `recipientName`

#### Scenario: Workflow-friendly form keys

- **GIVEN** the seed form definition used for SOD remediation
- **WHEN** a recipient submits the form
- **THEN** submitted `formData` SHALL expose user keys `action`, `remediationSide`, `policyControl`, and `comments`
- **AND** SHALL include hidden launch-populated keys `violationId`, `targetIdentityId`, `groupAAccessSearch`, and `groupBAccessSearch` suitable for downstream workflow JSONPath access
- **AND** SHALL NOT include hidden keys `groupARevokePayload` or `groupBRevokePayload`

#### Scenario: Single-side corrective selection

- **GIVEN** the user selects `action` value `Correct`
- **WHEN** the form is submitted
- **THEN** `formData.remediationSide` SHALL be exactly one of `groupA` or `groupB`

#### Scenario: Auto-discovery registration

- **GIVEN** `src/operations/sod-remediation/index.ts` declares `command: 'custom:sod-remediation'` on its OperationSignature interface
- **WHEN** codegen runs
- **THEN** `custom:sod-remediation` SHALL be registered in auto-registry.ts and listed in connector-spec.json commands

### Requirement: SOD access path resolution

The sod-remediation operation SHALL resolve each conflicting entitlement on a violation side into a display list that includes the entitlement and any access profile or role assigned to the target identity that grants that entitlement. Access path resolution logic SHALL reside under `src/operations/sod-remediation/` and SHALL NOT be part of the generic isc integration layer.

#### Scenario: Entitlement-only side

- **GIVEN** a conflicting entitlement held directly by the target identity
- **WHEN** access paths are resolved for that side
- **THEN** the side display list SHALL include the entitlement
- **AND** the side warning text SHALL use the standard corrective-removal message

#### Scenario: Access profile or role on side

- **GIVEN** a conflicting entitlement granted via an access profile or role assigned to the target identity
- **WHEN** access paths are resolved for that side
- **THEN** the side display list SHALL include the access profile or role in addition to the entitlement
- **AND** the side warning text SHALL state that removing profile- or role-level access may affect other functions of the user

#### Scenario: Hidden access search string per side

- **WHEN** form input is assembled for launch
- **THEN** each side SHALL produce an ISC access-item search filter joining all resolved path item ids with ` OR ` in the form `id:{uuid}`

#### Scenario: Single-item side search string

- **GIVEN** a violation side with one resolved access path item
- **WHEN** form input is assembled for launch
- **THEN** that side access search string SHALL be `id:{itemId}` without an ` OR ` suffix

### Requirement: Access path revocability annotation

The sod-remediation operation SHALL annotate each resolved access path (entitlement, access profile, role) with workflow-actionable revocability derived from path expansion. Entitlements on a side that also includes an access profile or role SHALL be marked not revocable with reason granted-via-role or granted-via-access-profile. Entitlements on entitlement-only sides SHALL be marked revocable.

#### Scenario: Entitlement-only side

- **GIVEN** a violation side with conflicting entitlements and no assigned access profile or role granting them
- **WHEN** access paths are resolved
- **THEN** each entitlement line SHALL be marked revocable
- **AND** the recommended revoke target SHALL be that entitlement

#### Scenario: Entitlement with role on side

- **GIVEN** a conflicting entitlement granted via an assigned role on the same side
- **WHEN** access paths are resolved
- **THEN** the entitlement line SHALL be marked not revocable with reason granted-via-role
- **AND** the role line SHALL be marked revocable and recommended

#### Scenario: Resolved access paths include revocability metadata

- **WHEN** access paths are resolved for a violation side
- **THEN** each access path item SHALL include `revocable`, `recommended`, and optional `reason`
- **AND** internal resolution SHALL identify a `recommendedRevoke` entry preferring Role over Access Profile over Entitlement among revocable items
- **AND** revocability metadata SHALL NOT be serialized as stringified JSON in submitted formData

## REMOVED Requirements

### Requirement: Hidden revoke payload per side

**Reason:** ISC workflows cannot parse stringified JSON from form submission outputs.

**Migration:** Use `groupAAccessSearch` / `groupBAccessSearch` for access-item fetch filters; use `remediationSide` to select the corrective side; rely on HTML columns for owner-facing revocability context.
