# Machine Identities

18 endpoints. Paths are relative to the environment API host.

## List machine identities (GET /machine-identities/v1)

`GET /machine-identities/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns a list of machine identities.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in, sw); displayName (eq, in, sw); cisIdentityId (eq, in, sw); nativeIdentity (eq, in, sw); attributes (eq); manuallyEdited (eq); subtype (eq, in); owners.primaryIdentity.id (eq, in, sw); owners.primaryIdentity.name (eq, in, isnull, pr); owners.secondaryIdentity.id (eq, in, sw); owners.secondaryIdentity.name (eq, in, isnull, pr); source.name (eq, in, sw); source.id (eq, in); entitlement.id (eq, in); entitlement.name (eq, in, sw)
- sorters: nativeIdentity, name, owners.primaryIdentity.name, source.name, created, modified

## Create machine identity (POST /machine-identities/v1)

`POST /machine-identities/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to create a machine identity.
The maximum supported length for the description field is 2000 characters.

Body:

```json
{
  "name": "aName",
  "nativeIdentity": "abc:123:dddd",
  "subtype": "Application",
  "description": "",
  "attributes": {},
  "owners": {
    "primaryIdentity": {
      "type": "IDENTITY",
      "id": "2c91808568c529c60168cca6f90c1313",
      "name": "William Wilson"
    },
    "secondaryIdentities": [
      {
        "type": "IDENTITY",
        "id": "2c91808568c529c60168cca6f90c1313",
        "name": "William Wilson"
      },
      {
        "type": "IDENTITY",
        "id": "2c91808568c529c60168cca6f90c1313",
        "name": "William Wilson"
      }
    ]
  },
  "sourceId": "6d28b7c1-620c-49c6-b6d5-cbf81eb4b5fa",
  "uuid": "f5dd23fe-3414-42b7-bb1c-869400ad7a10",
  "userEntitlements": [
    {
      "entitlementId": "6d28b7c1-620c-49c6-b6d5-cbf81eb4b5fa",
      "sourceId": "5898b7c1-620c-49c6-cccc-cbf81eb4bddd"
    },
    {
      "entitlementId": "6d28b7c1-620c-49c6-b6d5-cbf81eb4b5fa",
      "sourceId": "5898b7c1-620c-49c6-cccc-cbf81eb4bddd"
    }
  ]
}
```

## Get machine identity details (GET /machine-identities/v1/:id)

`GET /machine-identities/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns a single machine identity using the Machine Identity ID.

## Update machine identity details

`PATCH /machine-identities/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to update machine identity details.

Body:

```json
[
  {
    "op": "add",
    "path": "/attributes/securityRisk",
    "value": "medium"
  }
]
```

## Delete machine identity (DELETE /machine-identities/v1/:id)

