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

### Requirement: Per-operation README documentation

Each custom operation subdirectory under `src/operations/<slug>/` that is auto-discovered for command registration SHALL include a co-located `README.md` at `src/operations/<slug>/README.md`. The README SHALL document the operation command name, purpose, input and output fields, invoke payload examples or references to files under `payloads/`, and workflow integration steps when applicable. The `_template` operation scaffold SHALL include a `README.md` template for authors to copy when creating a new operation.

#### Scenario: Discovered operation has README

- **GIVEN** codegen discovers an operation at `src/operations/my-op/index.ts` with a declared `command` literal
- **WHEN** a developer inspects `src/operations/my-op/`
- **THEN** `README.md` SHALL exist in that subdirectory
- **AND** the README SHALL name the operation command (e.g. `custom:my-op`)

#### Scenario: Missing README fails build

- **GIVEN** an auto-discovered operation exists at `src/operations/my-op/index.ts`
- **AND** `src/operations/my-op/README.md` is absent
- **WHEN** operation discovery tests or codegen prebuild checks run
- **THEN** the build SHALL fail with a descriptive error naming the missing README path

#### Scenario: Template includes README scaffold

- **GIVEN** a developer copies `src/operations/_template/` to create a new operation
- **WHEN** they inspect the template directory
- **THEN** `_template/README.md` SHALL exist with section placeholders for purpose, command, input/output, invoke examples, workflow integration, and local development

#### Scenario: Example operation documents invoke contract

- **GIVEN** the foundation template includes `src/operations/example/index.ts`
- **WHEN** a developer reads `src/operations/example/README.md`
- **THEN** the README SHALL document `custom:example` input and output fields
- **AND** SHALL reference local invoke payloads under `payloads/` for offline and connected runs

### Requirement: Namespaced persist output keys

Each custom operation SHALL persist workflow-readable output on the result source using attribute names prefixed with `{slug}:` where `slug` is the operation command name without the `custom:` prefix. The `OperationSignature` output type, generated operation schema sidecar, operation README, and `ctx.persist` attributes SHALL use the same prefixed keys.

#### Scenario: Output keys use operation slug prefix

- **GIVEN** an operation is registered as `custom:my-op`
- **WHEN** the handler persists output via `ctx.persist`
- **THEN** each output attribute key SHALL begin with `my-op:`
- **AND** SHALL NOT persist unprefixed keys such as `result` or `emails` unless the slug itself contains a colon

#### Scenario: Sod remediation follows namespacing convention

- **GIVEN** `custom:sod-remediation` completes successfully
- **WHEN** operation output is read from the result source
- **THEN** persisted keys SHALL include `sod-remediation:form-url`, `sod-remediation:form-email-header`, `sod-remediation:form-email-body`, and `sod-remediation:form-email-recipients`

#### Scenario: Preventive sod check follows namespacing convention

- **GIVEN** `custom:preventive-sod-check` completes successfully
- **WHEN** operation output is read from the result source
- **THEN** persisted keys SHALL include `preventive-sod-check:has-violation`, `preventive-sod-check:situation-summary`, and `preventive-sod-check:violated-policy-names`

