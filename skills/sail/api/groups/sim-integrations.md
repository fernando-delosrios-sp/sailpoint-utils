# SIM Integrations

Use this API to administer IdentityNow's Service Integration Module, or SIM integration with ServiceNow, so that it converts IdentityNow provisioning actions into tickets in ServiceNow.

7 endpoints. Paths are relative to the environment API host.

## Update an existing sim integration

`PUT /sim-integrations/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Update an existing SIM integration.

Body:

```json
{
  "name": "aName",
  "description": "Integration description",
  "type": "ServiceNow Service Desk",
  "attributes": {},
  "sources": [
    "2c9180835d191a86015d28455b4a2329",
    "2c5680835d191a85765d28455b4a9823"
  ],
  "cluster": "xyzzy999",
  "statusMap": {
    "closed_cancelled": "Failed",
    "closed_complete": "Committed",
    "closed_incomplete": "Failed",
    "closed_rejected": "Failed",
    "in_process": "Queued",
    "requested": "Queued"
  },
  "request": {
    "description": "SailPoint Access Request,",
    "req_description": "The Service Request created by SailPoint ServiceNow Service Integration Module (SIM).,",
    "req_short_description": "SailPoint New Access Request Created from IdentityNow,",
    "short_description": "SailPoint Access Request $!plan.arguments.identityRequestId"
  },
  "beforeProvisioningRule": {
    "type": "IDENTITY",
    "id": "2c918085708c274401708c2a8a760001",
    "name": "Example Rule"
  }
}
```

## Get a sim integration details.

`GET /sim-integrations/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Get the details of a SIM integration.

## Delete a sim integration

`DELETE /sim-integrations/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Get the details of a SIM integration.

## Patch a sim attribute.

`PATCH /sim-integrations/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Patch a SIM attribute given a JsonPatch object.

Body:

```json
{
  "operations": [
    {
      "op": "replace",
      "path": "/description",
      "value": "New description"
    },
    {
      "op": "replace",
      "path": "/description",
      "value": "New description"
    }
  ]
}
```

## Patch a sim beforeprovisioningrule attribute.

`PATCH /sim-integrations/v1/:id/beforeProvisioningRule`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Patch a SIM beforeProvisioningRule attribute given a JsonPatch object.

Body:

```json
{
  "operations": [
    {
      "op": "replace",
      "path": "/description",
      "value": "New description"
    },
    {
      "op": "replace",
      "path": "/description",
      "value": "New description"
    }
  ]
}
```

## List the existing sim integrations.

`GET /sim-integrations/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

List the existing SIM integrations.

## Create new sim integration

`POST /sim-integrations/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Create a new SIM Integrations.

Body:

```json
{
  "name": "aName",
  "description": "Integration description",
  "type": "ServiceNow Service Desk",
  "attributes": {},
  "sources": [
    "2c9180835d191a86015d28455b4a2329",
    "2c5680835d191a85765d28455b4a9823"
  ],
  "cluster": "xyzzy999",
  "statusMap": {
    "closed_cancelled": "Failed",
    "closed_complete": "Committed",
    "closed_incomplete": "Failed",
    "closed_rejected": "Failed",
    "in_process": "Queued",
    "requested": "Queued"
  },
  "request": {
    "description": "SailPoint Access Request,",
    "req_description": "The Service Request created by SailPoint ServiceNow Service Integration Module (SIM).,",
    "req_short_description": "SailPoint New Access Request Created from IdentityNow,",
    "short_description": "SailPoint Access Request $!plan.arguments.identityRequestId"
  },
  "beforeProvisioningRule": {
    "type": "IDENTITY",
    "id": "2c918085708c274401708c2a8a760001",
    "name": "Example Rule"
  }
}
```
