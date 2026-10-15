# Workflows

Workflows allow administrators to create custom automation scripts directly within Identity Security Cloud.

19 endpoints. Paths are relative to the environment API host.

## List workflows

`GET /workflows/v1`

Success: 200.

List all workflows in the tenant.

## Create workflow

`POST /workflows/v1`

Success: 200.

Create a new workflow with the desired trigger and steps specified in the request body.

Body:

```json
{
  "name": "Send Email",
  "owner": {
    "type": "IDENTITY",
    "id": "2c91808568c529c60168cca6f90c1313",
    "name": "William Wilson"
  },
  "description": "Send an email to the identity who's attributes changed.",
  "definition": {
    "start": "Send Email Test",
    "steps": {
      "Send Email": {
        "actionId": "sp:send-email",
        "attributes": {
          "body": "This is a test",
          "from": "sailpoint@sailpoint.com",
          "recipientId.$": "$.identity.id",
          "subject": "test"
        },
        "nextStep": "success",
        "selectResult": null,
        "type": "action"
      },
      "success": {
        "type": "success"
      }
    }
  },
  "enabled": false,
  "trigger": {
    "type": "EVENT",
    "attributes": {
      "id": "idn:identity-attributes-changed",
      "filter": "$.changes[?(@.attribute == 'manager')]"
    }
  }
}
```

## Get workflow by id

`GET /workflows/v1/:id`

Success: 200.

Get a single workflow by id.

## Update workflow

`PUT /workflows/v1/:id`

Success: 200.

Perform a full update of a workflow.  The updated workflow object is returned in the response.

Body:

```json
{
  "name": "Send Email",
  "owner": {
    "type": "IDENTITY",
    "id": "2c91808568c529c60168cca6f90c1313",
    "name": "William Wilson"
  },
  "description": "Send an email to the identity who's attributes changed.",
  "definition": {
    "start": "Send Email Test",
    "steps": {
      "Send Email": {
        "actionId": "sp:send-email",
        "attributes": {
          "body": "This is a test",
          "from": "sailpoint@sailpoint.com",
          "recipientId.$": "$.identity.id",
          "subject": "test"
        },
        "nextStep": "success",
        "selectResult": null,
        "type": "ACTION"
      },
      "success": {
        "type": "success"
      }
    }
  },
  "enabled": false,
  "trigger": {
    "type": "EVENT",
    "attributes": {
      "id": "idn:identity-attributes-changed",
      "filter.$": "$.changes[?(@.attribute == 'manager')]",
      "description": "Triggered when an identity's manager attribute changes",
      "attributeToFilter": "LifecycleState",
      "formDefinitionId": "Admin_Access_Request_Form"
    },
    "displayName": "string"
  }
}
```

## Patch workflow

`PATCH /workflows/v1/:id`

Success: 200.

Partially update an existing Workflow using JSON Patch syntax.

Body:

```json
[
  {
    "op": "replace",
    "path": "/name",
    "value": "Send Email"
  },
  {
    "op": "replace",
    "path": "/owner",
    "value": {
      "type": "IDENTITY",
      "id": "2c91808568c529c60168cca6f90c1313",
      "name": "William Wilson"
    }
  },
  {
    "op": "replace",
    "path": "/description",
    "value": "Send an email to the identity who's attributes changed."
  },
  {
    "op": "replace",
    "path": "/enabled",
    "value": false
  },
  {
    "op": "replace",
    "path": "/definition",
    "value": {
      "start": "Send Email Test",
      "steps": {
        "Send Email": {
          "actionId": "sp:send-email",
          "attributes": {
            "body": "This is a test",
            "from": "sailpoint@sailpoint.com",
            "recipientId.$": "$.identity.id",
            "subject": "test"
          },
          "nextStep": "success",
          "selectResult": null,
          "type": "action"
        },
        "success": {
          "type": "success"
        }
      }
    }
  },
  {
    "op": "replace",
    "path": "/trigger",
    "value": {
      "type": "EVENT",
      "attributes": {
        "id": "idn:identity-attributes-changed"
      }
    }
  }
]
```

## Delete workflow by id

`DELETE /workflows/v1/:id`

Success: 204.

Delete a workflow.  **Enabled workflows cannot be deleted**.  They must first be disabled.

## Test workflow by id

`POST /workflows/v1/:id/test`

Success: 200.

:::info

Workflow must be disabled in order to use this endpoint.

:::

Test a workflow with the provided input data.  The input data should resemble the input that the trigger will send the workflow.  See the event trigger documentation for an example input for the trigger that initiates this workflow.

This endpoint will return an execution ID, which can be used to lookup more information about the execution using the `Get a Workflow Execution` endpoint.

