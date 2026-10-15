# Machine Identity Lifecycle Actions

Experimental APIs for machine identity lifecycle requests (`ACTIVATE`, `DEACTIVATE`), including approval and provisioning status.

4 endpoints. Paths are relative to the environment API host.

## Submit machine identity lifecycle action

`POST /machine-identities/v1/:id/lifecycle-actions`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

Creates a lifecycle request for the target machine identity and returns the created lifecycle
snapshot.

The response includes the generated `requestId`, which is used by

 and

Authorization is enforced in the service layer. Callers must have the
`idn:machine-identity-lifecycle-action:manage` scope or role-context access to the target machine
identity (organization admin, source admin, scoped source sub-admin, or effective owner).

Supported actions are `DEACTIVATE`, `ACTIVATE`.

Body:

```json
{
  "action": "DEACTIVATE",
  "comments": [
    {
      "comment": "Suspending agent until security review completes"
    }
  ]
}
```

## List lifecycle actions

`GET /machine-identities/v1/lifecycle-actions`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Lists lifecycle requests visible to the requester identity in the current request context.

Results are automatically scoped to the calling identity. If requester identity context is
missing, an empty list is returned.

When `limit` is omitted, this endpoint applies a default limit of 50.

Query:

- standard: `limit`, `offset`, `count`
- filters: resourceType (eq, in); operationType (eq, in); status (eq, in); completed (eq); targetId (eq); targetName (eq, sw); sourceId (eq); created (gt, ge, lt, le)
- sorters: created, modified, status

## Get lifecycle action by requestId

`GET /machine-identities/v1/lifecycle-actions/:requestId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Returns one lifecycle request snapshot by `requestId`. Used for request-level inspection,
including cancel acceptance and subsequent status changes.

The original requester is always allowed to read their request. Otherwise, callers must have
the `idn:machine-identity-lifecycle-action:manage` scope **and** role-context access to the target
machine identity (organization admin, source admin, scoped source sub-admin, or effective owner).

**403 Forbidden**

- `FORBIDDEN.lifecycle-request-access-denied` - caller is not the submitter and lacks both the
  `idn:machine-identity-lifecycle-action:manage` scope and target role-context (response includes `requestId` as a parameter).
- `FORBIDDEN.unsupported-type` - the persisted lifecycle row is not scoped to `AI_AGENT`
  (`targetType` on read-by-request-id paths).

**404 Not Found**

- `NOT_FOUND.detailed` - unknown `requestId`, or persisted `targetType` does not match the
  target machine identity's subtype-to-resource-type mapping.

## Cancel lifecycle action

`POST /machine-identities/v1/lifecycle-actions/:requestId/cancel`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

Attempts to cancel a lifecycle request before provisioning starts.

The path `requestId` is authoritative for lookup and authorization. The request body is
optional and may carry cancel metadata such as `comment`. Any `requestId` value in the body is
ignored.

Workflow cancel signaling is attempted before the request is persisted as `CANCELING`. If
signaling fails, the service returns **503** (`DOWNSTREAM_SERVICE_UNAVAILABLE`, cause
`workflow-signal-failed`) and the lifecycle request status is unchanged.

Invalid cancel states are returned as **400** (`INVALID_REQUEST_IN_CURRENT_STATE` variants).

Cancel authorization matches
the original submitter is always allowed; otherwise callers must have the
`idn:machine-identity-lifecycle-action:manage` scope **and** target role-context access.

**403 Forbidden**

- `FORBIDDEN.lifecycle-request-access-denied` - caller is not the submitter and lacks both the
  `idn:machine-identity-lifecycle-action:manage` scope and target role-context.
- `FORBIDDEN.unsupported-type` - the persisted lifecycle row is not scoped to `AI_AGENT`.

**404 Not Found**

- `NOT_FOUND.detailed` - unknown `requestId`, or persisted `targetType`/target-identity subtype
  mismatch.

Body:

```json
{
  "comment": "Cancelling - will resubmit after maintenance window"
}
```
