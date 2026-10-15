# Role Insights

9 endpoints. Paths are relative to the environment API host.

## Generate insights for roles

`POST /role-insights/v1/requests`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 201.

Submits a create role insights request to the role insights application. At this time there are no parameters. All business roles will be processed for the customer.

## Returns metadata from prior request.

`GET /role-insights/v1/requests/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This endpoint returns details of a prior role insights request.

## Get role insights summary information

`GET /role-insights/v1/summary`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method returns high level summary information for role insights for a customer.

## Get role insights

`GET /role-insights/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method returns detailed role insights for each role.

Query:

- standard: `limit`, `offset`, `count`
- sorters: numberOfUpdates, identitiesWithAccess, totalNumberOfIdentities
- filters: name (sw); ownerName (sw); description (sw)

## Get a single role insight

`GET /role-insights/v1/:insightId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This endpoint gets role insights information for a role.

## Get entitlement insights for a role

`GET /role-insights/v1/:insightId/entitlement-changes`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This endpoint returns entitlement insights for a role.

Query:

- sorters: identitiesWithAccess, name
- filters: name (sw); description (sw)

## Download entitlement insights for a role

`GET /role-insights/v1/:insightId/entitlement-changes/download`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This endpoint returns the entitlement insights for a role.

Query:

- sorters: identitiesWithAccess
- filters: name (sw); description (sw)

## Get current entitlement for a role

`GET /role-insights/v1/:insightId/current-entitlements`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This endpoint gets the entitlements for a role. The term "current" is to distinguish from the entitlement(s) an insight might recommend adding.

Query:

- filters: name (sw); description (sw)

## Get identities for a suggested entitlement (for a role)

`GET /role-insights/v1/:insightId/entitlement-changes/:entitlementId/identities`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Role insights suggests entitlements to be added for a role. This endpoint returns a list of identities in the role, with or without the entitlements, for a suggested entitlement so that the user can see which identities would be affected if the suggested entitlement were to be added to the role.

Query:

- standard: `limit`, `offset`, `count`
- `hasEntitlement`: Identity has this entitlement or not
- sorters: name
- filters: name (sw)
