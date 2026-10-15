# Work Items

Use this API to implement work item functionality.

13 endpoints. Paths are relative to the environment API host.

## List work items

`GET /work-items/v1`

Success: 200.

This gets a collection of work items belonging to either the specified user(admin required), or the current user.

Query:

- standard: `limit`, `offset`, `count`
- `ownerId`: ID of the work item owner.

## Completed work items

`GET /work-items/v1/completed`

Success: 200.

This gets a collection of completed work items belonging to either the specified user(admin required), or the current user.

Query:

- standard: `limit`, `offset`, `count`
- `ownerId`: The id of the owner of the work item list being requested. Either an admin, or the owning/current user must make this request.

## Count work items

`GET /work-items/v1/count`

Success: 200.

This gets a count of work items belonging to either the specified user(admin required), or the current user.

Query:

- `ownerId`: ID of the work item owner.

## Count completed work items

`GET /work-items/v1/completed/count`

Success: 200.

This gets a count of completed work items belonging to either the specified user(admin required), or the current user.

Query:

- `ownerId`: ID of the work item owner.

## Work items summary

`GET /work-items/v1/summary`

Success: 200.

This gets a summary of work items belonging to either the specified user(admin required), or the current user.

Query:

- `ownerId`: ID of the work item owner.

## Get a work item

`GET /work-items/v1/:id`

Success: 200.

This gets the details of a Work Item belonging to either the specified user(admin required), or the current user.

## Complete a work item

`POST /work-items/v1/:id`

Success: 200.

This API completes a work item. Either an admin, or the owning/current user must make this request.

Body:

```
string
```

## Approve an approval item

`POST /work-items/v1/:id/approve/:approvalItemId`

Success: 200.

This API approves an Approval Item. Either an admin, or the owning/current user must make this request.

## Reject an approval item

`POST /work-items/v1/:id/reject/:approvalItemId`

Success: 200.

This API rejects an Approval Item. Either an admin, or the owning/current user must make this request.

## Bulk approve approval items

`POST /work-items/v1/bulk-approve/:id`

Success: 200.

This API bulk approves Approval Items. Either an admin, or the owning/current user must make this request.

## Bulk reject approval items

`POST /work-items/v1/bulk-reject/:id`

Success: 200.

This API bulk rejects Approval Items. Either an admin, or the owning/current user must make this request.

## Submit account selections

`POST /work-items/v1/:id/submit-account-selection`

Success: 200.

This API submits account selections. Either an admin, or the owning/current user must make this request.

Body:

```json
{
  "fieldName": "fieldValue"
}
```

## Forward a work item

`POST /work-items/v1/:id/forward`

Success: 200.

This API forwards a work item to a new owner. Either an admin, or the owning/current user must make this request.

Body:

```json
{
  "targetOwnerId": "2c9180835d2e5168015d32f890ca1581",
  "comment": "I'm going on vacation.",
  "sendNotifications": true
}
```
