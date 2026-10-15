# Machine Account Mappings

4 endpoints. Paths are relative to the environment API host.

## Machine account mapping for source

`GET /sources/v1/:sourceId/machine-account-mappings`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Retrieves Machine account mappings for a specified source using Source ID.

Query:

- standard: `limit`, `offset`

## Update source's machine account mappings

`PUT /sources/v1/:sourceId/machine-account-mappings`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to update Machine Account Attribute Mapping for a Source. A token with ORG_ADMIN, SOURCE_ADMIN, or SOURCE_SUBADMIN authority is required to call this API.

Body:

```json
{
  "target": {
    "type": "IDENTITY",
    "attributeName": "businessApplication",
    "sourceId": "2c9180835d2e5168015d32f890ca1581"
  },
  "transformDefinition": {
    "type": "reference",
    "attributes": {
      "input": {
        "type": "accountAttribute",
        "attributes": {
          "attributeName": "givenName",
          "sourceName": "delimited-src",
          "name": "8d3e0094e99445de98eef6c75e25jc04"
        }
      }
    },
    "id": "ToUpper"
  }
}
```

## Create machine account mappings

`POST /sources/v1/:sourceId/machine-account-mappings`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Creates Machine Account Mappings for both identities and accounts for a source.
A token with API, ORG_ADMIN, ROLE_ADMIN, ROLE_SUBADMIN, SOURCE_ADMIN, or SOURCE_SUBADMIN authority is required to call this API.

Body:

```json
{
  "target": {
    "type": "IDENTITY",
    "attributeName": "businessApplication",
    "sourceId": "2c9180835d2e5168015d32f890ca1581"
  },
  "transformDefinition": {
    "type": "reference",
    "attributes": {
      "input": {
        "type": "accountAttribute",
        "attributes": {
          "attributeName": "givenName",
          "sourceName": "delimited-src",
          "name": "8d3e0094e99445de98eef6c75e25jc04"
        }
      }
    },
    "id": "ToUpper"
  }
}
```

## Delete source's machine account mappings

`DELETE /sources/v1/:sourceId/machine-account-mappings`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to remove machine account attribute mappings for a Source.
A token with ORG_ADMIN, SOURCE_ADMIN, or SOURCE_SUBADMIN authority is required to call this API.
