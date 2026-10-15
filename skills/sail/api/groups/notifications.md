# Notifications

18 endpoints. Paths are relative to the environment API host.

## Get notification template variables

`GET /notification-template-variables/v1/:key/:medium`

Success: 200.

Returns global variables and template-specific variables for a given notification template key and medium.
Use these variable names in template content; they are replaced at send time with the corresponding values.
Variable lists can be sorted by key, type, or description via the sorters query parameter (default ascending by key).

Query:

- sorters: key, type, description

## Change mail from domain

`PUT /mail-from-attributes/v1`

Success: 200.

Change the MAIL FROM domain of an AWS SES email identity and provide the MX and TXT records to be placed in the caller's DNS

Body:

```json
{
  "identity": "BobSmith@sailpoint.com",
  "mailFromDomain": "example.sailpoint.com"
}
```

## Get mail from attributes

`GET /mail-from-attributes/v1/:identity`

Success: 200.

Retrieve MAIL FROM attributes for a given AWS SES identity.

## List notification template defaults

`GET /notification-template-defaults/v1`

Success: 200.

This lists the default templates used for notifications, such as emails from IdentityNow.

Query:

- standard: `limit`, `offset`
- filters: key (eq, in, sw); medium (eq, sw); locale (eq, sw)

## List notification templates

`GET /notification-templates/v1`

Success: 200.

This lists the templates that you have modified for your site.

Query:

- standard: `limit`, `offset`
- filters: key (eq, in, sw); medium (eq, sw); locale (eq, sw)
- sorters: key, name, medium

## Create notification template

`POST /notification-templates/v1`

Success: 200.

This will update notification templates that are available in your tenant.
Note that you cannot create new templates in your tenant, but you can use this to create custom notifications from existing templates.  First, copy the response body from the get notification template endpoint for a template you wish to update and paste it into the request body for this endpoint.
Modify the fields you want to change and submit the POST request when ready.

Body:

```json
{
  "key": "cloud_manual_work_item_summary",
  "medium": "EMAIL",
  "locale": "en",
  "name": "Task Manager Subscription",
  "subject": "You have $numberOfPendingTasks $taskTasks to complete in ${__global.productName}.",
  "header": null,
  "body": "Please go to the task manager",
  "footer": null,
  "from": "$__global.emailFromAddress",
  "replyTo": "$__global.emailFromAddress",
  "description": "Daily digest - sent if number of outstanding tasks for task owner > 0",
  "id": "c17bea3a-574d-453c-9e04-4365fbf5af0b",
  "created": "2020-01-01T00:00:00.000000Z",
  "modified": "2020-01-01T00:00:00.000000Z",
  "slackTemplate": {
    "key": "string",
    "text": "You have a new approval request",
    "blocks": "string",
    "attachments": "[]",
    "notificationType": "string",
    "approvalId": "string",
    "requestId": "string",
    "requestedById": "string",
    "isSubscription": false,
    "autoApprovalData": {
      "isAutoApproved": "string",
      "itemId": "string",
      "itemType": "string",
      "autoApprovalMessageJSON": "string",
      "autoApprovalTitle": "string"
    },
    "customFields": {
      "requestType": "string",
      "containsDeny": "string",
```

Body example truncated.

## Get notification template by id

`GET /notification-templates/v1/:id`

Success: 200.

This gets a template that you have modified for your site by Id.

## Bulk delete notification templates

`POST /notification-templates/v1/bulk-delete`

Success: 204.

This lets you bulk delete templates that you previously created for your site.

Body:

```json
[
  {
    "key": "cloud_manual_work_item_summary",
    "medium": "EMAIL",
    "locale": "en"
  },
  {
    "key": "cloud_manual_work_item_summary",
    "medium": "EMAIL",
    "locale": "en"
  }
]
```

## Get notification template context

`GET /notification-template-context/v1`

Success: 200.

The notification service maintains metadata to construct the notification templates or supply any information during the event propagation. The data-store where this information is retrieved is called "Global Context" (a.k.a. notification template context). It defines a set of attributes
 that will be available per tenant (organization).

## List notification preferences for tenant

`GET /notification-preferences/v1`

Success: 200.

Returns a list of notification preferences for the current tenant, including preferred mediums and optional CC/BCC email recipients for each notification key. Supports standard V3 filtering, sorting, and offset/limit pagination.

Query:

- standard: `limit`, `offset`, `count`
- filters: key (eq, in)
- sorters: key

## Get notification preferences by key

`GET /notification-preferences/v1/:key`

Success: 200.

Returns the notification preferences for a specific notification key, including preferred mediums and optional CC/BCC email recipients. If no custom preferences exist, returns the default settings from the interest definition. If the key does not exist, a 404 is returned.

Query:

- `filterUnavailableMediums`: When `true`, excludes SLACK and TEAMS from the returned mediums if they are not configured for the tenant.

## Set notification preferences by key

`PUT /notification-preferences/v1/:key`

Success: 200.

Overwrites the notification preferences for a specific notification key. Controls which mediums are enabled and optional CC/BCC email recipients. The `key` property in the request body is optional; if provided, it must match the key in the path or a 400 is returned. Each of `ccList` and `bccList` supports a maximum of five entries, and the same recipient cannot appear in both lists. CC/BCC configuration requires EMAIL to be enabled in `mediums` and is only allowed for templates which support it (i.e., templates which contain sensitive data like reset tokens do not allow for carbon copy emails to be configured).

Body:

```json
{
  "key": "approval_completed_notification",
  "mediums": [
    "EMAIL"
  ],
  "ccList": [
    {
      "type": "IDENTITY",
      "id": "6b0b8e47cc1f4c3fa961a38fc718e989"
    },
    {
      "type": "STATIC_EMAIL",
      "email": "cc-recipient@example.com"
    }
  ],
  "bccList": [
    {
      "type": "MANAGER_OF"
    }
  ]
}
```

## Send test notification

`POST /send-test-notification/v1`

Success: 204.

Send a Test Notification

Body:

```json
{
  "key": "cloud_manual_work_item_summary",
  "medium": "EMAIL",
  "context": {
    "numberOfPendingTasks": "4",
    "ownerId": "201327fda1c44704ac01181e963d463c"
  }
}
```

## List from addresses

`GET /verified-from-addresses/v1`

Success: 200.

Retrieve a list of sender email addresses and their verification statuses

Query:

- standard: `limit`, `offset`, `count`
- filters: email (eq, ge, le, gt, lt)
- sorters: email

## Create verified from address

`POST /verified-from-addresses/v1`

Success: 201.

Create a new sender email address and initiate verification process.

Body:

```json
{
  "email": "sender@example.com"
}
```

## Delete verified from address

`DELETE /verified-from-addresses/v1/:id`

Success: 204.

Delete a verified sender email address

## Get dkim attributes

`GET /verified-domains/v1`

Success: 200.

Retrieve DKIM (DomainKeys Identified Mail) attributes for all your tenants' AWS SES identities. Limits retrieval to 100 identities per call.

Query:

- standard: `limit`, `offset`

## Verify domain address via dkim

`POST /verified-domains/v1`

Success: 200.

Create a domain to be verified via DKIM (DomainKeys Identified Mail)

Body:

```json
{
  "domain": "sailpoint.com"
}
```
