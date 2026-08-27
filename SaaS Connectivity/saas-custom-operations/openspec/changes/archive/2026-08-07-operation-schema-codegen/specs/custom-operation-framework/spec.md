## MODIFIED Requirements

### Requirement: Operation schema contract on context

The framework SHALL attach an OperationSchemaContract to the request context containing the current command name and output fields from the operation's OperationSignature. For auto-discovered operations, the framework SHALL resolve the schema from a build-time populated registry keyed by command name when `operationSchema` is not passed explicitly to `customOperation`. Manually registered operations SHALL continue to pass an explicit `operationSchema` sidecar. Operation modules SHALL NOT hand-maintain duplicate `defineOperationSchema({...})` field maps.

#### Scenario: Context carries current operation output fields

- **GIVEN** `custom:example` declares output fields `summary` string and optional `step` string in its OperationSignature interface
- **AND** `example-operation.schema.ts` is generated from that interface
- **AND** the sidecar is registered via generated `auto-registry.ts`
- **WHEN** `custom:example` is invoked
- **THEN** the request context operationSchema SHALL include `summary` and `step` as output fields for schema reconciliation

#### Scenario: Auto-discovered operation resolves schema from registry

- **GIVEN** `custom:example` is auto-discovered and its generated sidecar is registered via `registerOperationSchema`
- **AND** the handler is created via `customOperation<ExampleOperation>(handler)` without an explicit `operationSchema` option
- **WHEN** `custom:example` is invoked
- **THEN** the request context operationSchema SHALL include output fields from the generated sidecar for schema reconciliation

#### Scenario: Auto-discovered operation wires sidecar via auto-registry

- **GIVEN** `example-operation.ts` declares `command: 'custom:example'` on its OperationSignature interface
- **AND** codegen generates `example-operation.schema.ts` and `auto-registry.ts`
- **WHEN** the generated auto-registry is loaded
- **THEN** it SHALL import `exampleOperationSchema` from `./example-operation.schema`
- **AND** SHALL call `registerOperationSchema('custom:example', exampleOperationSchema)`
- **AND** `example-operation.ts` SHALL NOT inline a manual `defineOperationSchema({...})` field map

#### Scenario: Manual operation requires explicit operationSchema

- **GIVEN** a manually registered operation without `command` on its OperationSignature
- **WHEN** the handler is registered via `customOperation` with `{ operationSchema: manualOperationSchema }`
- **THEN** the request context operationSchema SHALL use the explicitly passed schema

#### Scenario: Explicit operationSchema overrides registry

- **GIVEN** an auto-discovered operation also passes `{ operationSchema: customSchema }` to `customOperation`
- **WHEN** the operation is invoked
- **THEN** the explicit schema SHALL take precedence over the registry lookup