**This will cause a live run of the workflow, which could result in unintended modifications to your IDN tenant.**

Body:

```json
{
  "input": {
    "identity": {
      "id": "ee769173319b41d19ccec6cea52f237b",
      "name": "john.doe",
      "type": "IDENTITY"
    },
    "changes": [
      {
        "attribute": "department",
        "oldValue": "sales",
        "newValue": "marketing"
      },
      {
        "attribute": "manager",
        "oldValue": {
          "id": "ee769173319b41d19ccec6c235423237b",
          "name": "nice.guy",
          "type": "IDENTITY"
        },
        "newValue": {
          "id": "ee769173319b41d19ccec6c235423236c",
          "name": "mean.guy",
          "type": "IDENTITY"
        }
      },
      {
        "attribute": "email",
        "oldValue": "john.doe@hotmail.com",
        "newValue": "john.doe@gmail.com"
      }
    ]
  }
}
```

## List workflow executions

`GET /workflows/v1/:id/executions`

Success: 200.

[Deprecated] This endpoint will be removed in July 2028. Use this API to list a specified workflow's executions. Workflow executions are available for up to 90 days before being archived. By default, you can get a maximum of 250 executions. To get executions past the first 250 records, you can do the following:
1. Use the Get Workflows endpoint to get your workflows.
2. Get your workflow ID from the response.
3. You can then do either of the following:

  - Filter to find relevant workflow executions.
  For example, you can filter for failed workflow executions: `GET /workflows/:workflowID/executions?filters=status eq "Failed"`

  - Paginate through results with the `offset` parameter.
  For example, you can page through 50 executions per page and use that as a way to get to the records past the first 250.
  Refer to Paginating Results for more information about the query parameters you can use to achieve pagination.

Query:

- standard: `limit`, `offset`
- filters: start_time (eq, lt, le, gt, ge); status (eq)

## Get workflow execution

`GET /workflow-executions/v1/:id`

Success: 200.

Use this API to get a single workflow execution. Workflow executions are available for up to 90 days before being archived. If you attempt to access a workflow execution that has been archived, you will receive a "404 Not Found" response.

## Get workflow execution history

`GET /workflow-executions/v1/:id/history`

Success: 200.

Get a detailed history of a single workflow execution.  Workflow executions are available for up to 90 days before being archived.  If you attempt to access a workflow execution that has been archived, you will receive a 404 Not Found.

Query:

- standard: `limit`, `offset`

## Get updated workflow execution history

`GET /workflow-executions/v1/:id/history-v2`

Success: 200.

Gets a workflow execution history, trigger input, and workflow definition of a single workflow execution.  Workflow executions are available for up to 90 days before being archived.  If you attempt to access a workflow execution that has been archived, you will receive a 404 Not Found.

## Cancel workflow execution by id

`POST /workflow-executions/v1/:id/cancel`

Success: 204.

Use this API to cancel a running workflow execution.

## List complete workflow library

`GET /workflow-library/v1`

Success: 200.

This lists all triggers, actions, and operators in the library

Query:

- standard: `limit`, `offset`

## List workflow library actions

`GET /workflow-library/v1/actions`

Success: 200.

This lists the workflow actions available to you.

Query:

- standard: `limit`, `offset`
- filters: id (eq)

## List workflow library triggers

`GET /workflow-library/v1/triggers`

Success: 200.

This lists the workflow triggers available to you

Query:

- standard: `limit`, `offset`
- filters: id (eq); name (eq); type (eq)

## List workflow library operators

`GET /workflow-library/v1/operators`

Success: 200.

This lists the workflow operators available to you

## Generate external trigger oauth client

`POST /workflows/v1/:id/external/oauth-clients`

Success: 200.

Create OAuth client ID, client secret, and callback URL for use in an external trigger.  External triggers will need this information to generate an access token to authenticate to the callback URL and submit a trigger payload that will initiate the workflow.

## Execute workflow via external trigger

`POST /workflows/v1/execute/external/:id`

Success: 200.

This endpoint allows a service outside of IdentityNow to initiate a workflow that uses the "External Trigger" step.  The external service will invoke this endpoint with the input data it wants to send to the workflow in the body.

Body:

```json
{
  "input": {
    "customAttribute1": "value1",
    "customAttribute2": "value2"
  }
}
```

## Test workflow via external trigger

`POST /workflows/v1/execute/external/:id/test`

Success: 200.

Validate a workflow with an "External Trigger" can receive input.  The response includes the input that the workflow received, which can be used to validate that the input is intact when it reaches the workflow.

Body:

```json
{
  "input": {
    "test": "hello world"
  }
}
```
