# IAI Role Mining

25 endpoints. Paths are relative to the environment API host.

## Create a role mining session

`POST /role-mining-sessions/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 201.

This submits a create role mining session request to the role mining application.

Body:

```json
{
  "scope": {
    "identityIds": [
      "2c918090761a5aac0176215c46a62d58",
      "2c918090761a5aac01722015c46a62d42"
    ],
    "criteria": "source.name:DataScienceDataset"
  },
  "pruneThreshold": 50,
  "prescribedPruneThreshold": 10,
  "minNumIdentitiesInPotentialRole": 20,
  "potentialRoleCount": 0,
  "potentialRolesReadyCount": 0,
  "type": "SPECIALIZED",
  "emailRecipientId": "2c918090761a5aac0176215c46a62d58",
  "identityCount": 0,
  "saved": true,
  "name": "Saved RM Session - 07/10"
}
```

## Retrieves all role mining sessions

`GET /role-mining-sessions/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Returns all role mining sessions that match the query parameters

Query:

- standard: `limit`, `offset`, `count`
- filters: saved (eq); name (eq, sw)
- sorters: createdBy, createdDate

## Patch a role mining session

`PATCH /role-mining-sessions/v1/:sessionId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

The  method updates an existing role mining session using PATCH. Supports op in {"replace"} and changes to pruneThreshold and/or minNumIdentitiesInPotentialRole. The potential roles in this role mining session is then re-calculated.

Body:

```json
[
  {
    "op": "replace",
    "path": "/pruneThreshold",
    "value": "83"
  },
  {
    "op": "replace",
    "path": "/minNumIdentitiesInPotentialRole",
    "value": "10"
  },
  {
    "op": "replace",
    "path": "/saved",
    "value": "false"
  },
  {
    "op": "replace",
    "path": "/name",
    "value": "RM Session - 07/10/22"
  },
  {
    "op": "add",
    "path": "/name",
    "value": "RM Session - 07/10/22"
  }
]
```

## Get a role mining session

`GET /role-mining-sessions/v1/:sessionId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

The method retrieves a role mining session.

## Get role mining session status state

`GET /role-mining-sessions/v1/:sessionId/status`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method returns a role mining session status for a customer.

## Retrieves all potential role summaries (GET /role-mining-sessions/v1/:sessionId/potential-role-summaries)

`GET /role-mining-sessions/v1/:sessionId/potential-role-summaries`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method returns the potential role summaries for a role mining session.

Query:

- standard: `limit`, `offset`, `count`
- sorters: createdDate
- filters: createdById (eq, sw, co); createdByName (eq, sw, co); description (sw, co); endDate (le, lt); freshness (eq, ge, gt, le, lt); name (eq, sw, co); quality (eq, ge, gt, le, lt); startDate (ge, gt); saved (eq); type (eq)

## Retrieves a specific potential role (GET /role-mining-sessions/v1/:sessionId/potential-role-summaries/:potentialRoleId)

`GET /role-mining-sessions/v1/:sessionId/potential-role-summaries/:potentialRoleId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method returns a specific potential role for a role mining session.

## Update a potential role session

`PATCH /role-mining-sessions/v1/:sessionId/potential-role-summaries/:potentialRoleId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

The method updates an existing potential role using.

The following fields can be modified:

* `description`

* `name`

* `saved`

>**NOTE: All other fields cannot be modified.**

Body:

```json
[
  {
    "op": "remove",
    "path": "/description"
  },
  {
    "op": "replace",
    "path": "/description",
    "value": "Acct I - Potential Role"
  },
  {
    "op": "remove",
    "path": "/saved"
  },
  {
    "op": "replace",
    "path": "/saved",
    "value": "false"
  },
  {
    "op": "remove",
    "path": "/name"
  },
  {
    "op": "replace",
    "path": "/name",
    "value": "Potential Role Accounting"
  }
]
```

## Retrieves the applications of a potential role for a role mining session

`GET /role-mining-sessions/v1/:sessionId/potential-role-summaries/:potentialRoleId/applications`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method returns the applications of a potential role for a role mining session.

Query:

- standard: `limit`, `offset`, `count`
- filters: applicationName (sw)

## Retrieves the entitlements of a potential role for a role mining session

`GET /role-mining-sessions/v1/:sessionId/potential-role-summaries/:potentialRoleId/entitlements`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method returns the entitlements of a potential role for a role mining session.

Query:

- standard: `limit`, `offset`, `count`
- filters: entitlementRef.name (sw)

## Retrieves entitlements for a potential role in a role mining session

`GET /role-mining-sessions/v1/:sessionId/potential-roles/:potentialRoleId/entitlement-popularities`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method returns entitlements for a potential role in a role mining session.

Query:

- standard: `limit`, `offset`, `count`
- `includeCommonAccess`: Boolean determining whether common access entitlements will be included or not
- sorters: popularity, entitlementName, applicationName
- filters: applicationName (sw); entitlementRef.name (sw)

## Retrieves entitlement popularity distribution for a potential role in a role mining session

`GET /role-mining-sessions/v1/:sessionId/potential-roles/:potentialRoleId/entitlement-popularity-distribution`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method returns entitlement popularity distribution for a potential role in a role mining session.

Query:

