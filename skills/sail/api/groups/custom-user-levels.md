# Custom User Levels

Use this API to implement custom user level functionality.

9 endpoints. Paths are relative to the environment API host.

## Create a custom user level

`POST /authorization/v1/custom-user-levels`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Creates a new custom user level for the tenant.

Body:

```json
{
  "name": "Identity And Access Management",
  "description": "This is a description of the custom user level.",
  "owner": {
    "id": "29b9da8273b441239238bc041c386817",
    "name": "John Doe"
  },
  "rightSets": [
    "idn:ui-identity-manage-example",
    "idn:ui-identity-manage-child-one-example"
  ]
}
```

## List user levels

`GET /authorization/v1/custom-user-levels`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Retrieves a list of user levels for the tenant.

Query:

- standard: `limit`, `offset`
- `detailLevel`: Specifies the level of detail for the user levels. (This can only be one of FULL,SLIM)
- filters: name (co); owner (co); status (eq); description (co)
- sorters: name, created, description, status, owner

## Publish a custom user level

`POST /authorization/v1/custom-user-levels/:id/publish`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Publishes a custom user level for the tenant, making it active and available.

## Retrieve a user level

`GET /authorization/v1/custom-user-levels/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Fetches the details of a specific user level by its ID.

## Delete a user level

`DELETE /authorization/v1/custom-user-levels/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

Deletes a specific user level by its ID.

## Update a user level

`PATCH /authorization/v1/custom-user-levels/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Updates the details of a specific user level using JSON Patch.

Body:

```json
[
  {
    "op": "replace",
    "path": "/rightSets",
    "value": [
      "idn:ui-identity-manage-example"
    ]
  }
]
```

## List all uiAssignable right sets

`GET /authorization/v1/authorization-assignable-right-sets`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Retrieves a list of authorization assignable right sets for the tenant.

Query:

- standard: `limit`, `offset`
- filters: category (eq)
- sorters: id, name, category

## List user level identities

`GET /authorization/v1/user-levels/:id/identities`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

List of identities associated with a user level.

Query:

- standard: `limit`, `offset`, `count`
- sorters: displayName

## Count user levels identities

`POST /authorization/v1/user-levels/get-identity-count`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

List of user levels along with the number of identities associated to it.

Body:

```json
[
  "HELPDESK",
  "ORG_ADMIN",
  "sp:ui-config-hub-admin"
]
```
