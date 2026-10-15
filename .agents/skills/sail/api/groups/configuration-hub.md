# Configuration Hub

Use this API to implement and customize configuration settings management.

20 endpoints. Paths are relative to the environment API host.

## Gets list of object mappings

`GET /configuration-hub/v1/object-mappings/:sourceOrg`

Success: 200.

This gets a list of existing object mappings between current org and source org.
Source org should be "default" when getting object mappings that are not associated to any particular org.
The request will need the following security scope:
- sp:config-object-mapping:read

## Creates an object mapping

`POST /configuration-hub/v1/object-mappings/:sourceOrg`

Success: 200.

This creates an object mapping between current org and source org.
Source org should be "default" when creating an object mapping that is not to be associated to any particular org.
The request will need the following security scope:
- sp:config-object-mapping:manage

Body:

```json
{
  "objectType": "GOVERNANCE_GROUP",
  "jsonPath": "$.description",
  "sourceValue": "Sample Governance Group",
  "targetValue": "Sample Governance Group - Updated",
  "enabled": true
}
```

## Deletes an object mapping

`DELETE /configuration-hub/v1/object-mappings/:sourceOrg/:objectMappingId`

Success: 204.

This deletes an existing object mapping.
Source org should be "default" when deleting an object mapping that is not associated to any particular org.
The request will need the following security scope:
- sp:config-object-mapping:manage

## Bulk creates object mappings

`POST /configuration-hub/v1/object-mappings/:sourceOrg/bulk-create`

Success: 200.

This creates a set of object mappings (Max 25) between current org and source org.
Source org should be "default" when creating object mappings that are not to be associated to any particular org.
The request will need the following security scope:
- sp:config-object-mapping:manage

Body:

```json
{
  "newObjectsMappings": [
    {
      "objectType": "SOURCE",
      "jsonPath": "$.name",
      "sourceValue": "Original SOURCE Name",
      "targetValue": "New SOURCE Name",
      "enabled": true
    },
    {
      "objectType": "IDENTITY",
      "jsonPath": "$.name",
      "sourceValue": "Original IDENTITY Name",
      "targetValue": "New IDENTITY Name ",
      "enabled": true
    }
  ]
}
```

## Bulk updates object mappings

`POST /configuration-hub/v1/object-mappings/:sourceOrg/bulk-patch`

Success: 200.

This updates a set of object mappings, only enabled and targetValue fields can be updated.
Source org should be "default" when updating object mappings that are not associated to any particular org.
The request will need the following security scope:
- sp:config-object-mapping:manage

Body:

```json
{
  "patches": {
    "603b1a61-d03d-4ed1-864f-a508fbd1995d": [
      {
        "op": "replace",
        "path": "/enabled",
        "value": true
      }
    ],
    "00bece34-f50d-4227-8878-76f620b5a971": [
      {
        "op": "replace",
        "path": "/targetValue",
        "value": "New Target Value"
      }
    ]
  }
}
```

## List scheduled actions

`GET /configuration-hub/v1/scheduled-actions`

Success: 200.

This API gets a list of existing scheduled actions for the current tenant.

## Create scheduled action

`POST /configuration-hub/v1/scheduled-actions`

Success: 200.

This API creates a new scheduled action for the current tenant.

Body:

```json
{
  "jobType": "BACKUP",
  "startTime": "2024-08-16T14:16:58.389Z",
  "cronString": "0 0 * * * *",
  "timeZoneId": "America/Chicago",
  "content": {
    "name": "Daily Backup",
    "backupOptions": {
      "includeTypes": [
        "SOURCE",
        "IDENTITY"
      ],
      "objectOptions": {
        "SOURCE": {
          "includedNames": [
            "Source1",
            "Source2"
          ]
        }
      }
    }
  }
}
```

## Update scheduled action

`PATCH /configuration-hub/v1/scheduled-actions/:id`

Success: 200.

This API updates an existing scheduled action using JSON Patch format.

Body:

```json
[
  {
    "op": "replace",
    "path": "/content/name",
    "value": "Updated Backup Name"
  },
  {
    "op": "replace",
    "path": "/cronString",
    "value": "0 0 9 * * ?"
  }
]
```

## Delete scheduled action

`DELETE /configuration-hub/v1/scheduled-actions/:id`

Success: 204.

This API deletes an existing scheduled action.

## List uploaded configurations

`GET /configuration-hub/v1/backups/uploads`

Success: 200.

This API gets a list of existing uploaded configurations for the current tenant.

Query:

- filters: status (eq)

## Upload a configuration

`POST /configuration-hub/v1/backups/uploads`

Success: 202.

This API uploads a JSON configuration file into a tenant.

Configuration files can be managed and deployed via Configuration Hub by uploading a json file which contains configuration data. The JSON file should be the same as the one used by our import endpoints. The object types supported by upload configuration file functionality are the same as the ones supported by our regular backup functionality.

Refer to SaaS Configuration for more information about supported objects.

## Get an uploaded configuration

`GET /configuration-hub/v1/backups/uploads/:id`

Success: 200.

This API gets an existing uploaded configuration for the current tenant.

## Delete an uploaded configuration

`DELETE /configuration-hub/v1/backups/uploads/:id`

Success: 204.

This API deletes an uploaded configuration based on Id.

On success, this endpoint will return an empty response.

The uploaded configuration id can be obtained from the response after a successful upload, or the list uploaded configurations endpoint.

## List backups

`GET /configuration-hub/v1/backups`

Success: 200.

This API gets a list of existing backups for the current tenant.

Query:

- filters: status (eq)

## Delete a backup

`DELETE /configuration-hub/v1/backups/:id`

Success: 204.

This API deletes an existing backup for the current tenant.

On success, this endpoint will return an empty response.

The backup id can be obtained from the response after a backup was successfully created, or from the list backups endpoint.

## List drafts

`GET /configuration-hub/v1/drafts`

Success: 200.

This API gets a list of existing drafts for the current tenant.

Query:

- filters: status (eq); approvalStatus (eq)

## Delete a draft

`DELETE /configuration-hub/v1/drafts/:id`

Success: 204.

This API deletes an existing draft for the current tenant.

On success, this endpoint will return an empty response.

The draft id can be obtained from the response after a draft was successfully created, or from the list drafts endpoint.

## List deploys

`GET /configuration-hub/v1/deploys`

Success: 200.

This API gets a list of deploys for the current tenant.

## Create a deploy

`POST /configuration-hub/v1/deploys`

Success: 202.

This API performs a deploy based on an existing daft.

Body:

```json
{
  "draftId": "c9a38d8c-5edf-4182-9d39-f6581d3ebd05"
}
```

## Get a deploy

`GET /configuration-hub/v1/deploys/:id`

Success: 200.

This API gets an existing deploy for the current tenant.
