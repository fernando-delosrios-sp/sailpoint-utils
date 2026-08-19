## MODIFIED Requirements

### Requirement: Standalone form instance create

The isc forms module SHALL provide `createStandaloneFormInstance` that creates an assigned standalone form instance and returns `standAloneFormUrl`. Callers MAY supply an explicit `expire` timestamp; when omitted, the module SHALL apply its default form instance TTL.

#### Scenario: Standalone instance created

- **GIVEN** a valid form definition id, recipient identity id, source id, and formInput map
- **WHEN** `createStandaloneFormInstance` is invoked
- **THEN** the function SHALL set `standAloneForm: true` and state `ASSIGNED`
- **AND** SHALL set `createdBy.type` to `SOURCE`
- **AND** SHALL return the `standAloneFormUrl` from the create response

#### Scenario: Caller-supplied expire used

- **GIVEN** a caller supplies `expire` equal to an assignment `removeDate`
- **WHEN** `createStandaloneFormInstance` is invoked
- **THEN** the create request body SHALL use that `expire` value
- **AND** SHALL NOT replace it with the default form instance TTL
