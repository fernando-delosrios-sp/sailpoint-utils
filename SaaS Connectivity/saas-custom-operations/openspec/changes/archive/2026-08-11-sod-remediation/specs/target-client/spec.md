## ADDED Requirements

### Requirement: Experimental violations API client

The connector SHALL provide an ISC loopback client capable of retrieving a policy violation by ID using `GET /violations/v1/:id` with header `X-SailPoint-Experimental: true`.

#### Scenario: Violation fetched by ID

- **GIVEN** a valid access token with violation read scope or ownership
- **WHEN** `custom:sod-remediation` is invoked with `violationId`
- **THEN** the client SHALL call `GET /violations/v1/{violationId}` with the experimental header
- **AND** SHALL parse owner, target, policy, and conflicting access criteria from the response

#### Scenario: Violation fetch failure surfaces error

- **GIVEN** the violations API returns 404 or 403
- **WHEN** the operation handler requests the violation
- **THEN** the handler SHALL fail with a ConnectorError describing the HTTP status

### Requirement: Tenant compensating controls client

The connector SHALL list tenant compensating controls using `GET /controls/v1` with header `X-SailPoint-Experimental: true` to determine whether mitigation is available in the remediation form.

#### Scenario: Controls listed at launch

- **WHEN** `custom:sod-remediation` prepares form input
- **THEN** the handler SHALL call `GET /controls/v1`
- **AND** SHALL set form launch input indicating whether any controls exist (`hasControls`)

#### Scenario: Empty controls hides mitigate path

- **GIVEN** `GET /controls/v1` returns zero controls
- **WHEN** the form instance is created
- **THEN** form input SHALL indicate mitigation is unavailable
- **AND** the situation summary SHALL note that no compensating controls are configured

### Requirement: Custom Forms API integration

The connector SHALL extend `RequestContext.sdk` with Custom Forms API access for form definition search/create and form instance create operations used by `custom:sod-remediation`.

#### Scenario: Forms client available on context

- **GIVEN** a valid apiUrl and token in the invocation envelope
- **WHEN** the sod-remediation handler accesses forms APIs
- **THEN** `ctx.sdk` SHALL expose configured CustomFormsApi methods for search/create form definitions and create form instances

#### Scenario: Standalone form instance created

- **WHEN** the handler creates a form instance
- **THEN** it SHALL set `standAloneForm: true`
- **AND** SHALL populate `formInput` from violation-derived values
- **AND** SHALL return `formUrl` from the create response `standAloneFormUrl`

### Requirement: Identity access path resolution

The connector SHALL resolve each conflicting entitlement on a violation side into a display list that includes the entitlement and any access profile or role assigned to the target identity that grants that entitlement.

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

#### Scenario: Hidden revoke payload per side

- **WHEN** form input is assembled for launch
- **THEN** each side SHALL produce a JSON revoke payload including item references and a `recommendedRevoke` entry preferring Role over Access Profile over Entitlement
