## MODIFIED Requirements

### Requirement: Operation schema contract on context

The framework SHALL attach an OperationSchemaContract to the request context containing the current command name and output fields from the operation's OperationSignature. The supported authoring pattern SHALL import a build-generated schema sidecar rather than hand-maintaining duplicate field maps in the operation module.

#### Scenario: Context carries current operation output fields

- **GIVEN** `custom:example` declares output fields `summary` string and optional `step` string in its OperationSignature interface
- **AND** `example-operation.schema.ts` is generated from that interface
- **WHEN** `custom:example` is invoked
- **THEN** the request context operationSchema SHALL include `summary` and `step` as output fields for schema reconciliation

#### Scenario: Operation imports generated sidecar

- **GIVEN** `example-operation.ts` registers the handler with `customOperation`
- **WHEN** the operation module is read
- **THEN** it SHALL import `exampleOperationSchema` from `./example-operation.schema`
- **AND** SHALL pass it as `operationSchema` to `customOperation`
- **AND** SHALL NOT inline a manual `defineOperationSchema({...})` field map
