# Branding

Use this API to implement and customize branding functionality.

5 endpoints. Paths are relative to the environment API host.

## List of branding items

`GET /brandings/v1`

Success: 200.

This API endpoint returns a list of branding items.

## Create a branding item

`POST /brandings/v1`

Success: 201.

This API endpoint creates a branding item.

## Get a branding item

`GET /brandings/v1/:name`

Success: 200.

This API endpoint retrieves information for an existing branding item by name.

## Update a branding item

`PUT /brandings/v1/:name`

Success: 200.

This API endpoint updates information for an existing branding item.

## Delete a branding item

`DELETE /brandings/v1/:name`

Success: 204.

This API endpoint delete information for an existing branding item by name.
