## MODIFIED Requirements

### Requirement: Account schema generation

The generator SHALL produce `templates/account-schema.json` compatible with ISC create-source-schema request shape, using semantic attribute names from registered operation output interfaces.

#### Scenario: Core attributes always present

- **GIVEN** registered operations exist
- **WHEN** account schema is generated
- **THEN** the schema SHALL include attributes `id`, `status`, and `date`
- **AND** SHALL set `identityAttribute` to `id`
- **AND** SHALL set schema `name` to `account`

#### Scenario: Operation output attributes merged

- **GIVEN** a registered operation declares output fields `summary` and optional `step`
- **WHEN** account schema is generated
- **THEN** the schema SHALL include `summary` and `step` attributes
- **AND** SHALL NOT include reserved framework keys `sourceId` as operator-facing schema attributes

#### Scenario: Only registered operations included

- **GIVEN** operations are discovered via auto-registration or manual index.ts registration
- **WHEN** account schema is generated
- **THEN** only discovered operations SHALL contribute output fields to the schema

### Requirement: Workflow invocation guide generation

The generator SHALL produce `templates/workflow-invocation.md` with one section per registered custom operation.

#### Scenario: Per-operation invoke section

- **GIVEN** `custom:example` is discovered with input field `message` and output fields `summary`, `step`
- **WHEN** workflow invocation guide is generated
- **THEN** the guide SHALL include a section for `custom:example`
- **AND** SHALL document invoke URL pattern `{API_URL}/beta/platform-connectors/{CONNECTOR_ID}/invoke`
- **AND** SHALL document invoke body with `config`, `connectorRef`, `type`, `tag`, and `input` including `requestId`
- **AND** SHALL document reading results via account filter on `nativeIdentity` equal to `requestId`

#### Scenario: Child identity documented when detected

- **GIVEN** an operation persists to a child identity pattern such as `` `${requestId}:detail` ``
- **WHEN** workflow invocation guide is generated
- **THEN** the operation section SHALL document the additional account read for that child identity

#### Scenario: Links to access token guide

- **GIVEN** workflow invocation guide is generated
- **WHEN** an operator reads an operation section
- **THEN** the guide SHALL reference `access-token.md` for authentication setup
- **AND** SHALL NOT duplicate the full OAuth section in each operation block
