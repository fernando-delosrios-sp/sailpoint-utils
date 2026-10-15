# Work Reassignment

Use this API to implement work reassignment functionality.

9 endpoints. Paths are relative to the environment API host.

## List reassignment config types

`GET /reassignment-configurations/v1/types`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Gets a collection of types which are available in the Reassignment Configuration UI.

## List reassignment configurations

`GET /reassignment-configurations/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Gets a paginated list of Reassignment configurations for the current org.

Query:

- standard: `limit`, `offset`, `count`

## Create a reassignment configuration

`POST /reassignment-configurations/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 201.

Creates a new Reassignment Configuration for the specified identity.

Body:

```json
{
  "reassignedFromId": "2c91808781a71ddb0181b9090b5c504e",
  "reassignedToId": "2c91808781a71ddb0181b9090b53504a",
  "configType": "ACCESS_REQUESTS",
  "startDate": "2022-07-21T11:13:12.345Z",
  "endDate": "2022-07-30T17:00:00.000Z"
}
```

## Get reassignment configuration

`GET /reassignment-configurations/v1/:identityId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Gets the Reassignment Configuration for an identity.

## Update reassignment configuration

`PUT /reassignment-configurations/v1/:identityId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Replaces existing Reassignment configuration for an identity with the newly provided configuration.

Body:

```json
{
  "reassignedFromId": "2c91808781a71ddb0181b9090b5c504e",
  "reassignedToId": "2c91808781a71ddb0181b9090b53504a",
  "configType": "ACCESS_REQUESTS",
  "startDate": "2022-07-21T11:13:12.345Z",
  "endDate": "2022-07-30T17:00:00.000Z"
}
```

## Delete reassignment configuration

`DELETE /reassignment-configurations/v1/:identityId/:configType`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

Deletes a single reassignment configuration for the specified identity

## Evaluate reassignment configuration

`GET /reassignment-configurations/v1/:identityId/evaluate/:configType`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Evaluates the Reassignment Configuration for an `Identity` to determine if work items for the specified type should be reassigned. If a valid Reassignment Configuration is found for the identity & work type, then a lookup is initiated which recursively fetches the Reassignment Configuration for the next `TargetIdentity` until no more results are found or a max depth of 5. That lookup trail is provided in the response and the final reassigned identity in the lookup list is returned as the `reassignToId` property. If no Reassignment Configuration is found for the specified identity & config type then the requested Identity ID will be used as the `reassignToId` value and the lookupTrail node will be empty.

Query:

- `exclusionFilters`: Exclusion filters that disable parts of the reassignment evaluation. Possible values are listed below: - `SELF_REVIEW_DELEGATION`: This will exclude delegations of self-review reassignments

## Get tenant-wide reassignment configuration settings

`GET /reassignment-configurations/v1/tenant-config`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Gets the global Reassignment Configuration settings for the requestor's tenant.

## Update tenant-wide reassignment configuration settings

`PUT /reassignment-configurations/v1/tenant-config`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Replaces existing Tenant-wide Reassignment Configuration settings with the newly provided settings.

Body:

```json
{
  "configDetails": {
    "disabled": true
  }
}
```
