## ADDED Requirements

### Requirement: Optional logUrl invoke config

The framework SHALL accept an optional non-empty `logUrl` string on the invoke config object. When absent or empty, the framework SHALL operate in console-only logging mode. When present, the framework SHALL trim whitespace and use the value as the external log sink URL for the invocation.

#### Scenario: logUrl resolved from invoke config

- **GIVEN** an invoke with config containing logUrl `https://logs.example.com/ingest`
- **WHEN** customOperation initializes the request context
- **THEN** the framework logger for that invocation SHALL target that URL for external log events

#### Scenario: Empty logUrl treated as unset

- **GIVEN** an invoke with config logUrl set to an empty string or whitespace only
- **WHEN** customOperation initializes the request context
- **THEN** the framework SHALL NOT POST external log events for that invocation

---

### Requirement: Dual-sink framework logger

The framework SHALL provide a logger that always writes human-readable log lines to stdout and, when logUrl is configured, SHALL additionally POST one JSON log event per log call to logUrl using HTTP POST with Content-Type application/json. External POST failures SHALL NOT fail or reject the custom operation invocation.

#### Scenario: Console output always emitted

- **GIVEN** an invocation with or without logUrl configured
- **WHEN** the framework logger records an info warn or error message
- **THEN** stdout SHALL receive a human-readable log line for that message

#### Scenario: External POST when logUrl configured

- **GIVEN** an invocation with logUrl `https://logs.example.com/ingest`
- **WHEN** the framework logger records an info message
- **THEN** the framework SHALL POST a JSON log event to that URL
- **AND** the operation invocation SHALL continue without awaiting POST completion

#### Scenario: External POST failure is non-fatal

- **GIVEN** an invocation with logUrl pointing to an unreachable host
- **WHEN** the framework logger records a message
- **THEN** the custom operation SHALL complete normally
- **AND** console output SHALL still include the log line

---

### Requirement: External log event schema

Each external log event POSTed to logUrl SHALL be a JSON object containing ISO-8601 timestamp, level info warn or error, requestId, optional command string, message string, and optional detail field. When detail contains sensitive values such as token or Authorization bearer values, the framework SHALL redact them before POST.

#### Scenario: Log event includes correlation fields

- **GIVEN** an invocation with requestId wf-run-8842 and command custom:example
- **WHEN** ctx.log.info is called with message step complete
- **THEN** the POSTed JSON SHALL include requestId wf-run-8842 command custom:example level info and message step complete

#### Scenario: Token redacted in external log event detail

- **GIVEN** an invocation where a log call includes detail containing a token field
- **WHEN** the framework POSTs the external log event
- **THEN** the detail token value SHALL be replaced with a redaction marker
- **AND** the raw token value SHALL NOT appear in the POST body

---

## MODIFIED Requirements

### Requirement: Operation logging

The framework SHALL provide correlated logging on the request context via ctx.log with info warn and error methods that include requestId in every log entry. ctx.log SHALL use the dual-sink framework logger for the invocation. When logUrl is configured, ctx.log calls SHALL additionally POST JSON log events to logUrl.

#### Scenario: Logs include requestId correlation

- **GIVEN** a custom operation with requestId wf-run-8842
- **WHEN** the handler calls ctx.log.info with a message
- **THEN** the log output SHALL include requestId wf-run-8842

#### Scenario: Token is not logged

- **GIVEN** a custom operation input containing a token
- **WHEN** the handler or framework logs operation details
- **THEN** the token value SHALL NOT appear in log output

#### Scenario: ctx.log exposed on request context

- **GIVEN** a handler wrapped with customOperation
- **WHEN** the handler accesses ctx.log
- **THEN** ctx.log SHALL expose info warn and error methods
- **AND** each method SHALL route through the invocation framework logger

---

### Requirement: Default incoming request logging

The framework SHALL log every registered custom command invoke to stdout before the handler executes using the framework logger. The log output SHALL include the command type, the invoke input object, and the resolved invocation config when available. The log format SHALL use readable section headers and spread JSON formatting consistent with the operation test runner output style. When logUrl is configured, the framework SHALL additionally POST a JSON log event containing structured command input and redacted config detail.

#### Scenario: Invoke payload logged at command entry

- **GIVEN** a custom command registered via registerCommands
- **WHEN** the connector receives an invoke with input containing requestId
- **THEN** stdout SHALL include an Incoming request section before the handler runs
- **AND** the log SHALL include the command type and input fields

#### Scenario: Config included when resolved

- **GIVEN** an invoke with a resolvable config containing apiUrl token and sourceName
- **WHEN** the command handler is invoked
- **THEN** the incoming request log SHALL include a config object with apiUrl and sourceName
- **AND** the config object SHALL appear alongside command and input in the logged payload

#### Scenario: Token redacted in request log

- **GIVEN** an invoke config containing a non-empty token value
- **WHEN** the incoming request is logged
- **THEN** the logged config token field SHALL be replaced with a redaction marker
- **AND** the raw token value SHALL NOT appear in stdout

#### Scenario: All registered commands wrapped

- **GIVEN** auto-discovered and manually registered custom commands
- **WHEN** registerCommands completes
- **THEN** every command handler registered via connector.command SHALL log incoming requests before delegation

#### Scenario: Incoming request posted when logUrl configured

- **GIVEN** an invoke with config logUrl set to a reachable HTTP endpoint
- **WHEN** the incoming request is logged at command entry
- **THEN** the framework SHALL POST a JSON log event to logUrl
- **AND** the event detail SHALL include command and input with config token redacted

---
