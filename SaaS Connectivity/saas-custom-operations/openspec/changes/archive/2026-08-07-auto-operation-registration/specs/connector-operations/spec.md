## MODIFIED Requirements

### Requirement: Operations registry pattern

The connector SHALL provide an operations module where authors register custom commands. Operations that declare a `command` string literal on their `OperationSignature` interface SHALL be auto-registered at build time via a generated registry. Operations without `command` SHALL remain manually registrable in `src/operations/index.ts`.

#### Scenario: Auto-discovered operation registered

- **GIVEN** an operation module declares `command: 'custom:example'` on its `OperationSignature` interface and exports exactly one `customOperation` handler
- **WHEN** the connector initializes
- **THEN** `custom:example` SHALL be registered without a manual `.command()` line in `index.ts`

#### Scenario: Manual operation still supported

- **GIVEN** an operation module has no `command` on its `OperationSignature` interface
- **WHEN** the author registers the handler via `.command('custom:legacy', legacyOperation)` in `index.ts`
- **THEN** `custom:legacy` SHALL be registered at connector initialization

#### Scenario: Duplicate command fails build

- **GIVEN** an auto-discovered operation declares `command: 'custom:example'`
- **AND** `index.ts` also registers `.command('custom:example', …)` manually
- **WHEN** codegen runs
- **THEN** the build SHALL fail with a descriptive error

#### Scenario: Example operation available

- **GIVEN** the foundation template is built
- **WHEN** a developer inspects `src/operations/`
- **THEN** an example custom operation SHALL be present demonstrating auto-discovery with `command` on `OperationSignature`
