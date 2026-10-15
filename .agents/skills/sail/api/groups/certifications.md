# Certifications

Use this API to implement certification functionality.

11 endpoints. Paths are relative to the environment API host.

## List identity campaign certifications

`GET /certifications/v1`

Success: 200.

Use this API to get a list of identity campaign certifications for the specified query parameters. Any authenticated token can call this API, but only certifications you are authorized to review will be returned. This API does not support requests for certifications assigned to governance groups.

Query:

- standard: `limit`, `offset`, `count`
- `reviewer-identity`: Reviewer's identity. *me* indicates the current user.
- filters: id (eq, in); campaign.id (eq, in); phase (eq); completed (eq)
- sorters: name, due, signed

## Identity certification by id

`GET /certifications/v1/:id`

Success: 200.

This API returns a single identity campaign certification by its ID. Reviewers for this certification can also call this API.

## List of access review items

`GET /certifications/v1/:id/access-review-items`

Success: 200.

This API returns a list of access review items for an identity campaign certification. Reviewers for this certification can also call this API. This API does not support requests for certifications assigned to Governance Groups.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in); type (eq); access.type (eq); completed (eq, ne); identitySummary.id (eq, in); identitySummary.name (eq, sw); access.id (eq, in); access.name (eq, sw); entitlement.sourceName (eq, sw); accessProfile.sourceName (eq, sw)
- sorters: identitySummary.name, access.name, access.type, entitlement.sourceName, accessProfile.sourceName
- `entitlements`: Filter results to view access review items that pertain to any of the specified comma-separated entitlement IDs. An error will occur if this param is used with **access-profiles** or **roles** as only one of these query params can be used…
- `access-profiles`: Filter results to view access review items that pertain to any of the specified comma-separated access-profle IDs. An error will occur if this param is used with **entitlements** or **roles** as only one of these query params can be used…
- `roles`: Filter results to view access review items that pertain to any of the specified comma-separated role IDs. An error will occur if this param is used with **entitlements** or **access-profiles** as only one of these query params can be used…

## Decide on a certification item

`POST /certifications/v1/:id/decide`

Success: 200.

The API makes a decision to approve or revoke one or more identity campaign certification items. Reviewers for this certification can also call this API. This API does not support requests for certifications assigned to Governance Groups.

Body:

```json
[
  {
    "id": "ef38f94347e94562b5bb8424a56396b5",
    "decision": "APPROVE",
    "bulk": true,
    "comments": "This user still needs access to this source."
  },
  {
    "id": "ef38f94347e94562b5bb8424a56397d8",
    "decision": "APPROVE",
    "bulk": true,
    "comments": "This user still needs access to this source too."
  }
]
```

## Reassign identities or items

`POST /certifications/v1/:id/reassign`

Success: 200.

This API reassigns up to 50 identities or items in an identity campaign certification to another reviewer. A token with ORG_ADMIN or CERT_ADMIN authority is required to call this API. Reviewers for this certification can also call this API. This API does not support requests for certifications assigned to Governance Groups.

Body:

```json
{
  "reassign": [
    {
      "id": "ef38f94347e94562b5bb8424a56397d8",
      "type": "ITEM"
    },
    {
      "id": "ef38f94347e94562b5bb8424a56397d8",
      "type": "ITEM"
    }
  ],
  "reassignTo": "ef38f94347e94562b5bb8424a56397d8",
  "reason": "reassigned for some reason"
}
```

## Finalize identity certification decisions

`POST /certifications/v1/:id/sign-off`

Success: 200.

This API finalizes all decisions made on an identity campaign certification and initiates any remediations required. Reviewers for this certification can also call this API. This API does not support requests for certifications assigned to Governance Groups.

## Permissions for entitlement certification item

`GET /certifications/v1/:certificationId/access-review-items/:itemId/permissions`

Success: 200.

This API returns the permissions associated with an entitlement certification item based on the certification item's ID. Reviewers for this certification can also call this API.

Query:

- standard: `limit`, `offset`, `count`
- filters: target (eq, sw); rights (ca)

## List of reviewers for certification

`GET /certifications/v1/:id/reviewers`

Success: 200.

This API returns a list of reviewers for the certification. Reviewers for this certification can also call this API.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in); name (eq, sw); email (eq, sw)
- sorters: name, email

## Reassign certifications asynchronously

`POST /certifications/v1/:id/reassign-async`

Success: 200.

This API initiates a task to reassign up to 500 identities or items in an identity campaign certification to another
reviewer. The `certification-tasks` API can be used to get an updated status on the task and determine when the
reassignment is complete.

Reviewers for this certification can also call this API.

Body:

```json
{
  "reassign": [
    {
      "id": "ef38f94347e94562b5bb8424a56397d8",
      "type": "ITEM"
    },
    {
      "id": "ef38f94347e94562b5bb8424a56397d8",
      "type": "ITEM"
    }
  ],
  "reassignTo": "ef38f94347e94562b5bb8424a56397d8",
  "reason": "reassigned for some reason"
}
```

## Certification task by id

`GET /certification-tasks/v1/:id`

Success: 200.

This API returns the certification task for the specified ID. Reviewers for the specified certification can also call this API.

## List of pending certification tasks

`GET /certification-tasks/v1`

Success: 200.

This API returns a list of pending (`QUEUED` or `IN_PROGRESS`) certification tasks. Any authenticated token can call this API, but only certification tasks you are authorized to review will be returned.

Query:

- standard: `limit`, `offset`, `count`
- `reviewer-identity`: The ID of reviewer identity. *me* indicates the current user.
- filters: id (eq, in); targetId (eq, in); type (eq, in)
