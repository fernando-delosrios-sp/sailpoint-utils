# Public Identities

Use this API in conjunction with Public Identites Config to enable non-administrators to view identities' publicly visible attributes.

1 endpoints. Paths are relative to the environment API host.

## Get list of public identities

`GET /public-identities/v1`

Success: 200.

Get a list of public identities.  Set `add-core-filters` to `true` to exclude incomplete identities and uncorrelated accounts.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in); alias (eq, sw); email (eq, sw); firstname (eq, sw); lastname (eq, sw)
- `add-core-filters`: If *true*, only get identities which satisfy ALL the following criteria in addition to any criteria specified by *filters*: - Should be either correlated or protected. - Should not be "spadmin" or "cloudadmin". - uid should not be null. -…
- sorters: name
