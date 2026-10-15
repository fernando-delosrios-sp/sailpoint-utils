# Multi-Host Integration

Use this API to build a Multi-Host Integration.

14 endpoints. Paths are relative to the environment API host.

## Create multi-host integration

`POST /multihosts/v1`

Success: 201.

This API is used to create Multi-Host Integration. Multi-host Integration holds similar types of sources.

A token with Org Admin or Multi-Host Admin authority is required to access this endpoint.

Body:

```json
{
  "name": "My Multi-Host Integration",
  "owner": {
    "type": "IDENTITY",
    "id": "2c91808568c529c60168cca6f90c1313",
    "name": "MyName"
  },
  "connector": "multihost-microsoft-sql-server",
  "description": "This is the Multi-Host Integration.",
  "cluster": {
    "name": "Corporate Cluster",
    "id": "2c9180866166b5b0016167c32ef31a66",
    "type": "CLUSTER"
  },
  "connectorAttributes": {
    "maxSourcesPerAggGroup": 10,
    "maxAllowedSources": 300
  },
  "managementWorkgroup": {
    "type": "GOVERNANCE_GROUP",
    "id": "2c91808568c529c60168cca6f90c2222",
    "name": "My Management Workgroup"
  },
  "created": "2022-02-08T14:50:03.827Z",
  "modified": "2024-01-23T18:08:50.897Z"
}
```

## List all existing multi-host integrations

`GET /multihosts/v1`

Success: 200.

Get a list of Multi-Host Integrations.

A token with Org Admin or Multi-Host Admin authority is required to access this endpoint.

Query:

- standard: `limit`, `offset`, `count`
- sorters: name
- filters: type (in); forSubAdminId (in)
- `for-subadmin`: If provided, filters the returned list according to what is visible to the indicated ROLE_SUBADMIN Identity or SOURCE_SUBADMIN identity. The value of the parameter is either an Identity ID, or the special value **me**, which is shorthand…

## List multi-host integration types

`GET /multihosts/v1/types`

Success: 200.

This API endpoint returns the current list of supported Multi-Host Integration types.

A token with Org Admin or Multi-Host Admin authority is required to access this endpoint.

## Create sources within multi-host integration

`POST /multihosts/v1/:multihostId`

Success: 200.

This API is used to create sources within Multi-Host Integration. Multi-Host Integration holds similar types of sources.

A token with Org Admin or Multi-Host Admin authority is required to access this endpoint.

Body:

```json
[
  {
    "name": "My Source",
    "description": "This is the corporate directory.",
    "connectorAttributes": {
      "authType": "SQLAuthentication",
      "url": "jdbc:sqlserver://178.18.41.118:1433",
      "user": "username",
      "driverClass": "com.microsoft.sqlserver.jdbc.SQLServerDriver",
      "maxSourcesPerAggGroup": 10,
      "maxAllowedSources": 300
    }
  },
  {
    "name": "My Source",
    "description": "This is the corporate directory.",
    "connectorAttributes": {
      "authType": "SQLAuthentication",
      "url": "jdbc:sqlserver://178.18.41.118:1433",
      "user": "username",
      "driverClass": "com.microsoft.sqlserver.jdbc.SQLServerDriver",
      "maxSourcesPerAggGroup": 10,
      "maxAllowedSources": 300
    }
  }
]
```

## Get multi-host integration by id

`GET /multihosts/v1/:multihostId`

Success: 200.

Get an existing Multi-Host Integration.

A token with Org Admin or Multi-Host Integration Admin authority is required to access this endpoint.

## Delete multi-host integration

`DELETE /multihosts/v1/:multihostId`

Success: 200.

Delete an existing Multi-Host Integration by ID.

A token with Org Admin or Multi Host Admin authority is required to access this endpoint.

## Update multi-host integration

`PATCH /multihosts/v1/:multihostId`

Success: 200.

Update existing sources within Multi-Host Integration.

A token with Org Admin or Multi-Host Admin authority is required to access this endpoint.

Body:

```json
[
  {
    "op": "add",
    "path": "/description",
    "value": "MDK Multi-Host Integration 222 description"
  }
]
```

## Test configuration for multi-host integration

`POST /multihosts/v1/:multihostId/sources/testConnection`

Success: 200.

This endpoint performs a more detailed validation of the Multi-Host Integration's configuration.

A token with Org Admin or Multi-Host Admin authority is required to access this endpoint.

## Test configuration for multi-host integration's single source

`GET /multihosts/v1/:multihostId/sources/:sourceId/testConnection`

Success: 200.

This endpoint performs a more detailed validation of the source's configuration.

A token with Org Admin or Multi-Host Admin authority is required to access this endpoint.

## List sources within multi-host integration

`GET /multihosts/v1/:multihostId/sources`

Success: 200.

Get a list of sources within Multi-Host Integration ID.

A token with Org Admin or Multi-Host Admin authority is required to access this endpoint.

Query:

- standard: `limit`, `offset`, `count`
- sorters: name
- filters: id (in)

## List multi-host source creation errors

`GET /multihosts/v1/:multiHostId/sources/errors`

Success: 200.

Get a list of sources creation errors within Multi-Host Integration ID.

A token with Org Admin or Multi-Host Admin authority is required to access this endpoint.

## Delete sources within multi-host integration

`POST /multihosts/v1/:multiHostId/sources/bulk-delete`

Success: 200.

This endpoint performs bulk sources delete within Multi-Host Integration via a list of supplied IDs.

The following rights are required to access this endpoint: idn:multihosts:delete, idn:sources:delete

Body:

```json
[
  "2c9180867b2a34e0017b3078d60b0699",
  "2c9180867b2a34e0017b3078d60b0698"
]
```

## List account-aggregation-groups by multi-host id

`GET /multihosts/v1/:multihostId/acctAggregationGroups`

Success: 200.

This API will return array of account aggregation groups within provided Multi-Host Integration ID.
A token with Org Admin or Multi-Host Admin authority is required to access this endpoint.

Query:

- standard: `limit`, `offset`

## List entitlement-aggregation-groups by integration id

`GET /multihosts/v1/:multiHostId/entitlementAggregationGroups`

Success: 200.

This API will return array of aggregation groups within provided Multi-Host Integration ID.

A token with Org Admin or Multi-Host Admin authority is required to access this endpoint.

Query:

- standard: `limit`, `offset`
