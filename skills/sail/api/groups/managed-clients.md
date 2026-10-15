# Managed Clients

Use this API to implement managed client functionality.

7 endpoints. Paths are relative to the environment API host.

## Get managed clients

`GET /managed-clients/v1`

Success: 200.

List managed clients.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq); name (eq); clientId (eq); clusterId (eq)

## Create managed client

`POST /managed-clients/v1`

Success: 200.

Create a new managed client.
The API returns a result that includes the managed client ID.

Body:

```json
{
  "clusterId": "aClusterId",
  "description": "A short description of the ManagedClient",
  "name": "aName",
  "type": "VA"
}
```

## Get managed client

`GET /managed-clients/v1/:id`

Success: 200.

Get managed client by ID.

## Update managed client

`PATCH /managed-clients/v1/:id`

Success: 200.

Update an existing managed client.

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

## Delete managed client

`DELETE /managed-clients/v1/:id`

Success: 204.

Delete an existing managed client.

## Get managed client status

`GET /managed-clients/v1/:id/status`

Success: 200.

Get a managed client's status, using its ID.

Query:

- `type`: (Required) Managed client type to get status for. (This can only be one of CCG,VA,INTERNAL,IIQ_HARVESTER,)

## Get managed client health indicators

`GET /managed-clients/v1/:id/health-indicators`

Success: 200.

Get a managed client's health indicators, using its ID.