- `includeCommonAccess`: Boolean determining whether common access entitlements will be included or not

## Edit entitlements for a potential role to exclude some entitlements

`POST /role-mining-sessions/v1/:sessionId/potential-roles/:potentialRoleId/edit-entitlements`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 201.

This endpoint adds or removes entitlements from an exclusion list for a potential role.

Body:

```json
{
  "ids": [
    "entId1",
    "entId2"
  ],
  "exclude": true
}
```

## Retrieves identities for a potential role in a role mining session

`GET /role-mining-sessions/v1/:sessionId/potential-roles/:potentialRoleId/identities`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method returns identities for a potential role in a role mining session.

Query:

- standard: `limit`, `offset`, `count`
- sorters: name
- filters: name (sw)

## Export (download) details for a potential role in a role mining session (GET /role-mining-sessions/v1/:sessionId/potential-roles/:potentialRoleId/export)

`GET /role-mining-sessions/v1/:sessionId/potential-roles/:potentialRoleId/export`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This endpoint downloads all the information for a potential role in a role mining session. Includes identities and entitlements in the potential role.

## Asynchronously export details for a potential role in a role mining session and upload to S3

`POST /role-mining-sessions/v1/:sessionId/potential-roles/:potentialRoleId/export-async`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

This endpoint uploads all the information for a potential role in a role mining session to S3 as a downloadable zip archive.  Includes identities and entitlements in the potential role.

Body:

```json
{
  "minEntitlementPopularity": 0,
  "includeCommonAccess": true
}
```

## Retrieve status of a potential role export job

`GET /role-mining-sessions/v1/:sessionId/potential-roles/:potentialRoleId/export-async/:exportId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This endpoint retrieves information about the current status of a potential role export.

## Export (download) details for a potential role in a role mining session (GET /role-mining-sessions/v1/:sessionId/potential-roles/:potentialRoleId/export-async/:exportId/download)

`GET /role-mining-sessions/v1/:sessionId/potential-roles/:potentialRoleId/export-async/:exportId/download`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This endpoint downloads a completed export of information for a potential role in a role mining session.

## Create request to provision a potential role into an actual role.

`POST /role-mining-sessions/v1/:sessionId/potential-roles/:potentialRoleId/provision`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

This method starts a job to provision a potential role

Query:

- `min-entitlement-popularity`: Minimum popularity required for an entitlement to be included in the provisioned role.
- `include-common-access`: Boolean determining whether common access entitlements will be included in the provisioned role.

Body:

```json
{
  "roleName": "Finance - Accounting",
  "roleDescription": "General access for accounting department",
  "ownerId": "2b568c65bc3c4c57a43bd97e3a8e41",
  "includeIdentities": true,
  "directlyAssignedEntitlements": false
}
```

## Retrieves excluded entitlements for a potential role in a role mining session

`GET /role-mining-sessions/v1/:sessionId/potential-roles/:potentialRoleId/excluded-entitlements`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method returns excluded entitlements for a potential role in a role mining session.

Query:

- standard: `limit`, `offset`, `count`
- sorters: popularity
- filters: applicationName (sw); entitlementRef.name (sw)

## Retrieves all potential role summaries (GET /role-mining-potential-roles/v1)

`GET /role-mining-potential-roles/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Returns all potential role summaries that match the query parameters

Query:

- standard: `limit`, `offset`, `count`
- sorters: createdDate, identityCount, entitlementCount, freshness, quality
- filters: createdById (eq, sw, co); createdByName (eq, sw, co); description (sw, co); endDate (le, lt); freshness (eq, ge, gt, le, lt); name (eq, sw, co, ge, gt, le, lt); quality (eq, ge, gt, le, lt); startDate (ge, gt); saved (eq); type (eq, ge, gt, le, lt); scopingMethod (eq); sessionState (eq); identityAttribute (co)

## Retrieves a specific potential role (GET /role-mining-potential-roles/v1/:potentialRoleId)

`GET /role-mining-potential-roles/v1/:potentialRoleId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method returns a specific potential role.

## Update a potential role

`PATCH /role-mining-potential-roles/v1/:potentialRoleId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

The method updates an existing potential role using.

The following fields can be modified:

* `description`

* `name`

* `saved`

>**NOTE: All other fields cannot be modified.**

Body:

```json
[
  {
    "op": "remove",
    "path": "/description"
  },
  {
    "op": "replace",
    "path": "/description",
    "value": "Acct I - Potential Role"
  },
  {
    "op": "remove",
    "path": "/saved"
  },
  {
    "op": "replace",
    "path": "/saved",
    "value": "false"
  },
  {
    "op": "remove",
    "path": "/name"
  },
  {
    "op": "replace",
    "path": "/name",
    "value": "Potential Role Accounting"
  }
]
```

## Retrieves all saved potential roles

`GET /role-mining-potential-roles/v1/saved`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method returns all saved potential roles (draft roles).

Query:

- standard: `limit`, `offset`, `count`
- sorters: modified

## Retrieves potential role source usage

`GET /role-mining-potential-roles/v1/:potentialRoleId/sources/:sourceId/identityUsage`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method returns source usageCount (as number of days in the last 90 days) for each identity in a potential role.

Query:

- standard: `limit`, `offset`, `count`
- sorters: displayName, email, usageCount
