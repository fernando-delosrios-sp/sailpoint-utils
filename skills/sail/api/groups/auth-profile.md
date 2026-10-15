# Auth Profile

Use this API to implement Auth Profile functionality.

3 endpoints. Paths are relative to the environment API host.

## Get list of auth profiles

`GET /auth-profiles/v1`

Success: 200.

This API returns a list of auth profiles.

## Get auth profile

`GET /auth-profiles/v1/:id`

Success: 200.

This API returns auth profile information.

## Patch a specified auth profile

`PATCH /auth-profiles/v1/:id`

Success: 200.

This API updates an existing Auth Profile. The following fields are patchable:
**offNetwork**, **untrustedGeography**, **applicationId**, **applicationName**, **type**

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
