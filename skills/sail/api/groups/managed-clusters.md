# Managed Clusters

Use this API to implement managed cluster functionality.

8 endpoints. Paths are relative to the environment API host.

## Get managed clusters

`GET /managed-clusters/v1`

Success: 200.

List current organization's managed clusters, based on request context.

Query:

- standard: `limit`, `offset`, `count`
- filters: operational (eq); name (eq); type (eq); status (eq)

## Create create managed cluster

`POST /managed-clusters/v1`

Success: 200.

Create a new Managed Cluster.
The API returns a result that includes the managed cluster ID.

Body:

```json
{
  "name": "Managed Cluster Name",
  "type": "idn",
  "configuration": {
    "clusterExternalId": "externalId",
    "ccgVersion": "77.0.0"
  },
  "description": "A short description of the managed cluster."
}
```

## Get managed cluster

`GET /managed-clusters/v1/:id`

Success: 200.

Get a managed cluster by ID.

## Update managed cluster

`PATCH /managed-clusters/v1/:id`

Success: 200.

Update an existing managed cluster.

Body:

```json
[
  {
    "op": "replace",
    "path": "/description",
    "value": "New description"
  },
  {
    "op": "replace",
    "path": "/description",
    "value": "New description"
  }
]
```

## Delete managed cluster

`DELETE /managed-clusters/v1/:id`

Success: 204.

Delete an existing managed cluster.

Query:

- `removeClients`: Flag to determine the need to delete a cluster with clients.

## Get managed cluster log configuration

`GET /managed-clusters/v1/:id/log-config`

Success: 200, 204.

Get a managed cluster's log configuration.

## Update managed cluster log configuration

`PUT /managed-clusters/v1/:id/log-config`

Success: 200.

Update a managed cluster's log configuration. You may only specify one of `durationMinutes` or `expiration`, up to 1440 minutes (24 hours) in the future. If neither is specified, the default value for `durationMinutes` is 240.

Body:

```json
{
  "clientId": "3a38a51992e8445ab51a549c0a70ee66",
  "durationMinutes": 120,
  "rootLevel": "INFO",
  "logLevels": {
    "sailpoint.connector.ADLDAPConnector": "TRACE",
    "sailpoint.connector.JDBCConnector": "DEBUG"
  }
}
```

## Trigger manual upgrade for managed cluster

`POST /managed-clusters/v1/:id/manualUpgrade`

Success: 200.

Trigger Manual Upgrade for Managed Cluster.
AMS Security: API, Internal A token with SYSTEM_ADMINISTRATOR authority is required to call this API.
