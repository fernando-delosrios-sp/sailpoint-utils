# Privilege Criteria Configuration

Use this API to manage the configuration of privilege criteria.

3 endpoints. Paths are relative to the environment API host.

## Update privilege criteria configuration

`PATCH /criteria-config/v1/privilege/:criteriaConfigId`

Success: 200.

Use this API to update the privilege criteria configuration.

Body:

```json
[
  {
    "op": "replace",
    "path": "/config/privilegeClassificationMode",
    "value": "SINGLE_PRIVILEGE_LEVEL"
  },
  {
    "op": "replace",
    "path": "/config/criteriaPrivilegeLevel/connectorMediumEnabled",
    "value": true
  }
]
```

## Get privilege criteria config

`GET /criteria-config/v1/privilege/:criteriaConfigId`

Success: 200.

Use this API to get the privilege criteria configuration by Id.

## List privilege criteria config

`GET /criteria-config/v1/privilege`

Success: 200.

Use this API to list the privilege criteria configuration.

Query:

- filters: sourceId (eq)
