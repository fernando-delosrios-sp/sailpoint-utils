## ADDED Requirements

### Requirement: JSON-safe detail normalization

Before writing to stdout or POSTing to logUrl, the framework SHALL normalize the optional log detail map so that JSON encoding cannot throw. The framework SHALL omit detail keys whose values are undefined, functions, or symbols. The framework SHALL replace circular object references with the string `[Circular]`. The framework SHALL serialize Error instances as plain objects containing name message and stack. The framework SHALL convert bigint values to decimal strings.

#### Scenario: Undefined detail keys omitted from JSON

- **GIVEN** a log call with detail `{ present: 'ok', missing: undefined }`
- **WHEN** the framework emits the log event
- **THEN** the POSTed JSON detail SHALL include key present
- **AND** SHALL NOT include key missing

#### Scenario: Circular reference replaced

- **GIVEN** a log detail object that references itself circularly on key payload
- **WHEN** the framework emits the log event
- **THEN** the POSTed JSON detail payload value SHALL be the string `[Circular]`
- **AND** the invocation SHALL NOT throw

#### Scenario: Function values omitted

- **GIVEN** a log call with detail `{ ok: true, fn: () => {} }`
- **WHEN** the framework emits the log event
- **THEN** the POSTed JSON detail SHALL NOT include key fn
- **AND** the invocation SHALL NOT throw

---

### Requirement: Pretty console log formatting

The framework SHALL format stdout log output for human operators using a headline line followed by labeled detail blocks. The headline SHALL be `[requestId] message`. When detail is present, each detail key SHALL appear on its own labeled line or block. Scalar detail values SHALL render inline after the key label. Object and array detail values SHALL render using Node inspect with depth colors when stdout is a TTY.

#### Scenario: Headline includes requestId and message

- **GIVEN** requestId wf-run-8842 and message violation loaded
- **WHEN** ctx.log.info is called without detail
- **THEN** stdout SHALL include a line starting with `[wf-run-8842] violation loaded`

#### Scenario: Named detail keys render as labeled blocks

- **GIVEN** a log call with message violation loaded and detail `{ violation: { id: 'v-1' }, count: 2 }`
- **WHEN** the framework writes to stdout
- **THEN** stdout SHALL include label violation with object content
- **AND** SHALL include label count with scalar value 2

#### Scenario: Console and JSON share normalized detail

- **GIVEN** logUrl configured and detail `{ violation: { id: 'v-1' } }`
- **WHEN** ctx.log.info is called with message violation loaded
- **THEN** the POSTed JSON detail SHALL equal the normalized detail used for console rendering
- **AND** both sinks SHALL apply the same redaction and JSON-safe normalization

---

### Requirement: Operation logs use framework logger

Custom operation handlers and operation-local logging helpers SHALL NOT call console.log console.warn or console.error directly for invoke-scoped diagnostics. Operation step logs SHALL use ctx.log or getActiveFrameworkLogger with a human message headline and a named detail map.

#### Scenario: SOD remediation step logs use framework logger

- **GIVEN** sod-remediation handler executing with logUrl configured
- **WHEN** the handler logs a violation step
- **THEN** the log SHALL route through the invocation framework logger
- **AND** SHALL POST a JSON log event to logUrl

#### Scenario: Access model SOD remediation uses ctx.log

- **GIVEN** access-model-sod-remediation handler executing
- **WHEN** the handler logs discover or policy steps
- **THEN** the log SHALL use ctx.log or getActiveFrameworkLogger
- **AND** SHALL NOT call console.log directly

---

## MODIFIED Requirements

### Requirement: Operation logging

The framework SHALL provide correlated logging on the request context via ctx.log with info warn and error methods that include requestId in every log entry. ctx.log SHALL use the dual-sink framework logger for the invocation. The optional second argument SHALL be a named detail map whose values MAY be objects arrays or scalars. When logUrl is configured, ctx.log calls SHALL POST JSON log events whose detail field contains the same normalized map written to stdout.

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

