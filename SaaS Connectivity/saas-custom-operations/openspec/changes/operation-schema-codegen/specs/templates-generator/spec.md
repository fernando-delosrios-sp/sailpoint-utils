## ADDED Requirements

### Requirement: Operation schema sidecar generation

The project SHALL provide a codegen script that generates one TypeScript sidecar file per registered custom operation, containing an `OperationSchemaContract` derived from the operation module's `OperationSignature.output` type literal.

#### Scenario: Sidecar generated for registered operation

- **GIVEN** `custom:example` is registered in `src/operations/index.ts` with handler module `example-operation.ts`
- **AND** the module declares `interface ExampleOperation extends OperationSignature` with output fields `summary` and optional `step`
- **WHEN** the developer runs `npm run codegen:schemas`
- **THEN** the generator SHALL write `src/operations/example-operation.schema.ts`
- **AND** the sidecar SHALL export `exampleOperationSchema` calling `defineOperationSchema` with fields matching the interface

#### Scenario: Sidecar includes auto-generated banner

- **GIVEN** a sidecar is generated
- **WHEN** the file is inspected
- **THEN** it SHALL include a comment indicating it is auto-generated and the command to regenerate

#### Scenario: Codegen fails on missing OperationSignature

- **GIVEN** a registered handler module has no interface extending `OperationSignature`
- **WHEN** `npm run codegen:schemas` runs
- **THEN** the script SHALL exit with non-zero status
- **AND** SHALL report the module path in the error message

### Requirement: Codegen runs before build

The project SHALL run operation schema codegen as part of the build pipeline so sidecars exist before bundling.

#### Scenario: prebuild invokes codegen

- **GIVEN** a developer runs `npm run build`
- **WHEN** the prebuild step executes
- **THEN** operation schema sidecars SHALL be regenerated before `ncc` compiles the connector

### Requirement: Shared operation introspection

The codegen script SHALL use the same operation registration and `OperationSignature` field extraction logic as the templates generator.

#### Scenario: Codegen and templates agree on output fields

- **GIVEN** `custom:example` declares output `summary: string` and `step?: string`
- **WHEN** both `npm run codegen:schemas` and `npm run templates` run
- **THEN** the sidecar field list SHALL match the templates generator's extracted output fields for that operation

## MODIFIED Requirements

### Requirement: Templates npm script

The project SHALL provide an npm script named `templates` that executes the template generator and writes output files to `./templates/`.

#### Scenario: Script runs successfully

- **GIVEN** at least one custom operation is registered in `src/operations/index.ts`
- **WHEN** the developer runs `npm run templates`
- **THEN** the generator SHALL create the `./templates/` directory if missing
- **AND** SHALL write `account-schema.json`, `access-token.md`, and `workflow-invocation.md`
- **AND** SHALL derive operation output fields using the same introspection module as schema codegen
