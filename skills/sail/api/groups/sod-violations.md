# SOD Violations

Use this API to check for current "separation of duties" (SOD) policy violations as well as potential future SOD policy violations.

7 endpoints. Paths are relative to the environment API host.

## Predict sod violations for identity.

`POST /sod-violations/v1/predict`

Success: 200.

This API is used to check if granting some additional accesses (entitlements, access profiles, or roles) would cause the subject to be in violation of any SOD policies. Returns the violations that would be caused.

Body:

```json
{
  "identityId": "2c91808568c529c60168cca6f90c1313",
  "accessRefs": [
    {
      "type": "ENTITLEMENT",
      "id": "2c918087682f9a86016839c050861ab1"
    },
    {
      "type": "ACCESS_PROFILE",
      "id": "2c918087682f9a86016839c0509c1ab2"
    },
    {
      "type": "ROLE",
      "id": "2c918087682f9a86016839c050a01ab3"
    }
  ]
}
```

## Check sod violations

`POST /sod-violations/v1/check`

Success: 202.

This API initiates a SOD policy verification asynchronously.

Body:

```json
{
  "identityId": "2c91808568c529c60168cca6f90c1313",
  "accessRefs": [
    {
      "type": "ENTITLEMENT",
      "id": "2c918087682f9a86016839c050861ab1"
    },
    {
      "type": "ACCESS_PROFILE",
      "id": "2c918087682f9a86016839c0509c1ab2"
    },
    {
      "type": "ROLE",
      "id": "2c918087682f9a86016839c050a01ab3"
    }
  ],
  "clientMetadata": {
    "additionalProp1": "string",
    "additionalProp2": "string",
    "additionalProp3": "string"
  }
}
```

## List Policy Violations

`GET /violations/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Returns a paged list of policy violations for the current tenant. Requires the read scope (idn:sod-violation:read).
This endpoint uses the standard collection parameters defined in V3 API Standard Collection Parameters.
This endpoint supports standard V3 collection parameters: `limit`, `offset`, `count`, `filters`, and `sorters`.
Embedded references in each violation (`owner`, `target`, `policy`, and references inside `appliedControls`) follow the `ReferenceResponse` schema: `id` and `type` are always present; `name` is included when display metadata resolves.
Filters and sorters are validated against a fixed whitelist of fields to ensure safe queries and to align with underlying database indexes.

Query:

- standard: `limit`, `offset`, `count`
- filters: status (eq, in); policyId (eq); ownerId (eq); level (eq, in); policyName (eq, in, sw, co); ownerName (eq, in, sw, co); targetName (eq, in, sw, co); targetId (eq, in)
- sorters: level

## List My Policy Violations

`GET /my-violations/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Returns a paged list of policy violations where the current user is the owner (directly assigned or via a governance group they belong to). No permission scope is required; caller identity is required.
Supports the same collection parameters as GET /violations (limit, offset, count, filters, sorters), including the same filter field whitelist and processing (normalization, pruning of not-yet-persisted name predicates). The owner filter is implicit (current user); **do not** use `ownerId` in filters for this endpoint.
Embedded references in each violation follow `ReferenceResponse` (`id`, `type`, and optional `name` when metadata resolves).

Query:

- standard: `limit`, `offset`, `count`
- filters: status (eq, in); policyId (eq); level (eq, in); policyName (eq, in, sw, co); ownerName (eq, in, sw, co); targetName (eq, in, sw, co); targetId (eq, in)
- sorters: level

## Get policy violation by ID

`GET /violations/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Returns a single policy violation by ID for the current tenant. Access is allowed if the caller has the read scope (`idn:sod-violation:read`) or is an owner of the violation (direct or via governance group). Returns 403 Forbidden if the violation exists but the caller has neither the read scope nor ownership. Returns 404 Not Found if the violation does not exist for the tenant.
Embedded references (`owner`, `target`, `policy`, and references inside `appliedControls`) use `ReferenceResponse`: `id` and `type` are always present; `name` is included when display metadata resolves.

## Apply control to violation

`POST /violations/v1/:id/controls`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 201.

Applies a compensating control to the specified policy violation. Callers without the `idn:sod-violation:manage` scope may only apply a control to violations they own (directly, or via a governance group they belong to).

Body:

```json
{
  "control": "3e07886555ed43cfb83c85c58d2016e6",
  "comments": "Some comments about the applied control"
}
```

## Reassign policy violation

`POST /violations/v1/:id/reassign`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200, 204.

Reassigns the specified policy violation to a new owner. Callers without the `idn:sod-violation:manage` scope may only reassign violations they own (directly, or via a governance group they belong to).

Body:

```json
{
  "reassignTo": {
    "assigneeId": "3e07886555ed43cfb83c85c58d2016e6",
    "assigneeType": "IDENTITY"
  },
  "comments": "some comments about the reassignment"
}
```
