# Org Config

Use this API to implement organization configuration functionality.

3 endpoints. Paths are relative to the environment API host.

## Get org config settings

`GET /org-config/v1`

Success: 200.

Get the current organization's configuration settings, only external accessible properties.

## Patch org config

`PATCH /org-config/v1`

Success: 200.

Patch the current organization's configuration, using  syntax. This is commonly used to changing an organization's time zone.

Body:

```json
[
  {
    "op": "replace",
    "path": "/timeZone",
    "value": "America/Toronto"
  }
]
```

## Get valid time zones

`GET /org-config/v1/valid-time-zones`

Success: 200.

List the valid time zones that can be set in organization configurations.

Query:

- standard: `limit`, `offset`, `count`
