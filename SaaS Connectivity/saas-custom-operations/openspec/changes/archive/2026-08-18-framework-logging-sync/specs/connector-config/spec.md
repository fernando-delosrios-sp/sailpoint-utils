## ADDED Requirements

### Requirement: Log detail map documentation

The project documentation SHALL describe the ctx.log second argument as an optional named detail map. The documentation SHALL state that detail values MAY be objects arrays or scalars and that the same map appears in external log event detail after redaction and JSON-safe normalization.

#### Scenario: Detail map convention documented

- **GIVEN** a developer reads the Operation logging section of README
- **WHEN** they add structured logs to a custom operation handler
- **THEN** the documentation SHALL show an example such as ctx.log.info with message and named keys violation and controls
- **AND** SHALL explain that scalars are allowed as detail values

#### Scenario: JSON-safe normalization documented

- **GIVEN** a developer configuring logUrl for workflow troubleshooting
- **WHEN** they read the invoke config or operation logging documentation
- **THEN** the documentation SHALL note that unserializable detail values are omitted or replaced before POST
- **AND** SHALL list circular references functions symbols and undefined as normalized away

---

## MODIFIED Requirements

### Requirement: Optional logUrl invoke config documentation

The project documentation SHALL describe optional invoke config field logUrl for external structured log delivery. The documentation SHALL state that logUrl is optional, that console logging always occurs, and that when logUrl is set the framework POSTs JSON log events to that URL. The documentation SHALL state that console and POST share the same message and normalized detail map for each log call.

#### Scenario: logUrl documented in README

- **GIVEN** a developer reads the Development or invoke config section of README
- **WHEN** they configure local or workflow invoke payloads
- **THEN** the documentation SHALL describe optional config.logUrl
- **AND** SHALL explain that log events are POSTed as JSON when logUrl is present

#### Scenario: JSON log event shape documented

- **GIVEN** a developer configuring logUrl for workflow troubleshooting
- **WHEN** they read the invoke config documentation
- **THEN** the documentation SHALL list the external log event fields timestamp level requestId command message and optional detail
- **AND** SHALL note that detail is a named map with redacted sensitive fields
- **AND** SHALL describe pretty multiline console output for the same events
