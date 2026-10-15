# Connectors

Use this API to implement connector functionality.

13 endpoints. Paths are relative to the environment API host.

## Get connector by script name

`GET /connectors/v1/:scriptName`

Success: 200.

Fetches a connector that using its script name.

Query:

- `locale`: The locale to apply to the config. If no viable locale is given, it will default to "en" (This can only be one of de,no,fi,sv,ru,pt,ko,zh-TW,en,it,fr,zh-CN,hu,es,cs,ja,pl,da,nl)

## Delete connector by script name

`DELETE /connectors/v1/:scriptName`

Success: 204.

Delete a custom connector that using its script name.

## Update connector by script name

`PATCH /connectors/v1/:scriptName`

Success: 200.

This API updates a custom connector by script name using JSON Patch syntax.

The following fields are patchable:

* connectorMetadata

* applicationXml

* correlationConfigXml

* sourceConfigXml

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

## Get connector list

`GET /connectors/v1`

Success: 200.

Fetches list of connectors that have 'RELEASED' status using filtering and pagination.

Query:

- standard: `limit`, `offset`, `count`
- filters: name (sw, co); type (sw, co, eq); directConnect (eq); category (eq); features (ca); labels (ca)
- `locale`: The locale to apply to the config. If no viable locale is given, it will default to "en" (This can only be one of de,no,fi,sv,ru,pt,ko,zh-TW,en,it,fr,zh-CN,hu,es,cs,ja,pl,da,nl)

## Create custom connector

`POST /connectors/v1`

Success: 200.

Create custom connector.

Body:

```json
{
  "name": "custom connector",
  "className": "sailpoint.connector.OpenConnectorAdapter",
  "type": "custom connector type",
  "directConnect": true,
  "status": "RELEASED"
}
```

## Get connector source configuration

`GET /connectors/v1/:scriptName/source-config`

Success: 200.

Fetches a connector's source config using its script name.

## Update connector source configuration

`PUT /connectors/v1/:scriptName/source-config`

Success: 200.

Update a connector's source config using its script name.

## Get connector translations

`GET /connectors/v1/:scriptName/translations/:locale`

Success: 200.

Fetches a connector's translations using its script name.

## Update connector translations

`PUT /connectors/v1/:scriptName/translations/:locale`

Success: 200.

Update a connector's translations using its script name.

## Get connector source template

`GET /connectors/v1/:scriptName/source-template`

Success: 200.

Fetches a connector's source template using its script name.

## Update connector source template

`PUT /connectors/v1/:scriptName/source-template`

Success: 200.

Update a connector's source template using its script name.

## Get connector correlation configuration

`GET /connectors/v1/:scriptName/correlation-config`

Success: 200.

Fetches a connector's correlation config using its script name.

## Update connector correlation configuration

`PUT /connectors/v1/:scriptName/correlation-config`

Success: 200.

Update a connector's correlation config using its script name.