#### Scenario: Scalar detail values allowed

- **GIVEN** a handler calls ctx.log.info with message step complete and detail `{ count: 3 }`
- **WHEN** logUrl is configured
- **THEN** the POSTed JSON detail SHALL include count with value 3

---

### Requirement: Dual-sink framework logger

The framework SHALL provide a logger that always writes pretty human-readable log output to stdout and, when logUrl is configured, SHALL additionally POST one JSON log event per log call to logUrl using HTTP POST with Content-Type application/json. Console and POST SHALL use the same redacted JSON-safe normalized message and detail. External POST failures SHALL NOT fail or reject the custom operation invocation.

#### Scenario: Console output always emitted

- **GIVEN** an invocation with or without logUrl configured
- **WHEN** the framework logger records an info warn or error message
- **THEN** stdout SHALL receive human-readable log output for that message

#### Scenario: External POST when logUrl configured

- **GIVEN** an invocation with logUrl `https://logs.example.com/ingest`
- **WHEN** the framework logger records an info message
- **THEN** the framework SHALL POST a JSON log event to that URL
- **AND** the operation invocation SHALL continue without awaiting POST completion

#### Scenario: External POST failure is non-fatal

- **GIVEN** an invocation with logUrl pointing to an unreachable host
- **WHEN** the framework logger records a message
- **THEN** the custom operation SHALL complete normally
- **AND** console output SHALL still include the log output

---

### Requirement: External log event schema

Each external log event POSTed to logUrl SHALL be a JSON object containing ISO-8601 timestamp, level info warn or error, requestId, optional command string, message string, and optional detail field. The detail field SHALL contain the normalized named detail map when provided. Detail values MAY be scalars objects or arrays. When detail contains sensitive values such as token or Authorization bearer values, the framework SHALL redact them before POST using the same policy applied to stdout.

#### Scenario: Log event includes correlation fields

- **GIVEN** an invocation with requestId wf-run-8842 and command custom:example
- **WHEN** ctx.log.info is called with message step complete
- **THEN** the POSTed JSON SHALL include requestId wf-run-8842 command custom:example level info and message step complete

#### Scenario: Token redacted in external log event detail

- **GIVEN** an invocation where a log call includes detail containing a token field
- **WHEN** the framework POSTs the external log event
- **THEN** the detail token value SHALL be replaced with a redaction marker
- **AND** the raw token value SHALL NOT appear in the POST body

#### Scenario: Named detail map preserved in JSON

- **GIVEN** ctx.log.info called with message violation loaded and detail `{ violation: { id: 'v-1' }, controls: [] }`
- **WHEN** the framework POSTs the external log event
- **THEN** the POSTed detail SHALL include keys violation and controls
- **AND** violation.id SHALL be `v-1`

---

### Requirement: Default incoming request logging

The framework SHALL log every registered custom command invoke before the handler executes using the same dual-sink framework logger as ctx.log. The log SHALL use message Incoming request and detail `{ command, input, config }` when config is available. Config in detail SHALL pass through sanitizeForLog. Console output MAY use readable section headers and spread JSON formatting consistent with the operation test runner output style. When logUrl is configured, the framework SHALL POST the same JSON log event schema as other framework logs.

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
- **AND** the raw token value SHALL NOT appear in stdout or POSTed detail

#### Scenario: All registered commands wrapped

- **GIVEN** auto-discovered and manually registered custom commands
- **WHEN** registerCommands completes
- **THEN** every command handler registered via connector.command SHALL log incoming requests before delegation

#### Scenario: Incoming request posted when logUrl configured

- **GIVEN** an invoke with config logUrl set to a reachable HTTP endpoint
- **WHEN** the incoming request is logged at command entry
- **THEN** the framework SHALL POST a JSON log event to logUrl
- **AND** the event message SHALL be Incoming request
- **AND** the event detail SHALL include command input and redacted config using the same schema as ctx.log detail
