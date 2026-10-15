# Search Attribute Configuration

Use this API to implement search attribute configuration functionality, along with Search.

5 endpoints. Paths are relative to the environment API host.

## Create extended search attributes

`POST /accounts/v1/search-attribute-config`

Success: 202.

Create and configure extended search attributes.  This API accepts an attribute name, an attribute display name and a list of name/value pair associates of application IDs to attribute names.  It will then validate the inputs and configure/create the attribute promotion configuration in the Link ObjectConfig.
>**Note: Give searchable attributes unique names.  Do not give them the same names used for account attributes or source attributes.  Also, do not give them the same names present in account schema for a current or future source, regardless of whether that source is included in the searchable attributes' `applicationAttributes`.**

Body:

```json
{
  "name": "newMailAttribute",
  "displayName": "New Mail Attribute",
  "applicationAttributes": {
    "2c9180866166b5b0016167c32ef31a66": "mail",
    "2c9180866166b5b0016167c32ef31a67": "mail"
  }
}
```

## List extended search attributes

`GET /accounts/v1/search-attribute-config`

Success: 200.

Get a list of attribute/application attributes currently configured in Identity Security Cloud (ISC).

Query:

- standard: `limit`, `offset`

## Get extended search attribute

`GET /accounts/v1/search-attribute-config/:name`

Success: 200, 204.

Get an extended attribute configuration by name.

## Delete extended search attribute

`DELETE /accounts/v1/search-attribute-config/:name`

Success: 204.

Delete an extended attribute configuration by name.

## Update extended search attribute

`PATCH /accounts/v1/search-attribute-config/:name`

Success: 200.

Update an existing search attribute configuration.
You can patch these fields:
* name  * displayName * applicationAttributes

Body:

```json
[
  {
    "op": "replace",
    "path": "/name",
    "value": "newAttributeName"
  },
  {
    "op": "replace",
    "path": "/displayName",
    "value": "new attribute display name"
  },
  {
    "op": "add",
    "path": "/applicationAttributes",
    "value": {
      "2c91808b79fd2422017a0b35d30f3968": "employeeNumber"
    }
  }
]
```
