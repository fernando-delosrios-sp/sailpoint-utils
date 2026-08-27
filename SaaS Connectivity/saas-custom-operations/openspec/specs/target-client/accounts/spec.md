# target-client/accounts Specification

## Purpose

Generic ISC Accounts API wrappers under `src/isc/accounts/`. Callers supply payloads and interpret responses; this module SHALL NOT encode result-source persist policy, provisioning task polling, attribute formatting for operation output, or schema reconciliation.

Account schema management remains under `src/isc/sources/` (SourcesApi).

## Requirements

### Requirement: Generic Accounts API boundary

The isc accounts module SHALL expose thin wrappers around `AccountsApi` methods. Functions SHALL accept caller-supplied request parameters and return SDK responses or parsed data. The module SHALL NOT hardcode result-source upsert policy, DelimitedFile retry semantics, operation output attribute formatting, or TaskManagementApi task polling.

#### Scenario: Account read by id

- **GIVEN** a configured `AccountsApi` and account id `{accountId}`
- **WHEN** `getAccount` is invoked
- **THEN** the function SHALL call `getAccountV1` with that id
- **AND** SHALL return the account record or undefined

#### Scenario: Account list uses caller filter

- **GIVEN** a configured `AccountsApi` and OData filter `{filters}`
- **WHEN** `listAccounts` is invoked with optional limit, offset, and detailLevel
- **THEN** the function SHALL call `listAccountsV1` with the supplied parameters
- **AND** SHALL return the account records from the response

#### Scenario: Account create uses caller payload

- **GIVEN** a caller-supplied account create attributes payload
- **WHEN** `createAccount` is invoked
- **THEN** the function SHALL call `createAccountV1` with that payload
- **AND** SHALL return the provisioning task id from the response when present

#### Scenario: Account update uses caller payload

- **GIVEN** an account id and caller-supplied account attributes payload
- **WHEN** `putAccount` is invoked
- **THEN** the function SHALL call `putAccountV1` with that id and payload
- **AND** SHALL return the provisioning task id from the response when present

### Requirement: Native identity lookup on source

The isc accounts module SHALL provide `findAccountOnSource` to locate an account on a given source by native identity, trying OData filters before paginated source scan.

#### Scenario: Lookup by nativeIdentity filter

- **GIVEN** a configured `AccountsApi`, source id `{sourceId}`, and native identity `{nativeIdentity}`
- **WHEN** `findAccountOnSource` is invoked and `listAccountsV1` returns a matching account on that source
- **THEN** the function SHALL return the account id and attributes
- **AND** SHALL match on nativeIdentity, name, or attributes.id equal to `{nativeIdentity}`

#### Scenario: Lookup falls back to source scan

- **GIVEN** OData filters return no match for `{nativeIdentity}` on `{sourceId}`
- **WHEN** `findAccountOnSource` is invoked
- **THEN** the function SHALL paginate `listAccountsV1` filtered by sourceId until a match is found or pages are exhausted
- **AND** SHALL return undefined when no account matches

#### Scenario: Invalid OData filter skipped

- **GIVEN** an OData filter that causes a 400 response from `listAccountsV1`
- **WHEN** `findAccountOnSource` tries that filter
- **THEN** the function SHALL skip to the next filter strategy
- **AND** SHALL NOT throw solely for that 400 response

### Requirement: OData string escaping utility

The isc accounts module SHALL export `escapeODataString` for escaping values embedded in OData double-quoted string literals.

#### Scenario: Quotes and backslashes escaped

- **GIVEN** a string containing backslashes or double quotes
- **WHEN** `escapeODataString` is invoked
- **THEN** the function SHALL return a value safe for use inside OData `"..."` literals
