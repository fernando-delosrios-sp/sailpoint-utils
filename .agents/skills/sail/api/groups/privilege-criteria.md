# Privilege Criteria

Use this API to create, retrieve, update, and delete privilege criteria.

5 endpoints. Paths are relative to the environment API host.

## Create custom privilege criteria

`POST /criteria/v1/privilege`

Success: 201.

Use this API to create a custom privilege criteria

Body:

```json
{
  "sourceId": "c42c45d8d7c04d2da64d215cd8c32f21",
  "type": "CUSTOM",
  "operator": "AND",
  "groups": [
    {
      "operator": "AND",
      "criteriaItems": [
        {
          "targetType": "group",
          "operator": "value",
          "values": [
            "admin",
            "superuser"
          ],
          "ignoreCase": true
        },
        {
          "targetType": "group",
          "operator": "description",
          "values": [
            "admin",
            "superuser"
          ],
          "ignoreCase": true
        }
      ]
    },
    {
      "operator": "AND",
      "criteriaItems": [
        {
          "targetType": "group",
          "operator": "displayName",
          "values": [
            "admin",
            "superuser"
          ],
          "ignoreCase": true
        },
        {
          "targetType": "group",
          "operator": "displayName",
          "values": [
            "admin",
            "superuser"
          ],
          "ignoreCase": true
        }
      ]
    }
  ],
  "privilegeLevel": "HIGH"
}
```

## List privilege criteria

`GET /criteria/v1/privilege`

Success: 200.

Use this API to list all privilege criteria matching a filter

Query:

- filters: type (eq); sourceId (eq); privilegeLevel (eq); Supported composite operators (and)

## Update privilege criteria

`PUT /criteria/v1/privilege/:criteriaId`

Success: 200.

Use this API to update a specific custom privilege criteria by overwriting the information with new information.

Body:

```json
{
  "id": "2c9180867817ac4d017817c491119a20",
  "sourceId": "c42c45d8d7c04d2da64d215cd8c32f21",
  "type": "CUSTOM",
  "operator": "AND",
  "groups": [
    {
      "operator": "AND",
      "criteriaItems": [
        {
          "targetType": "group",
          "operator": "IN",
          "property": "value",
          "values": [
            "admin",
            "superuser"
          ],
          "ignoreCase": true
        },
        {
          "targetType": "group",
          "operator": "IN",
          "property": "displayName",
          "values": [
            "admin",
            "superuser"
          ],
          "ignoreCase": true
        }
      ]
    },
    {
      "operator": "AND",
      "criteriaItems": [
        {
          "targetType": "group",
          "operator": "IN",
          "property": "description",
          "values": [
            "admin",
            "superuser"
          ],
          "ignoreCase": true
        },
        {
          "targetType": "group",
          "operator": "IN",
          "property": "value",
          "values": [
            "admin",
            "superuser"
          ],
          "ignoreCase": true
        }
      ]
    }
  ],
```

Body example truncated.

## Get privilege criteria

`GET /criteria/v1/privilege/:criteriaId`

Success: 200.

Use this API to get a specific privilege criteria.

## Delete privilege criteria

`DELETE /criteria/v1/privilege/:criteriaId`

Success: 204.

Use this API to delete a specific custom privilege criteria.
