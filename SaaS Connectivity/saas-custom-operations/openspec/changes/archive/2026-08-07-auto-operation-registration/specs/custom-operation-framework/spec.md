## MODIFIED Requirements

### Requirement: Operation signature

Each custom operation SHALL declare an OperationSignature interface with input and output fields using plain TypeScript types. The interface MAY optionally declare `command?: string` as a string literal for build-time auto-registration. The framework SHALL provide customOperation to register the handler; input and ctx.persist attribute types SHALL be inferred from that interface at compile time.

#### Scenario: Operation declares command for auto-registration

- **GIVEN** an operation defines `interface ExampleOperation extends OperationSignature` with `command: 'custom:example'`, input, and output fields
- **WHEN** codegen runs
- **THEN** the operation SHALL be included in the generated auto-registry without manual index.ts registration

#### Scenario: Operation declares combined input and output signature

- **GIVEN** an operation defines interface ExampleOperation extending OperationSignature with input message optional string and output summary string and optional step string
- **WHEN** the operation is registered via customOperation with a handler typed to ExampleOperation
- **THEN** the handler input parameter SHALL be typed as ExampleOperation input
- **AND** ctx.persist SHALL accept Partial of ExampleOperation output

## ADDED Requirements

### Requirement: Operation schema contract on context

The framework SHALL attach an OperationSchemaContract to the request context containing the current command name and output fields from the operation's OperationSignature. For auto-discovered operations, the framework SHALL resolve the schema from a build-time populated registry keyed by command name when `operationSchema` is not passed explicitly to `customOperation`. Manually registered operations SHALL continue to pass an explicit `operationSchema` sidecar.

#### Scenario: Auto-discovered operation resolves schema from registry

- **GIVEN** `custom:example` is auto-discovered and its generated sidecar is registered via `registerOperationSchema`
- **AND** the handler is created via `customOperation<ExampleOperation>(handler)` without an explicit `operationSchema` option
- **WHEN** `custom:example` is invoked
- **THEN** the request context operationSchema SHALL include output fields from the generated sidecar for schema reconciliation

#### Scenario: Manual operation requires explicit operationSchema

- **GIVEN** a manually registered operation without `command` on its OperationSignature
- **WHEN** the handler is registered via `customOperation` with `{ operationSchema: manualOperationSchema }`
- **THEN** the request context operationSchema SHALL use the explicitly passed schema

#### Scenario: Explicit operationSchema overrides registry

- **GIVEN** an auto-discovered operation also passes `{ operationSchema: customSchema }` to `customOperation`
- **WHEN** the operation is invoked
- **THEN** the explicit schema SHALL take precedence over the registry lookup
