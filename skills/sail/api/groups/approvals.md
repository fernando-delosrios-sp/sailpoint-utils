# Approvals

Use this API to implement approval functionality.

15 endpoints. Paths are relative to the environment API host.

## Get approvals

`GET /generic-approvals/v1`

Success: 200.

Gets a list of approvals.

One of the following query parameters should be present: 'mine', 'approverId', 'requesterId', 'requesteeId'.

The absence of all query parameters for non admins will default to mine=true (which is the equivalent of 'approverId=[your_identity_id]')
while admins will default to mine=false (which will show all approvals in the org).

For lookups by access request ID please use the following:

'/generic-approvals?mine=false&filters=referenceType+eq+"accessRequestId"+and+referenceId+eq+"12345678901234567890123456789012"'

Query:

- standard: `limit`, `offset`, `count`
- `mine`: Determines whether to return the list of approvals assigned to the current caller or all approvals in the org. Defaults to false if admin, true otherwise (which is the equivalent of 'approverId=[your_identity_id]').
- `requesterId`: Returns the list of approvals for a given requester ID. Must match the calling user's identity ID unless they are an admin.
- `requesteeId`: Returns the list of approvals for a given requesteeId ID. Must match the calling user's identity ID unless they are an admin.
- `approverId`: Returns the list of approvals for a given approverId ID. Must match the calling user's identity ID unless they are an admin.
- `count-only`: Adds X-Total-Count to the header to give the amount of total approvals returned from the query. Only returns the count and no approval objects.
- `include-comments`: If set to true in the query, the approval requests returned will include comments.
- `include-approvers`: If set to true in the query, the approval requests returned will include approvers.
- `include-reassignment-history`: If set to true in the query, the approval requests returned will include reassignment history.
- `include-batch-info`: If set to true in the query, the approval requests returned will include batch information.
- filters: status (eq, ne, in, co, sw); name (eq, ne, in, co, sw); priority (eq, ne, in, co, sw); type (eq, ne, in, co, sw); medium (eq, ne, in, co, sw); description (eq, ne, in, co, sw); batchId (eq, ne, in, co, sw); createdDate (eq, ne, in, co, sw, gt, ge, lt, le); dueDate (eq, ne, in, co, sw, gt, ge, lt, le); completedDate (eq, ne, in, co, sw, gt, ge, lt, le); search (eq, ne, in, co, sw); referenceId (eq, ne, in, co, sw); referenceType (eq, ne, in, co, sw); referenceName (eq, ne, in, co, sw); requestedTargetId (eq, ne, in, co, sw); requestedTargetType (eq, ne, in, co, sw); requestedTargetName (eq, ne, in, co, sw); requestedTargetRequestType (eq, ne, in, co, sw); modifiedDate (eq, ne, in, co, sw, gt, ge, lt, le); decisionDate (eq, ne, in, co, sw, gt, ge, lt, le); approvalId (eq, ne, in, co, sw); requesterId (eq, ne, in, co, sw); requesteeId (eq, ne, in, co, sw); approverId (eq, ne, in, co, sw)

## Get an approval

`GET /generic-approvals/v1/:id`

Success: 200.

Fetches an approval request by it's approval ID. For lookups by access request ID please use the following:
/generic-approvals?filters=referenceType+eq+"accessRequestId"+and+referenceId+eq+"12345678901234567890123456789012"

## Post Approvals Approve

`POST /generic-approvals/v1/:id/approve`

Success: 200.

Approves a specified approval request on behalf of the caller. The approval request must be in a state that allows it to be approved. This endpoint does not support access request IDs.
If called by an admin and the admin is not listed as an approver, the approval request will be reassigned from a random approver to the admin user.

Body:

```json
{
  "additionalAttributes": {
    "additionalProp1": "string",
    "additionalProp2": "string",
    "additionalProp3": "string"
  },
  "comment": "comment",
  "overrideApproverID": "12345678901234567890123456789012"
}
```

## Post Approvals Attributes

`POST /generic-approvals/v1/:id/attributes`

Success: 200.

Allows for the edit/addition/removal of the key/value pair additional attributes map for an existing approval request. This endpoint does not support access request IDs.

Body:

```json
{
  "additionalAttributes": {
    "additionalProp1": "string",
    "additionalProp2": "string",
    "additionalProp3": "string"
  },
  "comment": "comment",
  "removeAttributeKeys": [
    "string"
  ]
}
```

## Post Approvals Comments

`POST /generic-approvals/v1/:id/comments`

Success: 200.

Adds comments to a specified approval request. This endpoint does not support access request IDs.

Body:

```json
{
  "comment": "Approval comment."
}
```

## Post Approvals Reassign

`POST /generic-approvals/v1/:id/reassign`

Success: 204.

Reassigns an approval request to another identity resulting in that identity being added as an authorized approver. This endpoint does not support access request IDs.

Body:

```json
{
  "comment": "comment",
  "reassignFrom": "384532516be25f8fdf935ce19e295837",
  "reassignTo": "152354832eb6f8f539fd738592e19ec5"
}
```

