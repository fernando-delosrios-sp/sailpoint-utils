# Service Desk Integration

Use this API to build an integration between Identity Security Cloud and a service desk ITSM (IT service management) solution.

10 endpoints. Paths are relative to the environment API host.

## List existing service desk integrations

`GET /service-desk-integrations/v1`

Success: 200.

Get a list of Service Desk integration objects.

Query:

- standard: `limit`, `offset`, `count`
- sorters: name
- filters: id (eq, in); name (eq); type (eq, in); cluster (eq, in)

## Create new service desk integration

`POST /service-desk-integrations/v1`

Success: 200.

Create a new Service Desk integration.

Body:

```json
{
  "name": "Service Desk Integration Name",
  "description": "A very nice Service Desk integration",
  "type": "ServiceNowSDIM",
  "attributes": {
    "property": "value",
    "key": "value"
  },
  "id": "62945a496ef440189b1f03e3623411c8",
  "created": "2024-01-17T18:45:25.994Z",
  "modified": "2024-02-18T18:45:25.994Z",
  "ownerRef": {
    "type": "IDENTITY",
    "id": "2c9180a46faadee4016fb4e018c20639",
    "name": "Support"
  },
  "clusterRef": {
    "type": "CLUSTER",
    "id": "2c9180847a7fccdd017aa5896f9f4f6f",
    "name": "Training VA"
  },
  "cluster": "xyzzy999",
  "managedSources": [
    "2c9180835d191a86015d28455b4a2329",
    "2c5680835d191a85765d28455b4a9823"
  ],
  "provisioningConfig": {
    "managedResourceRefs": [
      {
        "type": "SOURCE",
        "name": "My Source 1"
      },
      {
        "type": "SOURCE",
        "name": "My Source 2"
      }
    ],
    "planInitializerScript": {
```

Body example truncated.

## Get a service desk integration

`GET /service-desk-integrations/v1/:id`

Success: 200.

Get an existing Service Desk integration by ID.

## Update a service desk integration

`PUT /service-desk-integrations/v1/:id`

Success: 200.

Update an existing Service Desk integration by ID.

Body:

```json
{
  "name": "Service Desk Integration Name",
  "description": "A very nice Service Desk integration",
  "type": "ServiceNowSDIM",
  "attributes": {
    "property": "value",
    "key": "value"
  },
  "id": "62945a496ef440189b1f03e3623411c8",
  "created": "2024-01-17T18:45:25.994Z",
  "modified": "2024-02-18T18:45:25.994Z",
  "ownerRef": {
    "type": "IDENTITY",
    "id": "2c9180a46faadee4016fb4e018c20639",
    "name": "Support"
  },
  "clusterRef": {
    "type": "CLUSTER",
    "id": "2c9180847a7fccdd017aa5896f9f4f6f",
    "name": "Training VA"
  },
  "cluster": "xyzzy999",
  "managedSources": [
    "2c9180835d191a86015d28455b4a2329",
    "2c5680835d191a85765d28455b4a9823"
  ],
  "provisioningConfig": {
    "managedResourceRefs": [
      {
        "type": "SOURCE",
        "name": "My Source 1"
      },
      {
        "type": "SOURCE",
        "name": "My Source 2"
      }
    ],
    "planInitializerScript": {
```

Body example truncated.

## Delete a service desk integration

`DELETE /service-desk-integrations/v1/:id`

Success: 204.

Delete an existing Service Desk integration by ID.

## Patch a service desk integration

`PATCH /service-desk-integrations/v1/:id`

Success: 200.

Update an existing Service Desk integration by ID with a PATCH request.

Body:

```json
[
  {
    "op": "replace",
    "path": "/ownerRef",
    "value": {
      "id": "2c9180867d05b227017d09921a205b4d",
      "type": "IDENTITY",
      "name": "Angelo Medici"
    }
  }
]
```

## List service desk integration types

`GET /service-desk-integrations/v1/types`

Success: 200.

This API endpoint returns the current list of supported Service Desk integration types.

## Service desk integration template by scriptname

`GET /service-desk-integrations/v1/templates/:scriptName`

Success: 200.

This API endpoint returns an existing Service Desk integration template by scriptName.

## Get the time check configuration

`GET /service-desk-integrations/v1/status-check-configuration`

Success: 200.

Get the time check configuration of queued SDIM tickets.

## Update the time check configuration

`PUT /service-desk-integrations/v1/status-check-configuration`

Success: 200.

Update the time check configuration of queued SDIM tickets.

Body:

```json
{
  "provisioningStatusCheckIntervalMinutes": "string",
  "provisioningMaxStatusCheckDays": "string"
}
```
