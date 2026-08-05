# templates-generator

## Purpose

Generate ISC operator artifacts (account schema JSON, OAuth guide, workflow invocation guide) from registered custom operations via `npm run templates`.

## Requirements

### Requirement: Templates npm script

The project SHALL provide an npm script named `templates` that executes the template generator and writes output files to `./templates/`.

#### Scenario: Script runs successfully

- **GIVEN** at least one custom operation is registered in `src/operations/index.ts`
- **WHEN** the developer runs `npm run templates`
- **THEN** the generator SHALL create the `./templates/` directory if missing
- **AND** SHALL write `account-schema.json`, `access-token.md`, and `workflow-invocation.md`

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

- **GIVEN** a command is declared in `connector-spec.json` but not registered in `src/operations/index.ts`
- **WHEN** account schema is generated
- **THEN** that command's output fields SHALL NOT appear in the schema

### Requirement: Access token guide generation

The generator SHALL produce `templates/access-token.md` documenting OAuth client-credentials token acquisition for workflow integration.

#### Scenario: Placeholder configuration documented

- **GIVEN** the sample workflow at `workflows/Workflow - SaaS Custom Operations Call.json` defines Configuration and Get Access Token steps
- **WHEN** access-token guide is generated
- **THEN** the guide SHALL document POST `{API_URL}/oauth/token` with `grant_type=client_credentials`
- **AND** SHALL use placeholders instead of tenant-specific IDs or URLs
- **AND** SHALL explain how to use the token in subsequent invoke requests

### Requirement: Workflow invocation guide generation

The generator SHALL produce `templates/workflow-invocation.md` with one section per registered custom operation.

#### Scenario: Per-operation invoke section

- **GIVEN** `custom:example` is registered with input field `message` and output fields `summary`, `step`
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

### Requirement: Generated output not committed

The project SHALL gitignore the `./templates/` directory so generated files are local-only artifacts.

#### Scenario: Templates directory ignored

- **GIVEN** the generator has written files to `./templates/`
- **WHEN** git status is checked
- **THEN** `./templates/` contents SHALL be ignored by git
