# connector-operations/evaluate-access-request-risk Delta

## ADDED Requirements

### Requirement: Bounded concurrent catalog reads

The evaluate-access-request-risk operation MAY fetch independent roles, access profiles, and entitlements concurrently within a single invocation. Concurrent fetches SHALL use a bounded concurrency limit. Identical ids SHALL share one in-flight lookup. Scoring rules, driver attribution, and situation-summary wording SHALL remain unchanged.

#### Scenario: Shared entitlement fetched once under concurrent scoring

- **GIVEN** two access profiles that both contain entitlement `ent-shared`
- **WHEN** risk evaluation scores those profiles concurrently
- **THEN** the catalog SHALL fetch `ent-shared` once
- **AND** the situation summary SHALL still report one distinct entitlement

#### Scenario: Scoring semantics unchanged under concurrency

- **GIVEN** a role whose nested entitlement scores High by effective privilege
- **WHEN** evaluation runs with concurrent nested fetches
- **THEN** the persisted tier SHALL still be `High`
- **AND** the deciding-rule split SHALL still attribute the driver to effective privilege
