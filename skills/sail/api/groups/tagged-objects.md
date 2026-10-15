# Tagged Objects

Use this API to implement object tagging functionality.

8 endpoints. Paths are relative to the environment API host.

## List tagged objects

`GET /tagged-objects/v1`

Success: 200.

This API returns a list of all tagged objects.

Query:

- standard: `limit`, `offset`, `count`
- filters: objectRef.id (eq, in); objectRef.type (eq, in); tagName (eq, in)

## Add tag to object

`POST /tagged-objects/v1`

Success: 201.

This adds a tag to an object.

Body:

```json
{
  "objectRef": {
    "type": "IDENTITY",
    "id": "2c91808568c529c60168cca6f90c1313",
    "name": "William Wilson"
  },
  "tags": [
    "BU_FINANCE",
    "PCI"
  ]
}
```

## List tagged objects by type

`GET /tagged-objects/v1/:type`

Success: 200.

This API returns a list of all tagged objects by type.

Query:

- standard: `limit`, `offset`, `count`
- filters: objectRef.id (eq); objectRef.type (eq)

## Get tagged object

`GET /tagged-objects/v1/:type/:id`

Success: 200.

This gets a tagged object for the specified type.

## Update tagged object

`PUT /tagged-objects/v1/:type/:id`

Success: 200.

This updates a tagged object for the specified type.

Body:

```json
{
  "objectRef": {
    "type": "IDENTITY",
    "id": "2c91808568c529c60168cca6f90c1313",
    "name": "William Wilson"
  },
  "tags": [
    "BU_FINANCE",
    "PCI"
  ]
}
```

## Delete object tags

`DELETE /tagged-objects/v1/:type/:id`

Success: 204.

Delete all tags from a tagged object.

## Tag multiple objects

`POST /tagged-objects/v1/bulk-add`

Success: 200.

This API adds tags to multiple objects.

Body:

```json
{
  "objectRefs": [
    {
      "type": "IDENTITY",
      "id": "2c91808568c529c60168cca6f90c1313",
      "name": "William Wilson"
    },
    {
      "type": "IDENTITY",
      "id": "2c91808568c529c60168cca6f90c1313",
      "name": "William Wilson"
    }
  ],
  "tags": [
    "BU_FINANCE",
    "PCI"
  ],
  "operation": "MERGE"
}
```

## Remove tags from multiple objects

`POST /tagged-objects/v1/bulk-remove`

Success: 204.

This API removes tags from multiple objects.

Body:

```json
{
  "objectRefs": [
    {
      "type": "IDENTITY",
      "id": "2c91808568c529c60168cca6f90c1313",
      "name": "William Wilson"
    },
    {
      "type": "IDENTITY",
      "id": "2c91808568c529c60168cca6f90c1313",
      "name": "William Wilson"
    }
  ],
  "tags": [
    "BU_FINANCE",
    "PCI"
  ]
}
```
