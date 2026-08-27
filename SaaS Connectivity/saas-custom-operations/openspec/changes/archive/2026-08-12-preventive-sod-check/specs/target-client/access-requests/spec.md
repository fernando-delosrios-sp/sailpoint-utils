## ADDED Requirements

### Requirement: Executing access request status listing

The isc access-requests module SHALL list access request status items for a target identity in EXECUTING state via `AccessRequestsApi.listAccessRequestStatusV1`. The module SHALL reside under `src/isc/access-requests/` and SHALL NOT encode preventive-sod-check-specific summary or predict logic.

#### Scenario: List executing requests for identity

- **GIVEN** a configured `AccessRequestsApi` and target identity id `{identityId}`
- **WHEN** `listExecutingAccessRequestsForIdentity` is invoked
- **THEN** the function SHALL call `listAccessRequestStatusV1` with `requestedFor` set to `{identityId}` and `requestState` set to `EXECUTING`
- **AND** SHALL return the status items from the response

#### Scenario: Filter GRANT_ACCESS operations

- **GIVEN** access request status items include both GRANT_ACCESS and REVOKE_ACCESS operations
- **WHEN** `listExecutingGrantAccessRequestsForIdentity` is invoked
- **THEN** the function SHALL return only items whose operation is GRANT_ACCESS
- **AND** SHALL exclude REVOKE_ACCESS and other non-grant operations

#### Scenario: Offline stub listing

- **GIVEN** test mode or offline invocation without apiUrl and token
- **WHEN** `listExecutingGrantAccessRequestsForIdentityOffline` is invoked for a target identity id
- **THEN** the function SHALL return deterministic offline access request status items suitable for local operation tests
- **AND** SHALL NOT call ISC APIs

#### Scenario: Resolve identity from access request id

- **GIVEN** an EXECUTING GRANT_ACCESS access request with `accessRequestId` `{accessRequestId}` and `requestedFor.id` `{identityId}`
- **WHEN** `resolveIdentityIdForAccessRequest` is invoked with `{accessRequestId}`
- **THEN** the function SHALL call `listAccessRequestStatusV1` with `requestState` EXECUTING and filter `accessRequestId eq "{accessRequestId}"`
- **AND** SHALL return `{identityId}`

#### Scenario: Offline resolve identity from access request id

- **GIVEN** offline invocation without apiUrl and token
- **WHEN** `resolveIdentityIdForAccessRequestOffline` is invoked with a known offline tracking number
- **THEN** the function SHALL return the canned target identity id without calling ISC APIs

#### Scenario: API folder barrel entry

- **GIVEN** the connector source tree under `src/isc/access-requests/`
- **WHEN** a developer inspects the module
- **THEN** the folder SHALL contain `index.ts` exporting public list helpers and types
- **AND** offline stub data SHALL reside in `offline-data.ts` separate from orchestration logic
