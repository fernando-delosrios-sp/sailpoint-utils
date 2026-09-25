# target-client/entitlements Delta

## ADDED Requirements

### Requirement: List entitlements by value

The isc entitlements module SHALL wrap `EntitlementsApi.listEntitlementsV1` to find entitlements whose `value` equals a caller-supplied string. The module SHALL OData-escape the value, return id and source id for each match, and SHALL NOT encode machine-identity persist policy.

#### Scenario: Value equality match

- **GIVEN** a configured entitlements client and value `{value}` that exists on one or more entitlements
- **WHEN** list-entitlements-by-value is invoked
- **THEN** the function SHALL call `listEntitlementsV1` with filter `value eq "{value}"`
- **AND** SHALL return each matching entitlement’s id and source id

#### Scenario: No match returns empty list

- **GIVEN** no entitlement has `value` `{value}`
- **WHEN** list-entitlements-by-value is invoked
- **THEN** the function SHALL return an empty list
- **AND** SHALL NOT throw solely because zero rows matched

#### Scenario: Quotes in value are escaped

- **GIVEN** an entitlement value containing double quotes
- **WHEN** list-entitlements-by-value is invoked
- **THEN** the function SHALL escape the value for OData string literals
- **AND** SHALL NOT emit a broken filter

#### Scenario: API failure surfaces error

- **GIVEN** `listEntitlementsV1` returns a non-2xx response
- **WHEN** list-entitlements-by-value is invoked
- **THEN** the function SHALL throw ConnectorError including the HTTP status
