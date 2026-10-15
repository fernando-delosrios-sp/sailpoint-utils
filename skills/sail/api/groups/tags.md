# Tags

Use this API to manage the tags available in your Identity Security Cloud tenant.

4 endpoints. Paths are relative to the environment API host.

## List tags

`GET /tags/v1`

Success: 200.

This API returns a list of tags.

A token with API, ORG_ADMIN, CERT_ADMIN, REPORT_ADMIN, ROLE_ADMIN, ROLE_SUBADMIN, SOURCE_ADMIN, or SOURCE_SUBADMIN authority is required to call this API.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in); name (eq, in, sw)
- sorters: id, name, created, modified

## Create tag

`POST /tags/v1`

Success: 201.

This API creates new tag.

A token with API, ORG_ADMIN, CERT_ADMIN, REPORT_ADMIN, ROLE_ADMIN, ROLE_SUBADMIN, SOURCE_ADMIN, or SOURCE_SUBADMIN authority is required to call this API.

Body:

```json
{
  "name": "PCI",
  "id": true,
  "created": 6566.972354793371,
  "modified": false,
  "tagCategoryRefs": 8110
}
```

## Get tag by id

`GET /tags/v1/:id`

Success: 200.

Returns a tag by its id.

A token with API, ORG_ADMIN, CERT_ADMIN, REPORT_ADMIN, ROLE_ADMIN, ROLE_SUBADMIN, SOURCE_ADMIN, or SOURCE_SUBADMIN authority is required to call this API.

## Delete tag

`DELETE /tags/v1/:id`

Success: 204.

This API deletes a tag by specified id.

A token with API, ORG_ADMIN, CERT_ADMIN, REPORT_ADMIN, ROLE_ADMIN, ROLE_SUBADMIN, SOURCE_ADMIN, or SOURCE_SUBADMIN authority is required to call this API.
