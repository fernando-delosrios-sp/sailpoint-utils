# target-client/machine-identities Delta

## ADDED Requirements

### Requirement: List and get machine identities

The isc machine-identities module SHALL wrap `MachineIdentitiesApi` to paginate machine identities and to get one machine identity by id, including `userEntitlements`. Callers SHALL supply filters; the module SHALL NOT encode result-source persist policy.

#### Scenario: List paginates machine identities

- **GIVEN** a configured `MachineIdentitiesApi` whose list endpoint returns more than one page
- **WHEN** list-machine-identities is invoked without an id filter
- **THEN** the function SHALL call `listMachineIdentitiesV1` (or v2) with pagination until pages are exhausted
- **AND** SHALL return the concatenated machine identity records

#### Scenario: Get returns user entitlements

- **GIVEN** machine identity id `{id}` with `userEntitlements`
- **WHEN** get-machine-identity is invoked
- **THEN** the function SHALL return that identity including each `sourceId` and `entitlementId` on `userEntitlements`

#### Scenario: List API failure surfaces error

- **GIVEN** the list machine identities call returns a non-2xx response
- **WHEN** list-machine-identities is invoked
- **THEN** the function SHALL throw ConnectorError including the HTTP status

#### Scenario: Experimental header sent when required

- **GIVEN** the SDK method requires `X-SailPoint-Experimental`
- **WHEN** list, get, or patch is invoked
- **THEN** the wrapper SHALL send the experimental header as required by the client

### Requirement: Patch machine identity user entitlements

The isc machine-identities module SHALL expose a helper that PATCHes `/userEntitlements` with a complete array of `{sourceId, entitlementId}` refs. Union policy SHALL remain in the calling operation.

#### Scenario: Patch sends complete refs

- **GIVEN** a complete user-entitlements union
- **WHEN** the patch helper is invoked
- **THEN** it SHALL call the machine identity update API with JSON Patch operation `replace`
- **AND** path `/userEntitlements`
- **AND** the supplied refs as its value

### Requirement: Filter machine identity by invoke identityId

The isc machine-identities module SHALL resolve an optional invoke `identityId` by `id eq` then `cisIdentityId eq`, returning the matching machine identity or signaling not found to the caller.

#### Scenario: Match by machine identity id

- **GIVEN** a machine identity whose `id` is `{identityId}`
- **WHEN** resolve-by-identity-id is invoked with `{identityId}`
- **THEN** the function SHALL return that machine identity

#### Scenario: Match by cisIdentityId

- **GIVEN** no machine identity `id` equals `{identityId}`
- **AND** a machine identity `cisIdentityId` equals `{identityId}`
- **WHEN** resolve-by-identity-id is invoked
- **THEN** the function SHALL return that machine identity

#### Scenario: Unknown identityId is not found

- **GIVEN** no machine identity matches `{identityId}` on `id` or `cisIdentityId`
- **WHEN** resolve-by-identity-id is invoked
- **THEN** the function SHALL return undefined or throw ConnectorError as documented for the operation
- **AND** SHALL NOT return a different identity
