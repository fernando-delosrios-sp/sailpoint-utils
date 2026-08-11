## Purpose

Custom command handlers registered in the connector for ISC custom operations, using the custom-operation framework wrapper.
## Requirements
### Requirement: Custom command registration

The connector SHALL register custom command handlers and SHALL NOT register any std command handlers.

#### Scenario: Custom command invoked

- **GIVEN** a custom command is declared in connector-spec.json and registered in the connector
- **WHEN** ISC invokes that custom command
- **THEN** the connector SHALL execute the registered handler via withCustomOperation

#### Scenario: No std handlers registered

- **GIVEN** the connector is initialized
- **WHEN** the connector command registry is inspected
- **THEN** no std:account:list, std:account:read, or std:test-connection handlers SHALL be registered

### Requirement: Operations registry pattern

The connector SHALL provide an operations module where authors register custom commands. Each custom operation SHALL live in its own subdirectory under `src/operations/<slug>/` with entry module `index.ts`. Operations that declare a `command` string literal on their `OperationSignature` interface in `index.ts` SHALL be auto-registered at build time via a generated registry. Operations without `command` SHALL remain manually registrable in `src/operations/index.ts`. Flat handler files directly under `src/operations/` (other than `index.ts` and generated `auto-registry.ts`) SHALL NOT be used for operation implementations.

#### Scenario: Auto-discovered operation registered

- **GIVEN** `src/operations/example/index.ts` declares `command: 'custom:example'` on its `OperationSignature` interface and exports exactly one `customOperation` handler
- **WHEN** the connector initializes
- **THEN** `custom:example` SHALL be registered without a manual `.command()` line in `operations/index.ts`

#### Scenario: Manual operation still supported

- **GIVEN** an operation module has no `command` on its `OperationSignature` interface
- **WHEN** the author registers the handler via `.command('custom:legacy', legacyOperation)` in `operations/index.ts`
- **THEN** `custom:legacy` SHALL be registered at connector initialization

#### Scenario: Duplicate command fails build

- **GIVEN** an auto-discovered operation declares `command: 'custom:example'`
- **AND** `operations/index.ts` also registers `.command('custom:example', …)` manually
- **WHEN** codegen runs
- **THEN** the build SHALL fail with a descriptive error

#### Scenario: Example operation available

- **GIVEN** the foundation template is built
- **WHEN** a developer inspects `src/operations/`
- **THEN** an example custom operation SHALL be present at `src/operations/example/index.ts` demonstrating auto-discovery with `command` on `OperationSignature`

#### Scenario: Subdirectory entry is index.ts

- **GIVEN** a new auto-discovered operation with slug `my-op`
- **WHEN** the author adds the operation
- **THEN** the handler entry module SHALL be `src/operations/my-op/index.ts`
- **AND** domain helper modules MAY live alongside it in the same subdirectory

