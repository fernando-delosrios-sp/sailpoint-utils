# Access Request Approvals

Use this API to implement and customize access request approval functionality.

7 endpoints. Paths are relative to the environment API host.

## Pending access request approvals list

`GET /access-request-approvals/v1/pending`

Success: 200.

This endpoint returns a list of pending approvals. See "owner-id" query parameter below for authorization info.
For access requests for machines, each approval will include `identityType` as `MACHINE` and `requestedFor` with `type: MACHINE_IDENTITY` and the machine id. Approvals without a stored identity type are returned as `HUMAN` / `IDENTITY`.
When a requested object has an associated form, each approval may include a `form` object with the form definition ID, instance ID, and answers (`formData`).

Query:

- standard: `limit`, `offset`, `count`
- `owner-id`: If present, the value returns only pending approvals for the specified identity. * ORG_ADMIN users can call this with any identity ID value. * ORG_ADMIN users can also fetch all the approvals in the org, when owner-id is not used. *…
- filters: id (eq, in); requestedFor.id (eq, in); modified (gt, lt, ge, le, eq, in); accessRequestId (eq, in); created (gt, lt, ge, le, eq, in)
- sorters: created, modified

## Completed access request approvals list

`GET /access-request-approvals/v1/completed`

Success: 200.

This endpoint returns list of completed approvals. See *owner-id* query parameter below for authorization info. For access requests for machines, each approval will include 'identityType' as 'MACHINE' and 'requestedFor' with 'type: MACHINE_IDENTITY' and the machine id. Approvals without a stored identity type are returned as 'HUMAN' / 'IDENTITY'.
When a requested object has an associated form, each approval may include a `form` object with the form definition ID, instance ID, and answers (`formData`).

Query:

- standard: `limit`, `offset`, `count`
- `owner-id`: If present, the value returns only completed approvals for the specified identity. * ORG_ADMIN users can call this with any identity ID value. * ORG_ADMIN users can also fetch all the approvals in the org, when owner-id is not used. *…
- filters: id (eq, in, ge, gt, le, lt, ne, isnull, sw); requestedFor.id (eq, in, ge, gt, le, lt, ne, isnull, sw); modified (gt, lt, ge, le, eq, in, ne, sw)
- sorters: created, modified

## Approve access request approval

`POST /access-request-approvals/v1/:approvalId/approve`

Success: 202.

Use this endpoint to approve an access request approval. Only the owner of the approval and ORG_ADMIN users are allowed to perform this action.

Body:

```json
{
  "comment": "This is a comment.",
  "created": "2017-07-11T18:45:37.098Z"
}
```

## Reject access request approval

`POST /access-request-approvals/v1/:approvalId/reject`

Success: 202.

Use this API to reject an access request approval. Only the owner of the approval and admin users are allowed to perform this action.

Body:

```json
{
  "comment": "This is a comment.",
  "created": "2017-07-11T18:45:37.098Z"
}
```

## Forward access request approval

`POST /access-request-approvals/v1/:approvalId/forward`

Success: 202.

Use this API to forward an access request approval to a new owner. Only the owner of the approval and ORG_ADMIN users are allowed to perform this action. Only the owner of the approval and ORG_ADMIN users are allowed to perform this action.

Body:

```json
{
  "newOwnerId": "2c91808568c529c60168cca6f90c1314",
  "comment": "2c91808568c529c60168cca6f90c1313"
}
```

## Get access requests approvals number

`GET /access-request-approvals/v1/approval-summary`

Success: 200.

Use this API to return the number of pending, approved and rejected access requests approvals. See the "owner-id" query parameter for authorization information. info.

Query:

- `owner-id`: The ID of the owner or approver identity of the approvals. If present, the value returns approval summary for the specified identity. * ORG_ADMIN users can call this with any identity ID value. * ORG_ADMIN user can also fetch all the…
- `from-date`: This is the date and time the results will be shown from. It must be in a valid ISO-8601 format.

## Access request approvers

`GET /access-request-approvals/v1/:accessRequestId/approvers`

Success: 200.

This API endpoint returns the list of approvers for the given access request id.

Query:

- standard: `limit`, `offset`, `count`
