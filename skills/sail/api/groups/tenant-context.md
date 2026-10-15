# Tenant Context

The purpose of this API is to manage key-value pairs specific to a tenant's context, enabling dynamic configuration and personalized settings per tenant.

2 endpoints. Paths are relative to the environment API host.

## Retrieve tenant context

`GET /tenant-context/v1`

Success: 200.

Returns all key-value pairs representing the current state of the tenant's context.
Each tenant is limited to a maximum of 100 key-value pairs.

## Update tenant context

`PATCH /tenant-context/v1`

Success: 200.

Allows the user to make incremental updates to tenant context records using JSON Patch syntax.

This endpoint is specifically designed to modify the `/Key/*` field, supporting operations such as `add`, `remove`, or `replace` to manage key-value pairs.

Note that each tenant is limited to a maximum of 100 key-value pairs.

Body:

```json
[
  {
    "op": "add",
    "path": "/Key/IAS",
    "value": "Integrated Automation System"
  },
  {
    "op": "replace",
    "path": "/Key/IAS",
    "value": "International Accounting Standards"
  },
  {
    "op": "remove",
    "path": "/Key/NDR"
  }
]
```
