# SP-Config

Import and export configuration for some objects between tenants.

7 endpoints. Paths are relative to the environment API host.

## Initiates configuration objects export job

`POST /sp-config/v1/export`

Success: 202.

This post will export objects from the tenant to a JSON configuration file.
For more information about the object types that currently support export functionality, refer to SaaS Configuration.

Body:

```json
{
  "description": "Export all available objects",
  "excludeTypes": [],
  "includeTypes": [
    "ACCESS_PROFILE",
    "ACCESS_REQUEST_CONFIG",
    "ATTR_SYNC_SOURCE_CONFIG",
    "AUTH_ORG",
    "CAMPAIGN_FILTER",
    "CONNECTOR_RULE",
    "FORM_DEFINITION",
    "GOVERNANCE_GROUP",
    "IDENTITY_OBJECT_CONFIG",
    "IDENTITY_PROFILE",
    "LIFECYCLE_STATE",
    "NOTIFICATION_TEMPLATE",
    "PASSWORD_POLICY",
    "PASSWORD_SYNC_GROUP",
    "PUBLIC_IDENTITIES_CONFIG",
    "ROLE",
    "RULE",
    "SEGMENT",
    "SERVICE_DESK_INTEGRATION",
    "SOD_POLICY",
    "SOURCE",
    "TAG",
    "TRANSFORM",
    "TRIGGER_SUBSCRIPTION",
    "WORKFLOW"
  ],
  "objectOptions": {}
}
```

## Get export job status

`GET /sp-config/v1/export/:id`

Success: 200.

This gets the status of the export job identified by the `id` parameter.
The request will need one of the following security scopes:
- sp:config:read - sp:config:manage

## Download export job result.

`GET /sp-config/v1/export/:id/download`

Success: 200.

This endpoint gets the export file resulting from the export job with the requested `id` and downloads it to a file.
The request will need one of the following security scopes:
- sp:config:read - sp:config:manage

## Initiates configuration objects import job

`POST /sp-config/v1/import`

Success: 202.

This post will import objects from a JSON configuration file into a tenant.
By default, every import will first export all existing objects supported by sp-config as a backup before the import is attempted.
The backup is provided so that the state of the configuration prior to the import is available for inspection or restore if needed.
The backup can be skipped by setting "excludeBackup" to true in the import options.
If a backup is performed, the id of the backup will be provided in the ImportResult as the "exportJobId". This can be downloaded
using the `/sp-config/export/{exportJobId}/download` endpoint.

You cannot currently import from the Non-Employee Lifecycle Management (NELM) source. You cannot use this endpoint to back up or store NELM data.

For more information about the object types that currently support import functionality, refer to SaaS Configuration.

Query:

- `preview`: This option is intended to give the user information about how an import operation would proceed, without having any effect on the target tenant. If this parameter is "true", no objects will be imported. Instead, the import process will…

## Get import job status

`GET /sp-config/v1/import/:id`

Success: 200.

'This gets the status of the import job identified by the `id` parameter.

 For more information about the object types that currently support import functionality,
 refer to SaaS Configuration.'

## Download import job result

`GET /sp-config/v1/import/:id/download`

Success: 200.

This gets import file resulting from the import job with the requested id and downloads it to a file. The downloaded file will contain the results of the import operation, including any error, warning or informational messages associated with the import.
The request will need the following security scope:
- sp:config:manage

## List config objects

`GET /sp-config/v1/config-objects`

Success: 200.

Get a list of object configurations that the tenant export/import service knows.
