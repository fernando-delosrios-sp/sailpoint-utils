# Managed Cluster Types

Use this API to implement managed cluster types functionality.

5 endpoints. Paths are relative to the environment API host.

## List managed cluster types

`GET /managed-cluster-types/v1`

Success: 200.

Get a list of Managed Cluster Types.

Query:

- standard: `limit`, `offset`
- `type`: Type descriptor
- `pod`: Pinned pod (or default)
- `org`: Pinned org (or default)

## Create new managed cluster type

`POST /managed-cluster-types/v1`

Success: 200.

Create a new Managed Cluster Type.

The API returns a result that includes the Managed Cluster Type ID

Body:

```json
{
  "type": "idn",
  "pod": "megapod-useast1",
  "org": "denali-cjh",
  "managedProcessIds": [
    "someId",
    "someId2"
  ]
}
```

## Get a managed cluster type

`GET /managed-cluster-types/v1/:id`

Success: 200.

Get a Managed Cluster Type.

## Update a managed cluster type

`PATCH /managed-cluster-types/v1/:id`

Success: 200.

Update an existing Managed Cluster Type.

Body:

```json
{
  "operations": [
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
}
```

## Delete a managed cluster type

`DELETE /managed-cluster-types/v1/:id`

Success: 204.

Delete an existing Managed Cluster Type.
