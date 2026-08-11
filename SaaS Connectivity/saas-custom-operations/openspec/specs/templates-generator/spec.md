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
- **AND** SHALL derive operation output fields using the same introspection module as schema codegen

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

### Requirement: Generated output not committed

The project SHALL gitignore the `./templates/` directory so generated files are local-only artifacts.

#### Scenario: Templates directory ignored

- **GIVEN** the generator has written files to `./templates/`
- **WHEN** git status is checked
- **THEN** `./templates/` contents SHALL be ignored by git

### Requirement: Operation schema sidecar generation

The project SHALL provide a codegen script that generates one TypeScript sidecar file per discovered custom operation, containing an `OperationSchemaContract` derived from the operation module's `OperationSignature.output` type literal. Discovery SHALL scan `src/operations/<slug>/index.ts` entry modules. For auto-discovered operations (those with a `command` literal on the interface in `index.ts`), codegen SHALL also generate `auto-registry.ts` to register handlers and schema sidecars using relative import paths `./<slug>/index`, and SHALL sync `connector-spec.json` `commands[]`.

#### Scenario: Sidecar generated for registered operation

- **GIVEN** `custom:example` is auto-discovered with handler module `src/operations/example/index.ts`
- **AND** the module declares `interface ExampleOperation extends OperationSignature` with output fields `summary` and optional `step`
- **WHEN** the developer runs `npm run codegen:schemas`
- **THEN** the generator SHALL write `src/operations/example/index.schema.ts`
- **AND** the sidecar SHALL export `exampleOperationSchema` calling `defineOperationSchema` with fields matching the interface
- **AND** the generator SHALL write `src/operations/auto-registry.ts` importing from `./example/index`

#### Scenario: Sidecar includes auto-generated banner

- **GIVEN** a sidecar is generated
- **WHEN** the file is inspected
- **THEN** it SHALL include a comment indicating it is auto-generated and the command to regenerate

#### Scenario: Codegen fails on missing OperationSignature

- **GIVEN** a registered handler module has no interface extending `OperationSignature`
- **WHEN** `npm run codegen:schemas` runs
- **THEN** the script SHALL exit with non-zero status
- **AND** SHALL report the module path in the error message

#### Scenario: Template subdirectory excluded

- **GIVEN** `src/operations/_template/index.ts` exists as a copy scaffold
- **WHEN** codegen discovers operations
- **THEN** `_template` SHALL NOT be registered as a custom command

### Requirement: Codegen runs before build

The project SHALL run operation schema codegen as part of the build pipeline so sidecars exist before bundling.

#### Scenario: prebuild invokes codegen

- **GIVEN** a developer runs `npm run build`
- **WHEN** the prebuild step executes
- **THEN** operation schema sidecars SHALL be regenerated before `ncc` compiles the connector

### Requirement: Shared operation introspection

The codegen script SHALL use the same operation discovery and `OperationSignature` field extraction logic as the templates generator via `scripts/templates/operation-introspection.ts`. Discovery SHALL enumerate immediate subdirectories of `src/operations/` and treat `index.ts` in each subdirectory as the operation entry module.

#### Scenario: Codegen and templates agree on output fields

- **GIVEN** `custom:example` declares output `summary: string` and `step?: string` in `src/operations/example/index.ts`
- **WHEN** both `npm run codegen:schemas` and `npm run templates` run
- **THEN** the sidecar field list SHALL match the templates generator's extracted output fields for that operation

#### Scenario: Subdirectory discovery finds all auto operations

- **GIVEN** auto-discovered operations exist at `src/operations/example/index.ts` and `src/operations/sod-remediation/index.ts`
- **WHEN** operation introspection runs
- **THEN** both commands SHALL be discovered with correct module paths

