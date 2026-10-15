# Connector Customizers

Saas Connectivity Customizers are cloud-based connector customizers.

6 endpoints. Paths are relative to the environment API host.

## List all connector customizers

`GET /connector-customizers/v1`

Success: 200.

List all connector customizers.

Query:

- standard: `limit`, `offset`

## Create connector customizer

`POST /connector-customizers/v1`

Success: 201.

Create a connector customizer.

Body:

```json
{
  "name": "My Custom Connector"
}
```

## Get connector customizer

`GET /connector-customizers/v1/:id`

Success: 200.

Gets connector customizer by ID.

## Update connector customizer

`PUT /connector-customizers/v1/:id`

Success: 200.

Update an existing connector customizer with the one provided in the request body. These fields are immutable: `id`, `name`, `type`.

Body:

```json
{
  "name": "My Custom Connector"
}
```

## Delete connector customizer

`DELETE /connector-customizers/v1/:id`

Success: 204.

Delete the connector customizer for the given ID.

## Creates a connector customizer version

`POST /connector-customizers/v1/:id/versions`

Success: 200.

Creates a new version for the customizer.
