# IAI Common Access

3 endpoints. Paths are relative to the environment API host.

## Get a paginated list of common access

`GET /common-access/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This endpoint returns the current common access for a customer. The returned items can be filtered and sorted. Requires authorization scope of iai:access-modeling:read

Query:

- standard: `limit`, `offset`, `count`
- filters: status (eq, sw); access.id (eq, sw); access.type (eq); access.name (sw, eq); access.description (sw, eq)
- sorters: access.name, status

## Create common access items

`POST /common-access/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

This API is used to add roles/access profiles to the list of common access for a customer. Requires authorization scope of iai:access-modeling:create

Body:

```json
{
  "access": {
    "id": "string",
    "type": "ACCESS_PROFILE",
    "name": "string",
    "description": "string",
    "ownerName": "string",
    "ownerId": "string"
  },
  "status": "CONFIRMED"
}
```

## Bulk update common access status

`POST /common-access/v1/update-status`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

This submits an update request to the common access application. At this time there are no parameters. Requires authorization scope of iai:access-modeling:update

Body:

```json
[
  {
    "confirmedIds": [
      "c0207a4b-f48e-fc1c-b218-004f716c54f6",
      "a77c356c-78f9-a1cb-4975-306ab8691846"
    ],
    "deniedIds": [
      "29aa36de-7b52-28c5-0869-e945ea96a42a",
      "3ba35b4d-5fed-308e-3e9a-013c25332731"
    ]
  },
  {
    "confirmedIds": [
      "cf9d2063-61bb-293a-ee03-151ed8841575",
      "66812b6a-8ca7-f28f-af56-7393d9e6badb"
    ],
    "deniedIds": [
      "4acf7cc8-b268-5df6-dd2e-ad73c7c30a19",
      "80e02574-2862-24c0-137b-8ae4b993a22a"
    ]
  }
]
```
