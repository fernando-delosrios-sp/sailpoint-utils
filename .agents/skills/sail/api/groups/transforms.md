# Transforms

The purpose of this API is to expose functionality for the manipulation of Transform objects.

5 endpoints. Paths are relative to the environment API host.

## List transforms

`GET /transforms/v1`

Success: 200.

Gets a list of all saved transform objects.

Query:

- standard: `limit`, `offset`, `count`
- `name`: Name of the transform to retrieve from the list.
- filters: internal (eq); name (eq, sw)

## Create transform

`POST /transforms/v1`

Success: 201.

Creates a new transform object immediately. By default, the internal flag is set to false to indicate that this is a custom transform. Only SailPoint employees have the ability to create a transform with internal set to true. Newly created Transforms can be used in the Identity Profile mappings within the UI.

Body:

```json
{
  "name": "Timestamp To Date",
  "type": "dateFormat",
  "attributes": {
    "inputFormat": "MMM dd yyyy, HH:mm:ss.SSS",
    "outputFormat": "yyyy/dd/MM"
  }
}
```

## Transform by id

`GET /transforms/v1/:id`

Success: 200.

This API returns the transform specified by the given ID.

## Update a transform

`PUT /transforms/v1/:id`

Success: 200.

Replaces the transform specified by the given ID with the transform provided in the request body. Only the "attributes" field is mutable. Attempting to change other properties (ex. "name" and "type") will result in an error.

Body:

```json
{
  "name": "Timestamp To Date",
  "type": "dateFormat",
  "attributes": {
    "inputFormat": "MMM-dd-yyyy, HH:mm:ss.SSS",
    "outputFormat": "yyyy/dd/MM"
  }
}
```

## Delete a transform

`DELETE /transforms/v1/:id`

Success: 204.

Deletes the transform specified by the given ID. Attempting to delete a transform that is used in one or more Identity Profile mappings will result in an error. If this occurs, you must first remove the transform from all mappings before deleting the transform.