## Post Approvals Reject

`POST /generic-approvals/v1/:id/reject`

Success: 204.

Rejects a specified approval request on behalf of the caller. This endpoint does not support access request IDs.
If called by an admin and the admin is not listed as an approver, the approval request will be reassigned from a random approver to the admin user and approved.

Body:

```json
{
  "comment": "string",
  "overrideApproverID": "12345678901234567890123456789012"
}
```

## Post Approval Cancel

`POST /generic-approvals/v1/:id/cancel`

Success: 204.

Cancels a specified approval requests on behalf of the caller.
Note: This endpoint does not support access request IDs. To cancel access request approvals, please use the following:
/access-requests/cancel

Body:

```json
{
  "comment": "Cancelled by administrator"
}
```

## Get Approval Config

`GET /generic-approvals/v1/config/:id`

Success: 200.

Retrieves a singular approval configuration that matches the given ID

## Put Approval Config

`PUT /generic-approvals/v1/config/:id/:scope`

Success: 200.

Upserts a singular approval configuration that matches the given configID and configScope.
For example to update the approval configurations for all Access Request Approvals please use: '/generic-approvals/config/ACCESS_REQUEST_APPROVAL/APPROVAL_TYPE'

Body:

```json
{
  "reminderConfig": {
    "enabled": false,
    "daysUntilFirstReminder": 0,
    "reminderCronSchedule": "@every 24h",
    "maxReminders": 5
  },
  "escalationConfig": {
    "enabled": true,
    "daysUntilFirstEscalation": 2,
    "escalationCronSchedule": "@every 72h",
    "escalationChain": [
      {
        "identityId": "fdfda352157d4cc79bb749953131b457",
        "identityType": "IDENTITY"
      },
      {
        "identityId": "fdfda352157d4cc79bb749953131b457",
        "identityType": "IDENTITY"
      }
    ]
  },
  "timeoutConfig": {
    "enabled": true,
    "daysUntilTimeout": 2,
    "timeoutResult": "EXPIRED"
  },
  "cronTimezone": {
    "location": "America/New_York",
    "offset": ""
  },
  "serialChain": [
    {
      "identityId": "2c9180858090ea8801809a0465e829da",
      "identityType": "IDENTITY"
    },
    {
      "identityId": "2c9180858090ea8801809a0465e829da",
      "identityType": "IDENTITY"
    }
  ],
  "requiresComment": "ALL",
  "fallbackApprover": {
    "identityID": "fdfda352157d4cc79bb749953131b457",
    "type": "MANAGER_OF"
  },
  "machineIdentityManagerAssignment": "MACHINE_IDENTITY_OWNER",
  "circumventApprovalProcess": false,
  "autoApprove": "OFF"
}
```

## Delete Approval Configuration

`DELETE /generic-approvals/v1/config/:id/:scope`

Success: 204.

Deletes an approval configuration.
Configurations at the APPROVAL_REQUEST scope cannot be deleted.

## Post Bulk Approve Approvals

`POST /generic-approvals/v1/bulk-approve`

Success: 202.

Bulk Approves specified approval requests on behalf of the caller

Body:

```json
{
  "approvalIds": [
    "38453251-6be2-5f8f-df93-5ce19e295837",
    "38453251-6be2-5f8f-df93-5ce19e295838"
  ],
  "comment": "Bulk approved by admin for monthly review",
  "additionalAttributes": {
    "source": "automation",
    "urgency": "high"
  }
}
```

## Post Bulk Reject Approvals

`POST /generic-approvals/v1/bulk-reject`

Success: 202.

Bulk reject specified approval requests on behalf of the caller

Body:

```json
{
  "approvalIds": [
    "38453251-6be2-5f8f-df93-5ce19e295837",
    "38453251-6be2-5f8f-df93-5ce19e295838"
  ],
  "comment": "Bulk reject by admin"
}
```

## Post Bulk Cancel Approvals

`POST /generic-approvals/v1/bulk-cancel`

Success: 202.

Bulk cancels specified approval requests on behalf of the caller.
Note: To bulk cancel access request approvals, please use the following:
/access-requests/bulk-cancel

Body:

```json
{
  "approvalIds": [
    "38453251-6be2-5f8f-df93-5ce19e295837",
    "38453251-6be2-5f8f-df93-5ce19e295838"
  ],
  "comment": "Bulk cancellation by admin"
}
```

## Post Bulk Reassign Approvals

`POST /generic-approvals/v1/bulk-reassign`

Success: 202.

Bulk reassigns specified approval requests on behalf of the caller

Body:

```json
{
  "approvalIds": [
    "38453251-6be2-5f8f-df93-5ce19e295837",
    "38453251-6be2-5f8f-df93-5ce19e295838"
  ],
  "comment": "Bulk reassignment by admin",
  "reassignFrom": "12353251-6be2-5f8f-df93-5ce19b6e5837",
  "reassignTo": "32454251-6ce2-5d8f-df93-5ce19e295238"
}
```
