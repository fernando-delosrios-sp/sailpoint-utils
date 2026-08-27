## ADDED Requirements

### Requirement: Optional logUrl invoke config documentation

The project documentation SHALL describe optional invoke config field logUrl for external structured log delivery. The documentation SHALL state that logUrl is optional, that console logging always occurs, and that when logUrl is set the framework POSTs JSON log events to that URL.

#### Scenario: logUrl documented in README

- **GIVEN** a developer reads the Development or invoke config section of README
- **WHEN** they configure local or workflow invoke payloads
- **THEN** the documentation SHALL describe optional config.logUrl
- **AND** SHALL explain that log events are POSTed as JSON when logUrl is present

#### Scenario: JSON log event shape documented

- **GIVEN** a developer configuring logUrl for workflow troubleshooting
- **WHEN** they read the invoke config documentation
- **THEN** the documentation SHALL list the external log event fields timestamp level requestId command message and optional detail
- **AND** SHALL note that config.token is redacted in logged payloads

---

## MODIFIED Requirements

### Requirement: Local debug invoke envelope documentation

The project documentation SHALL describe the spcx local debug invoke POST body shape including type config and input fields. The documentation SHALL note that default incoming request logging prints the resolved envelope to stdout during npm run debug. The documentation SHALL note that optional config.logUrl enables additional JSON log POSTs to an external URL.

#### Scenario: spcx invoke shape documented

- **GIVEN** a developer reading the Development section of README
- **WHEN** they need to invoke the connector locally via spcx
- **THEN** the documentation SHALL show a JSON example with type config and input
- **AND** SHALL explain that config is passed as a top-level field separate from input

#### Scenario: Request logging behavior documented

- **GIVEN** a developer running npm run debug
- **WHEN** they read the Development section
- **THEN** the documentation SHALL describe default incoming request logging
- **AND** SHALL note that config.token is redacted in log output

---
