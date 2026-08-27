## ADDED Requirements

### Requirement: Per-operation documentation pointers

The project root README SHALL state that each custom operation documents its invoke contract and workflow integration in `src/operations/<slug>/README.md`. Operation-specific invoke and workflow integration content SHALL NOT be duplicated in the root README when a per-operation README exists for that command.

#### Scenario: Root README points to operation docs

- **GIVEN** a developer reads the Extending the connector section of the project README
- **WHEN** they look for operation-specific invoke or workflow guidance
- **THEN** the documentation SHALL direct them to the co-located README in each operation subdirectory
- **AND** SHALL NOT require reading the root README for operation-specific workflow steps

#### Scenario: Operation README documents payloads

- **GIVEN** an operation has workflow-ready invoke examples under `payloads/` (e.g. `*-workflow.json`)
- **WHEN** a developer reads that operation's README
- **THEN** the README SHALL reference the relevant payload file paths for local and workflow invoke examples
