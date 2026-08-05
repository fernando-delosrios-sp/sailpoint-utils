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

The connector SHALL provide an operations module where authors register custom commands, with an example operation included as a template.

#### Scenario: Example operation available

- **GIVEN** the foundation template is built
- **WHEN** a developer inspects src/operations/
- **THEN** an example custom operation SHALL be present demonstrating ctx.sdk, ctx.log, and ctx.persist usage
