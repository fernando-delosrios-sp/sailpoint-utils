## ADDED Requirements

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