`DELETE /machine-identities/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

The API returns successful response if the requested machine identity was deleted.

## List machine identity anomalies

`GET /machine-identities/v1/:id/anomalies`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Returns a paginated list of anomalies detected for the specified machine identity (agent).

Set **count=true** to populate the *X-Total-Count* response header with the total number of anomalies for the agent. Combine **limit=0** with **count=true** to retrieve only the count with an empty result body.

Query:

- standard: `limit`, `offset`, `count`
- sorters: detectedAt

## Get unsanctioned application anomaly summary

`GET /machine-identities/v1/anomaly-summaries/unsanctioned`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Returns aggregate counts (distinct agents, distinct owners, and total events) for anomalies of type **unsanctioned_app** across the tenant. Powers the Unsanctioned Agents card on the Agent Registry page.

## List machine identities (GET /machine-identities/v2)

`GET /machine-identities/v2`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns a list of machine identities.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in, sw); displayName (eq, in, sw); nativeIdentity (eq, in, sw); attributes (eq); manuallyEdited (eq); subtype (eq, in); owners.primaryIdentity.id (eq, in, sw); owners.primaryIdentity.name (eq, in, isnull, pr); owners.secondaryIdentity.id (eq, in, sw); owners.secondaryIdentity.name (eq, in, isnull, pr); owners.secondaryGovernanceGroup.id (eq, in); owners.secondaryGovernanceGroup.name (eq, in, isnull, pr); source.id (eq, in); source.name (eq, in, sw); entitlement.id (eq, in); entitlement.name (eq, in, sw); risk.severity (eq, in); businessApplicationRefs.id (eq); effectiveSanctionedStatus (eq); sessionCount (eq, gt, ge, lt, le, isnull); suspiciousSessionCount (eq, gt, ge, lt, le, isnull); entroId (eq); insights (eq)
- sorters: nativeIdentity, name, owners.primaryIdentity.name, source.name, created, modified, sessionCount, suspiciousSessionCount

## Create machine identity (POST /machine-identities/v2)

`POST /machine-identities/v2`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 201.

Use this API to create a machine identity. Additional owners may be either up to ten human (IDENTITY) references or exactly one GOVERNANCE_GROUP reference - not both. The maximum supported length for the description field is 2000 characters.

When Business Applications is enabled for the tenant, callers may optionally include a single `businessApplicationRefs` entry (`type`=`BUSINESS_APPLICATION`, `id`=BA UUID). The assignment is stored as a `MANUAL` correlation. `correlationType` may be omitted or `MANUAL`; `AUTOMATIC` is rejected (`400`). Unknown BA id returns `404`. More than one ref returns `400`. When Business Applications is not enabled, supplying `businessApplicationRefs` returns `400`. `sanctionedStatus` and `effectiveSanctionedStatus` are read-only and ignored on input.

Body:

```json
{
  "name": "aName",
  "description": "Service account for nightly batch jobs",
  "attributes": {
    "privilegeLevel": "HIGH",
    "region": "APAC"
  },
  "connectorAttributes": {
    "objectguid": "abc-123"
  },
  "manuallyEdited": true,
  "manuallyCreated": true,
  "owners": {
    "primary": {
      "name": "John Doe",
      "type": "IDENTITY"
    },
    "secondary": [
      {
        "name": "Jane Doe",
        "type": "IDENTITY"
      }
    ]
  },
  "subtype": "AI_AGENT",
  "sourceId": "6d28b7c1-620c-49c6-b6d5-cbf81eb4b5fa",
  "uuid": "f5dd23fe-3414-42b7-bb1c-869400ad7a10",
  "nativeIdentity": "abc:123:dddd",
  "datasetId": "8886e5e3-63d0-462f-a195-d98da885b8dc",
  "environment": "PRODUCTION",
  "existsOnSource": "TRUE",
  "status": "ACTIVE",
  "resource": {
    "id": "8886e5e3-63d0-462f-a195-d98da885b8dc",
    "type": "aws:iam-role",
    "name": "nightly-batch-role",
    "features": [
      "PROVISIONING",
      "AUTHENTICATION"
    ]
  },
  "source": {
    "name": "Active Directory",
    "type": "SOURCE"
  },
  "userEntitlements": [
    {
      "sourceId": "5898b7c1-620c-49c6-cccc-cbf81eb4bddd",
      "entitlementId": "6d28b7c1-620c-49c6-b6d5-cbf81eb4b5fa",
```

Body example truncated.

## Get machine identity details (GET /machine-identities/v2/:id)

`GET /machine-identities/v2/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns a single machine identity using the Machine Identity ID.

## Partial update of machine identity

`PATCH /machine-identities/v2/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to selectively update machine identity details using a JSONPatch payload.

Patchable fields include **name**, **description**, **nativeIdentity**, **subtype**, **environment**, **attributes**, **owners**, **userEntitlements**, **manuallyEdited**, and **businessApplicationRefs** (when Business Applications is enabled for the tenant).

When Business Applications is enabled for the tenant, `/businessApplicationRefs` may be replaced with at most one MANUAL Business Application
reference, or cleared with an empty array. Patching `/businessApplicationRefs` when Business Applications is not enabled returns `400`.
Existing `AUTOMATIC` correlations cannot be overridden (`400` / `ILLEGAL_UPDATE_ATTEMPT`). Unknown BA id returns `404`.

`entroId`, `insights`, `sessionCount`, and `suspiciousSessionCount` are read-only. A patch that targets them is rejected
with `400`; aggregation is the only writer. `entroRiskBand`, `agentSource`, and `integrationType` are not response fields.

Body:

```json
[
  {
    "op": "add",
    "path": "/attributes/securityRisk",
    "value": "medium"
  }
]
```

## Delete machine identity (DELETE /machine-identities/v2/:id)

`DELETE /machine-identities/v2/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

The API returns a successful response if the requested machine identity was deleted.

## List ownership correlation configs

`GET /sources/v1/:sourceId/resources/:resourceId/correlation-configs`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Returns the OWNER_PRIMARY and OWNER_SECONDARY correlation configs for the specified source resource, creating default rows if they are missing. Use the optional type query parameter to return a single matching config.

Query:

- standard: `limit`, `offset`, `count`
- `type`: When set, filters to the given config type. (This can only be one of OWNER_PRIMARY,OWNER_SECONDARY)

## Get ownership correlation config

`GET /sources/v1/:sourceId/resources/:resourceId/correlation-configs/:configId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This end-point retrieves a single ownership correlation config by ID for the specified source resource.

## Patch ownership correlation config

`PATCH /sources/v1/:sourceId/resources/:resourceId/correlation-configs/:configId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Selectively updates an ownership correlation config using an RFC 6902 JSONPatch payload. Only replace on /attributes (full object) and replace on /rules (full array; merge by stable rule id, remove rules omitted from the array) are allowed.

Body:

```json
[
  {
    "op": "replace",
    "path": "/attributes",
    "value": {
      "syncPrimaryToMachineAccounts": true
    }
  }
]
```

## Delete ownership correlation config

`DELETE /sources/v1/:sourceId/resources/:resourceId/correlation-configs/:configId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

Deletes the ownership correlation config with the specified ID for the given source resource.

## Start machine identity aggregation

`POST /sources/v1/:sourceId/aggregate-agents`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Starts a machine identity (AI Agents) aggregation on the specified source.

Body:

```json
{
  "datasetIds": [
    "source:datasetId12345",
    "source:datasetId12345"
  ],
  "disableOptimization": false
}
```

## List machine identity's user entitlements

`GET /machine-identity-user-entitlements/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns a list of user entitlements associated with machine identities.

Query:

- standard: `limit`, `offset`, `count`
- filters: machineIdentityId (eq, in); machineIdentityName (eq, in, sw); entitlement.id (eq, in); entitlement.name (eq, in, sw); source.id (eq, in); source.name (eq, in, sw)
- sorters: machineIdentityName, entitlement.name, source.name
