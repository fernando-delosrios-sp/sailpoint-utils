# Triggers

Event Triggers provide real-time updates to changes in Identity Security Cloud so you can take action as soon as an event occurs, rather than poll an API endpoint for updates.

10 endpoints. Paths are relative to the environment API host.

## List triggers

`GET /triggers/v1`

Success: 200.

Gets a list of triggers that are available in the tenant.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, ge, le)
- sorters: id, name

## Create a subscription

`POST /trigger-subscriptions/v1`

Success: 201.

This API creates a new subscription to a trigger and defines trigger invocation details. The type of subscription determines which config object is required:
* HTTP subscriptions require httpConfig
* EventBridge subscriptions require eventBridgeConfig

Body:

```json
{
  "name": "Access request subscription",
  "description": "Access requested to site xyz",
  "triggerId": "idn:access-requested",
  "type": "HTTP",
  "httpConfig": {
    "url": "https://www.example.com",
    "httpDispatchMode": "SYNC",
    "httpAuthenticationType": "BASIC_AUTH",
    "basicAuthConfig": {
      "userName": "user@example.com",
      "password": "eRtg4%6yuI!"
    }
  },
  "enabled": true,
  "filter": "$[?($.identityId == \"201327fda1c44704ac01181e963d463c\")]"
}
```

## List subscriptions

`GET /trigger-subscriptions/v1`

Success: 200.

Gets a list of all trigger subscriptions.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq); triggerId (eq); type (eq, le)
- sorters: triggerId, triggerName

## Update a subscription

`PUT /trigger-subscriptions/v1/:id`

Success: 200.

This API updates a trigger subscription in IdentityNow, using a full object representation. In other words, the existing
  Subscription is completely replaced. The following fields are immutable:

  * id

  * triggerId

  Attempts to modify these fields result in 400.

Body:

```json
{
  "name": "Access request subscription",
  "description": "Access requested to site xyz",
  "type": "HTTP",
  "httpConfig": {
    "url": "https://www.example.com",
    "httpDispatchMode": "SYNC",
    "httpAuthenticationType": "BASIC_AUTH",
    "basicAuthConfig": {
      "userName": "user@example.com",
      "password": "eRtg4%6yuI!"
    }
  },
  "enabled": true,
  "filter": "$[?($.identityId == \"201327fda1c44704ac01181e963d463c\")]"
}
```

## Patch a subscription

`PATCH /trigger-subscriptions/v1/:id`

Success: 200.

This API updates a trigger subscription in IdentityNow, using a set of instructions to modify a subscription partially. The following fields are patchable:

**name**, **description**, **enabled**, **type**, **filter**, **responseDeadline**, **httpConfig**, **eventBridgeConfig**, **workflowConfig**

Body:

```json
[
  {
    "op": "replace",
    "path": "/description",
    "value": "A new description"
  },
  {
    "op": "replace",
    "path": "/name",
    "value": "A new name"
  }
]
```

## Delete a subscription

`DELETE /trigger-subscriptions/v1/:id`

Success: 204.

Deletes an existing subscription to a trigger.

## Validate a subscription filter

`POST /trigger-subscriptions/v1/validate-filter`

Success: 200.

Validates a JSONPath filter expression against a provided mock input.
Request requires a security scope of:

Body:

```json
{
  "input": {
    "identityId": "201327fda1c44704ac01181e963d463c"
  },
  "filter": "$[?($.identityId == \"201327fda1c44704ac01181e963d463c\")]"
}
```

## List latest invocation statuses

`GET /trigger-invocations/v1/status`

Success: 200.

Gets a list of latest invocation statuses.
Statuses of successful invocations are available for up to 24 hours. Statuses of failed invocations are available for up to 48 hours.
This endpoint may only fetch up to 2000 invocations, and should not be treated as a representation of the full history of invocations.

Query:

- standard: `limit`, `offset`, `count`
- filters: triggerId (eq); subscriptionId (eq)
- sorters: triggerId, subscriptionName, created, completed

## Complete trigger invocation

`POST /trigger-invocations/v1/:id/complete`

Success: 204.

Completes an invocation to a REQUEST_RESPONSE type trigger.

Body:

```json
{
  "secret": "0f11f2a4-7c94-4bf3-a2bd-742580fe3bde",
  "output": {
    "approved": false
  }
}
```

## Start a test invocation

`POST /trigger-invocations/v1/test`

Success: 200, 204.

Initiate a test event for all subscribers of the specified event trigger.  If there are no subscribers to the specified trigger in the tenant, then no test event will be sent.

Body:

```json
{
  "triggerId": "idn:access-requested",
  "input": {
    "identityId": "201327fda1c44704ac01181e963d463c"
  },
  "contentJson": {
    "workflowId": 1234
  }
}
```
