# Requestable Objects

Use this API to implement requestable object functionality.

1 endpoints. Paths are relative to the environment API host.

## Requestable objects list

`GET /requestable-objects/v1`

Success: 200.

Get a list of acccess items that can be requested through the Access Request endpoints. Access items are marked with `AVAILABLE`, `PENDING` or `ASSIGNED` with respect to the identity provided using `identity-id` query parameter.
This endpoint only lists roles and access profiles. For gathering requestable entitlements, the Entitlements List API can be used with the segmented-for-identity parameter.
Any authenticated token can call this endpoint to see their requestable access items.

Query:

- standard: `limit`, `offset`, `count`
- `identity-id`: If present, the value returns only requestable objects for the specified identity. * Admin users can call this with any identity ID value. * Non-admin users can only specify *me* or pass their own identity ID value. * If absent, returns a…
- `types`: Filters the results to the specified type/types, where each type is one of `ROLE` or `ACCESS_PROFILE`. If absent, all types are returned. SailPoint may add support for additional types in the future without notice.
- `term`: Allows searching requestable access items with a partial match on the name or description. If `term` is provided, then the API will ignore the `filter` query parameter.
- `statuses`: Filters the result to the specified status/statuses, where each status is one of `AVAILABLE`, `ASSIGNED`, or `PENDING`. Specifying this parameter without also specifying an `identity-id` parameter results in an error. SailPoint may add…
- filters: id (eq, in); name (eq, in, sw)
- sorters: name
