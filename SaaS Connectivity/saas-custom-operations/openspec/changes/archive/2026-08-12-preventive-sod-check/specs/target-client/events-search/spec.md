## ADDED Requirements

### Requirement: Executing request events search with retry

The isc events-search module SHALL resolve provisioning events for an access request tracking number by searching the ISC `events` search index via `SearchApi.searchPostV1`, retrying when events are not yet indexed. The module SHALL reside under `src/isc/events-search/` and SHALL NOT encode SoD predict or situation summary logic.

#### Scenario: Search events by tracking number

- **GIVEN** a configured `SearchApi` and tracking number `{trackingNumber}`
- **WHEN** `searchEventsByTrackingNumber` is invoked
- **THEN** the function SHALL call `searchPostV1` against the `events` index with a query matching `{trackingNumber}`
- **AND** SHALL return parsed event documents from the search response

#### Scenario: Retry when events not yet indexed

- **GIVEN** the first search call returns zero events for tracking number `{trackingNumber}`
- **AND** retry configuration allows additional attempts
- **WHEN** `searchEventsByTrackingNumberWithRetry` is invoked
- **THEN** the function SHALL retry the search with bounded delay between attempts
- **AND** SHALL return events when a retry succeeds
- **AND** SHALL return an empty result after exhausting retries without throwing solely for empty results

#### Scenario: Extract access items from events

- **GIVEN** event documents for an executing GRANT_ACCESS request
- **WHEN** `extractAccessItemsFromEvents` is invoked
- **THEN** the function SHALL return access item references including type and id for ENTITLEMENT, ROLE, and ACCESS_PROFILE items present in the events
- **AND** SHALL dedupe items by type and id

#### Scenario: Offline stub events search

- **GIVEN** test mode or offline invocation without apiUrl and token
- **WHEN** `searchEventsByTrackingNumberOffline` is invoked for a tracking number
- **THEN** the function SHALL return deterministic offline event documents suitable for local operation tests
- **AND** SHALL NOT call ISC APIs

#### Scenario: API folder barrel entry

- **GIVEN** the connector source tree under `src/isc/events-search/`
- **WHEN** a developer inspects the module
- **THEN** the folder SHALL contain `index.ts` exporting public search helpers and types
- **AND** offline stub data SHALL reside in `offline-data.ts` separate from search orchestration logic
