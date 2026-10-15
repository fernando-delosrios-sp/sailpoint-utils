# Account Activities

Use this API to implement account activity tracking functionality.

2 endpoints. Paths are relative to the environment API host.

## List account activities

`GET /account-activities/v1`

Success: 200.

This gets a collection of account activities that satisfy the given query parameters.

Query:

- standard: `limit`, `offset`, `count`
- `requested-for`: The identity that the activity was requested for. *me* indicates the current user. Mutually exclusive with *regarding-identity*.
- `requested-by`: The identity that requested the activity. *me* indicates the current user. Mutually exclusive with *regarding-identity*.
- `regarding-identity`: The specified identity will be either the requester or target of the account activity. *me* indicates the current user. Mutually exclusive with *requested-for* and *requested-by*.
- filters: type (eq, in, ge, le, lt, ne, isnull, sw); created (gt, lt, ge, le, eq, in, ne, isnull, sw); modified (gt, lt, ge, le, eq, in, ne, isnull, sw)
- sorters: type, created, modified

## Get an account activity

`GET /account-activities/v1/:id`

Success: 200.

This gets a single account activity by its id.
