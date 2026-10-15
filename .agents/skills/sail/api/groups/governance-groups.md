# Governance Groups

Use this API to implement and customize Governance Group functionality.

10 endpoints. Paths are relative to the environment API host.

## List governance groups

`GET /workgroups/v1`

Success: 200.

This API returns list of Governance Groups

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in, sw); name (eq, sw, in); memberships.identityId (eq, in)
- sorters: name, created, modified, id, description

## Create a new governance group.

`POST /workgroups/v1`

Success: 200.

This API creates a new Governance Group.

Body:

```json
{
  "owner": {
    "type": "IDENTITY",
    "id": "2c9180a46faadee4016fb4e018c20639",
    "name": "Support"
  },
  "name": "DB Access Governance Group",
  "description": "Description of the Governance Group",
  "created": "2022-01-06T19:51:13Z",
  "modified": "2022-01-06T19:51:13Z"
}
```

## Get governance group by id

`GET /workgroups/v1/:id`

Success: 200.

This API returns a Governance Groups by its ID.

## Delete a governance group

`DELETE /workgroups/v1/:id`

Success: 204.

This API deletes a Governance Group by its ID.

## Patch a governance group

`PATCH /workgroups/v1/:id`

Success: 200.

This API updates an existing governance group by ID. The following fields and objects are patchable:
* name
* description
* owner

Body:

```json
[
  {
    "op": "replace",
    "path": "/description",
    "value": "Governance Group new description."
  }
]
```

## Delete governance group(s)

`POST /workgroups/v1/bulk-delete`

Success: 207.

This API initiates a bulk deletion of one or more Governance Groups.

>  If any of the indicated Governance Groups have one or more connections associated with it,then those Governance Groups will be added in  **inUse** list of the response. Governance Group(s) marked as **inUse** can not be deleted.

>  If any of the indicated Governance Groups is not does not exists in Organization,then those Governance Groups will be added in **notFound** list of the response. Governance Groups marked as **notFound** will not be deleted.

>  If any of the indicated Governance Groups does not have any connections associated with it,then those Governance Groups will be added in **deleted** list of the response. A Governance Group marked as **deleted** will be deleted from current Organization.

>  If the request contains any **inUse** or **notFound** Governance Group IDs then it skips only these Governance Groups for deletion and deletes the rest of Governance Groups which have no connections associated with it.

>  **This API has limit number of Governance Groups can be deleted at one time. If the request contains more then 100 Governance Groups IDs to be deleted then the API will throw an exception.**

Body:

```json
{
  "ids": [
    "567a697e-885b-495a-afc5-d55e1c23a302",
    "c7b0f7b2-1e78-4063-b294-a555333dacd2"
  ]
}
```

## List connections for governance group

`GET /workgroups/v1/:workgroupId/connections`

Success: 200.

This API returns list of connections associated with a Governance Group.

Query:

- standard: `limit`, `offset`, `count`
- sorters: name, created, modified

## List governance group members

`GET /workgroups/v1/:workgroupId/members`

Success: 200.

This API returns list of members associated with a Governance Group.

Query:

- standard: `limit`, `offset`, `count`
- sorters: name, created, modified

## Add members to governance group

`POST /workgroups/v1/:workgroupId/members/bulk-add`

Success: 207.

This API adds one or more members to a Governance Group.  A token with API, ORG_ADMIN authority is required to call this API.

>  **Following field of Identity is an optional field in the request.**

>  **name**

Body:

```json
[
  {
    "type": "IDENTITY",
    "id": "464ae7bf791e49fdb74606a2e4a89635",
    "name": "Addie Smith"
  }
]
```

## Remove members from governance group

`POST /workgroups/v1/:workgroupId/members/bulk-delete`

Success: 207.

This API removes one or more  members from a Governance Group.  A
>  **Following field of Identity is an optional field in the request.**

>  **name**

Body:

```json
[
  {
    "type": "IDENTITY",
    "id": "464ae7bf791e49fdb74606a2e4a89635",
    "name": "Addie Smith"
  }
]
```
