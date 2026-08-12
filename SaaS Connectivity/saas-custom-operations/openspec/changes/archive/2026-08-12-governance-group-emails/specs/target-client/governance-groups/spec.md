# target-client/governance-groups Delta

## ADDED Requirements

### Requirement: Workgroup lookup by name

The isc governance-groups module SHALL resolve a governance group (workgroup) by exact display name using `listWorkgroupsV1` with an OData name filter.

#### Scenario: Workgroup found by name

- **GIVEN** a configured governance groups client and workgroup name `{groupName}` that exists in the tenant
- **WHEN** `findWorkgroupByName` is invoked
- **THEN** the function SHALL call `listWorkgroupsV1` with filter `name eq "{groupName}"` (with OData string escaping)
- **AND** SHALL return the matching workgroup id and name

#### Scenario: Workgroup not found

- **GIVEN** no workgroup matches `{groupName}`
- **WHEN** `findWorkgroupByName` is invoked
- **THEN** the function SHALL return undefined or throw ConnectorError as documented by the caller contract
- **AND** SHALL NOT return a partial match from a different name

#### Scenario: API failure surfaces error

- **GIVEN** `listWorkgroupsV1` returns a non-2xx response
- **WHEN** `findWorkgroupByName` is invoked
- **THEN** the function SHALL throw ConnectorError including the HTTP status

### Requirement: Workgroup member email listing

The isc governance-groups module SHALL list member email addresses for a workgroup id using `listWorkgroupMembersV1`, paginating until all members are retrieved.

#### Scenario: Member emails extracted

- **GIVEN** workgroup id `{workgroupId}` with members that include `email` values
- **WHEN** `listWorkgroupMemberEmails` is invoked
- **THEN** the function SHALL call `listWorkgroupMembersV1` for `{workgroupId}`
- **AND** SHALL return an array of non-empty `email` strings from member records
- **AND** SHALL omit members with missing or blank email

#### Scenario: Large member sets paginated

- **GIVEN** a workgroup with more members than a single API page returns
- **WHEN** `listWorkgroupMemberEmails` is invoked
- **THEN** the function SHALL paginate `listWorkgroupMembersV1` until no further members remain
- **AND** SHALL aggregate emails from all pages

#### Scenario: Member list API failure

- **GIVEN** `listWorkgroupMembersV1` returns a non-2xx response
- **WHEN** `listWorkgroupMemberEmails` is invoked
- **THEN** the function SHALL throw ConnectorError including the HTTP status

### Requirement: Governance group emails orchestration

The isc governance-groups module SHALL expose a high-level function that resolves a workgroup by name and returns member emails suitable for operation handlers.

#### Scenario: End-to-end resolution by name

- **GIVEN** workgroup name `{groupName}` that exists with members having emails
- **WHEN** `resolveGovernanceGroupEmails` (or equivalent public orchestrator) is invoked
- **THEN** the function SHALL find the workgroup by name
- **AND** SHALL return the member email array
- **AND** SHALL NOT require the caller to know workgroup id

#### Scenario: Orchestrator fails when group missing

- **GIVEN** no workgroup matches `{groupName}`
- **WHEN** the orchestrator is invoked
- **THEN** the function SHALL throw ConnectorError indicating the governance group was not found
