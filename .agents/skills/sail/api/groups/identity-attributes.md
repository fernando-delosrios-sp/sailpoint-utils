# Identity Attributes

6 endpoints. Paths are relative to the environment API host.

## List identity attributes

`GET /identity-attributes/v1`

Success: 200.

Use this API to get a collection of identity attributes.

Query:

- standard: `count`
- `includeSystem`: Include 'system' attributes in the response.
- `includeSilent`: Include 'silent' attributes in the response.
- `searchableOnly`: Include only 'searchable' attributes in the response.

## Create identity attribute

`POST /identity-attributes/v1`

Success: 201.

Use this API to create a new identity attribute.

Body:

```json
{
  "name": "costCenter",
  "displayName": "Cost Center",
  "standard": false,
  "type": "string",
  "multi": false,
  "searchable": false,
  "system": false,
  "sources": [
    {
      "type": "rule",
      "properties": {
        "ruleType": "IdentityAttribute",
        "ruleName": "Cloud Promote Identity Attribute"
      }
    },
    {
      "type": "rule",
      "properties": {
        "ruleType": "IdentityAttribute",
        "ruleName": "Cloud Promote Identity Attribute"
      }
    }
  ]
}
```

## Get identity attribute

`GET /identity-attributes/v1/:name`

Success: 200.

This gets an identity attribute for a given technical name.

## Update identity attribute

`PUT /identity-attributes/v1/:name`

Success: 200.

This updates an existing identity attribute.  Making an attribute searchable requires that the `system`, `standard`, and `multi` properties be set to false.

Body:

```json
{
  "name": "costCenter",
  "displayName": "Cost Center",
  "standard": false,
  "type": "string",
  "multi": false,
  "searchable": false,
  "system": false,
  "sources": [
    {
      "type": "rule",
      "properties": {
        "ruleType": "IdentityAttribute",
        "ruleName": "Cloud Promote Identity Attribute"
      }
    },
    {
      "type": "rule",
      "properties": {
        "ruleType": "IdentityAttribute",
        "ruleName": "Cloud Promote Identity Attribute"
      }
    }
  ]
}
```

## Delete identity attribute

`DELETE /identity-attributes/v1/:name`

Success: 204.

This deletes an identity attribute with the given name.  The `system` and `standard` properties must be set to false before you can delete an identity attribute.

## Bulk delete identity attributes

`DELETE /identity-attributes/v1/bulk-delete`

Success: 204.

Use this API to bulk delete identity attributes for a given set of names. Attributes that are currently mapped in an identity profile cannot be deleted.  The `system` and `standard` properties must be set to 'false' before you can delete an identity attribute.

Body:

```json
{
  "ids": [
    "name",
    "displayName"
  ]
}
```
