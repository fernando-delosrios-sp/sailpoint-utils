# Public Machine Identities

Use this API to list machine identities with a reduced, public-safe payload for catalog and request workflows.

1 endpoints. Paths are relative to the environment API host.

## List public machine identities

`GET /public-machine-identities/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Get a list of machine identities with a reduced public payload (`id`, `name`, `description`, and optionally `subtype` and the primary `owner`). Any authenticated user with the default scope can call this endpoint; it does not require the `idn:mis-identity:read` scope.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in); name (eq, sw); subtype (eq); owner.id (eq); owner (eq)
- sorters: id, name, subtype
