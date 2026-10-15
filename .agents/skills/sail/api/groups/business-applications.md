# Business Applications

A Business Application groups machine identities (for example AI agents or applications) under a common owner and sanctioned status.

4 endpoints. Paths are relative to the environment API host.

## List Business Applications

`GET /business-applications/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Returns the list of Business Applications defined for the requesting tenant. Requires the `idn:business-application:read` right and the Machine Identity Security product to be enabled for the tenant.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq); name (eq, co); vendor (eq, co); signatures.type (eq, co); signatures.name (eq, co); source.name (eq, co); sanctionedStatus (eq)
- sorters: id, name, sanctionedStatus

## Create Business Application

`POST /business-applications/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Creates a custom Business Application. Requires the `idn:business-application:create` right, the Machine Identity Security product to be enabled, and the custom Business Application feature to be enabled for the tenant. The `name` must be unique within the tenant, and any provided `signatures` must not already be assigned to another Business Application.

Body:

```json
{
  "name": "Cursor",
  "description": "AI coding assistant used by the platform engineering team.",
  "vendor": "Cursor",
  "sanctionedStatus": "SANCTIONED",
  "owner": {
    "type": "IDENTITY",
    "id": "2c91808568c529c60168cca6f90c1313",
    "name": "William Wilson"
  },
  "signatures": [
    {
      "type": "AI Agent",
      "name": "cursor"
    }
  ]
}
```

## Get Business Application

`GET /business-applications/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Returns a single Business Application by ID for the requesting tenant. Requires the `idn:business-application:read` right and the Machine Identity Security product to be enabled.

## Update Business Application

`PATCH /business-applications/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Updates a Business Application using the JSON Patch standard. Requires the `idn:business-application:update` right and the Machine Identity Security product to be enabled. Patchable fields: `name`, `description`, `owner`, `additionalOwners`, `sanctionedStatus`, and `signatures`. Modifying `signatures` additionally requires the custom Business Application feature to be enabled.

Body:

```json
[
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
```
