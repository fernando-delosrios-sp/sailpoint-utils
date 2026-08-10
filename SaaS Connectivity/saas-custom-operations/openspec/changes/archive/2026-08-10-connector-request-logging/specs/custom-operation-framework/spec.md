## ADDED Requirements

### Requirement: Default incoming request logging

The framework SHALL log every registered custom command invoke to stdout before the handler executes. The log output SHALL include the command type, the invoke input object, and the resolved invocation config when available. The log format SHALL use readable section headers and spread JSON formatting consistent with the operation test runner output style.

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

### Requirement: Invoke config resolution for bundled and spcx runtimes

The framework SHALL resolve per-invoke config from context.config when present, otherwise from the external node_modules connector SDK readConfig when running under spcx local dev, otherwise from the bundled readConfig runtime path.

#### Scenario: spcx per-invoke config resolved

- **GIVEN** spcx wraps the invoke with _withConfig supplying apiUrl token and sourceName
- **WHEN** resolveInvocationConfig or readInvokeConfig is called without context.config
- **THEN** the framework SHALL return the spcx-supplied config object
- **AND** configProvided SHALL be true

#### Scenario: Production CONNECTOR_CONFIG fallback

- **GIVEN** no context.config and no spcx AsyncLocalStorage config
- **WHEN** readInvokeConfig is called and bundled readConfig returns a non-empty object
- **THEN** the framework SHALL return the bundled config
- **AND** configProvided SHALL be true when keys are present

#### Scenario: Absent config returns not provided

- **GIVEN** no context.config and all readConfig paths return empty or fail
- **WHEN** resolveInvocationConfig is called
- **THEN** configProvided SHALL be false
- **AND** config SHALL be an empty object

## MODIFIED Requirements

### Requirement: Invocation config presence detection

The framework SHALL determine whether an invocation config object was provided from deps.config, context.config, or readInvokeConfig before applying test mode ISC gating. readInvokeConfig SHALL try external node_modules SDK readConfig before bundled readConfig.

#### Scenario: Context config counts as provided

- **GIVEN** test mode is active and context.config contains connection fields
- **WHEN** customOperation resolves configuration
- **THEN** the framework SHALL treat config as provided
- **AND** SHALL require apiUrl token and sourceName

#### Scenario: Absent config enables offline test mode path

- **GIVEN** test mode is active via SPCX_TEST_MODE only and neither deps.config nor context.config is set
- **WHEN** customOperation resolves configuration
- **THEN** the framework SHALL treat config as not provided
- **AND** SHALL skip ISC API calls

#### Scenario: spcx AsyncLocalStorage config counts as provided

- **GIVEN** test mode is active and spcx supplies config via _withConfig without context.config
- **WHEN** customOperation resolves configuration via readInvokeConfig
- **THEN** the framework SHALL treat config as provided
- **AND** SHALL require apiUrl token and sourceName
