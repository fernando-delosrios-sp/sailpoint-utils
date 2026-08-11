## MODIFIED Requirements

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
