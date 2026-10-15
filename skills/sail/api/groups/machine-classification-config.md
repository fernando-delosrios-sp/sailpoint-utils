# Machine Classification Config

3 endpoints. Paths are relative to the environment API host.

## Machine classification config for source

`GET /sources/v1/:sourceId/machine-classification-config`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns a Machine Classification Config for a Source using Source ID.

## Update source's classification config

`PUT /sources/v1/:sourceId/machine-classification-config`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to update Classification Config for a Source. A token with ORG_ADMIN, SOURCE_ADMIN, or SOURCE_SUBADMIN authority is required to call this API.

Body:

```json
{
  "enabled": true,
  "classificationMethod": "SOURCE",
  "criteria": {
    "operation": "EQUALS",
    "caseSensitive": false,
    "dataType": null,
    "attribute": "distinguishedName",
    "value": "OU=Service Accounts",
    "children": null
  },
  "created": "2017-07-11T18:45:37.098Z",
  "modified": "2018-06-25T20:22:28.104Z"
}
```

## Delete source's classification config

`DELETE /sources/v1/:sourceId/machine-classification-config`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to remove Classification Config for a Source.
A token with ORG_ADMIN, SOURCE_ADMIN, or SOURCE_SUBADMIN authority is required to call this API.
