## ADDED Requirements

### Requirement: Form launch shared facade

The connector SHALL provide a shared **form launch** orchestrator under `src/lib/form-launch/` that ensures a seeded form definition (via existing `src/isc/forms/` helpers), creates a standalone form instance for a recipient, and returns a **form notification envelope** including the standalone form URL. The facade SHALL NOT persist result-source accounts and SHALL NOT resolve recipient identity or email policy.

#### Scenario: Ensure then create returns form URL

- **GIVEN** a Forms API mock, form name, owner id, seed/template, recipient id, created-by source id, and formInput
- **WHEN** the form launch facade is invoked
- **THEN** it SHALL ensure the form definition and create a standalone instance
- **AND** the returned envelope `formUrl` SHALL equal the created standalone form URL

#### Scenario: Notification fields paired with form URL

- **GIVEN** email header, body builder or body string needing the form URL, and recipients
- **WHEN** the facade completes create
- **THEN** the returned envelope SHALL include header, body (with form URL available to the body), and recipients

#### Scenario: Optional expire passed through

- **GIVEN** an explicit `expire` timestamp
- **WHEN** the facade creates the instance
- **THEN** create SHALL receive that expire value (not only the default TTL)

#### Scenario: Handler owns persist

- **GIVEN** a successful facade result
- **WHEN** inspecting the facade implementation
- **THEN** it SHALL NOT call `ctx.persist` or write result-source accounts

#### Scenario: Uses isc forms API helpers

- **GIVEN** the form launch facade
- **WHEN** ensuring definitions or creating instances
- **THEN** it SHALL delegate to `src/isc/forms/` helpers rather than reimplementing Forms HTTP calls
