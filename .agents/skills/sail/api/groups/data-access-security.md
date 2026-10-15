# Data Access Security

Use this API to enable data ownership election campaigns, assign resource owners, and respond to identity lifecycle events to maintain continuous accountability.

31 endpoints. Paths are relative to the environment API host.

## Lists all DAS tasks.

`GET /das/v1/tasks`

Success: 200.

This end-point lists all the tasks in Data Access Security.

Query:

- standard: `limit`, `offset`, `count`
- filters: taskIds (eq, in); statuses (eq, in); taskTypeName (eq, in); taskName (eq); endBeforeTime (eq)

## Get a DAS task.

`GET /das/v1/tasks/:id`

Success: 200.

This end-point gets a task in Data Access Security.

## Delete a DAS task.

`DELETE /das/v1/tasks/:id`

Success: 204.

This end-point sends a request to delete a task in Data Access Security.

## Cancel a DAS task.

`POST /das/v1/tasks/cancel/:id`

Success: 204.

This end-point sends a request to cancel a task in Data Access Security.

## Rerun a DAS task.

`POST /das/v1/tasks/rerun/:id`

Success: 204.

This end-point sends a request to re-run a task in Data Access Security.

## List all schedules.

`GET /das/v1/tasks/schedules`

Success: 200.

This end-point lists all the schedules in Data Access Security.

Query:

- standard: `limit`, `offset`, `count`
- filters: scheduleTaskIds (eq, in); taskTypeName (eq, in); status (eq); applicationId (eq); fullName (eq); nameSubString (eq); scheduleType (eq)

## Create a new schedule.

`POST /das/v1/tasks/schedules`

Success: 200.

Body:

```json
{
  "taskTypeName": "DataSync",
  "scheduleType": "Daily",
  "interval": 1440,
  "scheduleTaskName": "Daily Data Sync",
  "startTime": 1762237200,
  "endTime": 1762240800,
  "daysOfWeek": [
    "Monday",
    "Wednesday",
    "Friday"
  ],
  "active": true,
  "runAfterScheduleTaskId": 1000,
  "applicationId": 2001
}
```

## Get a DAS schedule.

`GET /das/v1/tasks/schedules/:id`

Success: 200.

This end-point gets a schedule in Data Access Security.

## Update a schedule.

`PUT /das/v1/tasks/schedules/:id`

Success: 204.

Body:

```json
{
  "taskTypeName": "DataSync",
  "scheduleType": "Daily",
  "interval": 1440,
  "scheduleTaskName": "Daily Data Sync",
  "startTime": 1762237200,
  "endTime": 1762240800,
  "daysOfWeek": [
    "Monday",
    "Wednesday",
    "Friday"
  ],
  "active": true,
  "runAfterScheduleTaskId": 1000,
  "applicationId": 2001
}
```

## Delete a DAS schedule.

`DELETE /das/v1/tasks/schedules/:id`

Success: 204.

This end-point sends a request to delete a schedule in Data Access Security.

## Create application

`POST /das/v1/applications`

Success: 204.

This endpoint creates a new application in Data Access Security with the specified configuration.

Body:

```json
{
  "applicationType": 9,
  "name": "HR File Server",
  "description": "Stores HR documents and employee records.",
  "tags": [
    {
      "key": 1,
      "value": "Confidential"
    }
  ],
  "identityCollectorId": 123456789,
  "adIdentityCollectorId": 987654321,
  "nisIdentityCollectorId": 192837465,
  "applicationCrawlerSettings": {
    "isEnabled": true,
    "clusterId": "cluster-001",
    "calculateResourceSize": 2,
    "crawlSnapshotsFolder": true,
    "crawlMailboxes": false,
    "crawlPublicFolders": true,
    "excludedPathsByRegex": "^/archive/.*",
    "crawlTopLevelShares": [
      "share1",
      "share2"
    ],
    "excludedResources": [
      "resourceA",
      "resourceB"
    ],
    "includeResources": [
      "resourceX",
      "resourceY"
    ]
  },
  "permissionCollectorSettings": {
    "isEnabled": true,
    "clusterId": "cluster-001",
    "analyzeUniquePermissions": true,
    "calculateEffectivePermissions": true,
    "calculateRiskiestPermissions": false,
    "effectivePermissionsSource": "S3"
  },
  "dataClassificationSettings": {
    "isEnabled": true,
    "clusterId": "cluster-001"
  },
  "activityConfigurationSettings": {
    "isEnabled": true,
```

Body example truncated.

## Search applications in DAS.

`GET /das/v1/applications`

Success: 200.

This endpoint lists all the applications in Data Access Security with optional filtering.

Query:

- standard: `limit`, `offset`, `count`
- filters: appIds (eq, in); tagIds (eq, in); statuses (eq, in); groupCodes (eq, in); virtualAppId (eq); appName (eq); supportsValidation (eq)

## Update application by identifier.

`PUT /das/v1/applications/:id`

Success: 204.

This endpoint updates an existing application in Data Access Security with the specified configuration.

Body:

```json
{
  "applicationType": 9,
  "name": "HR File Server",
  "description": "Stores HR documents and employee records.",
  "tags": [
    {
      "key": 1,
      "value": "Confidential"
    }
  ],
  "identityCollectorId": 123456789,
  "adIdentityCollectorId": 987654321,
  "nisIdentityCollectorId": 192837465,
  "applicationCrawlerSettings": {
    "isEnabled": true,
    "clusterId": "cluster-001",
    "calculateResourceSize": 2,
    "crawlSnapshotsFolder": true,
    "crawlMailboxes": false,
    "crawlPublicFolders": true,
    "excludedPathsByRegex": "^/archive/.*",
    "crawlTopLevelShares": [
      "share1",
      "share2"
    ],
    "excludedResources": [
      "resourceA",
      "resourceB"
    ],
    "includeResources": [
      "resourceX",
      "resourceY"
    ]
  },
  "permissionCollectorSettings": {
    "isEnabled": true,
    "clusterId": "cluster-001",
    "analyzeUniquePermissions": true,
    "calculateEffectivePermissions": true,
    "calculateRiskiestPermissions": false,
    "effectivePermissionsSource": "S3"
  },
  "dataClassificationSettings": {
    "isEnabled": true,
    "clusterId": "cluster-001"
  },
  "activityConfigurationSettings": {
    "isEnabled": true,
```

Body example truncated.

## Delete an application by identifier.

`DELETE /das/v1/applications/:id`

Success: 204.

This endpoint deletes an application from Data Access Security by its unique identifier.

## Retrieve application details by identifier.

`GET /das/v1/applications/:id`

Success: 200.

This endpoint retrieves the details of a specific application in Data Access Security by its unique identifier.

## List identity collectors

`GET /das/v1/identity-collectors`

Success: 200.

This endpoint lists the identity collectors in Data Access Security with optional filtering and pagination.

Sorting is not supported for this endpoint; supplying the `sorters` query parameter results in a validation error.

Query:

- standard: `limit`, `offset`, `count`
- filters: sourceId (eq); type (eq, in); id (eq, in); name (eq, co)

## Create identity collector

`POST /das/v1/identity-collectors`

Success: 200.

This endpoint creates a new identity collector in Data Access Security for the specified source. The identity collector type is derived from the source.

Optionally configure `users` and `groups` to register source attributes (`properties`) and map them to data dictionary fields by name (`fieldMappings.fieldDictionaryName`). When omitted, both collections are created with fixed columns only.

Body:

```json
{
  "name": "Active Directory Identity Collector",
  "sourceId": "2c9180835d2e5168015d32f890ca1581",
  "users": {
    "properties": [
      "UserAddress",
      "department"
    ],
    "fieldMappings": [
      {
        "fieldDictionaryName": "UPTF-1",
        "sourceAttributeName": "department"
      },
      {
        "fieldDictionaryName": "UPTF-1",
        "sourceAttributeName": "department"
      }
    ]
  },
  "groups": {
    "properties": [
      "UserAddress",
      "department"
    ],
    "fieldMappings": [
      {
        "fieldDictionaryName": "UPTF-1",
        "sourceAttributeName": "department"
      },
      {
        "fieldDictionaryName": "UPTF-1",
        "sourceAttributeName": "department"
      }
    ]
  }
}
```

## List identity collector types

`GET /das/v1/identity-collectors/types`

Success: 200.

Returns the public identity collector type display names exposed for metadata and UI discovery. This endpoint lists base types only (for example, `Box` rather than `Box SaaS`). SaaS variants are not listed here; the identity collector type is derived from `sourceId` when creating an identity collector. Existing identity collectors may still report SaaS variant types in list and update responses.

Pagination is not supported for this endpoint; the full set of public types is always returned.

Query:

- standard: `limit`, `offset`

## List built-in identity collector properties

`GET /das/v1/identity-collectors/properties`

Success: 200.

Returns the built-in source attribute names for users and groups collections. When no filter is provided, built-in properties for all public identity collector types are returned (the same base types listed by List Identity Collector Types). When filtered by `type`, only the matching type is returned; the filter accepts any supported type display name, including SaaS variants such as `Box SaaS` or `AWS SaaS`.

These attributes are always available for field mapping without being listed in `properties`.

Query:

- filters: type (eq)

## Replace identity collector

`PUT /das/v1/identity-collectors/:id`

Success: 204.

Fully replaces an existing identity collector in Data Access Security. This is a PUT operation, not a partial update: the request body must contain the complete resource representation. Omitted or null top-level properties are rejected. After a successful request, a subsequent list request returns exactly the configuration that was sent.

Retrieve the current configuration with List Identity Collectors before replacing it. The `sourceId` and `type` cannot be changed and must match the current values.

Body:

```json
{
  "name": "Active Directory Identity Collector",
  "sourceId": "2c9180835d2e5168015d32f890ca1581",
  "type": "Active Directory",
  "users": {
    "properties": [
      "UserAddress",
      "department"
    ],
    "fieldMappings": [
      {
        "fieldDictionaryName": "UPTF-1",
        "sourceAttributeName": "department"
      },
      {
        "fieldDictionaryName": "UPTF-1",
        "sourceAttributeName": "department"
      }
    ]
  },
  "groups": {
    "properties": [
      "UserAddress",
      "department"
    ],
    "fieldMappings": [
      {
        "fieldDictionaryName": "UPTF-1",
        "sourceAttributeName": "department"
      },
      {
        "fieldDictionaryName": "UPTF-1",
        "sourceAttributeName": "department"
      }
    ]
  }
}
```

## Delete identity collector by identifier

`DELETE /das/v1/identity-collectors/:id`

Success: 204.

This endpoint deletes an identity collector from Data Access Security by its unique identifier.

## List data dictionary fields

`GET /das/v1/permissions/fields`

Success: 200.

Returns custom data dictionary fields that can be used when configuring identity collector field mappings and other permission-related settings. Built-in fields are not included in list responses; only custom fields created via Create Data Dictionary Field are returned. All listed fields have `required: false`.

Query:

- standard: `limit`, `offset`, `count`
- filters: dataDictionaryType (eq); name (eq)

## Create data dictionary field

`POST /das/v1/permissions/fields`

Success: 201.

Creates a custom data dictionary field. The server assigns fieldType String and required false; callers do not supply those values.

Body:

```json
{
  "name": "Department",
  "dataDictionaryType": "Users"
}
```

## Replace data dictionary field

`PUT /das/v1/permissions/fields/:name`

Success: 200.

Fully replaces a custom data dictionary field. This is a PUT operation, not a partial update: the request body must contain the complete resource representation. Omitted properties are rejected. For custom fields, `fieldType`, `dataDictionaryType`, and `required` must match the current values; only `name` may change. Built-in fields where `required` is true cannot be updated.

List the field first with List Data Dictionary Fields to obtain the current representation before replacing it.

Body:

```json
{
  "name": "Cost Center",
  "fieldType": "String",
  "dataDictionaryType": "Users",
  "required": false
}
```

## Delete data dictionary field

`DELETE /das/v1/permissions/fields/:name`

Success: 204.

Deletes a custom data dictionary field. Built-in fields where required is true cannot be deleted.

## Retrieve owners per application.

`GET /das/v1/owners/applications/:appId`

Success: 200.

Query:

- standard: `limit`, `offset`

## List owners for resource.

`GET /das/v1/owners/resources/:resourceId`

Success: 200.

Query:

- standard: `limit`, `offset`

## List resources for owner.

`GET /das/v1/owners/:ownerIdentityId/resources`

Success: 200.

Query:

- standard: `limit`, `offset`

## Assign owner to application resource.

`POST /das/v1/owners/assign`

Success: 200.

Body:

```json
{
  "appId": 12345,
  "fullPath": "/shared/hr/documents/employee-records.pdf",
  "identityId": "d290f1ee-6c54-4b01-90e6-d701748f0851"
}
```

## Reassign resource owner.

`POST /das/v1/owners/:sourceIdentityId/reassign/:destinationIdentityId`

Success: 200.

## Re-elect resource owner.

`POST /das/v1/owners/reelect`

Success: 200.

Body:

```json
{
  "ownerId": "c1a2b3d4-e5f6-7890-abcd-1234567890ab",
  "campaignName": "Annual Resource Owner Election",
  "reviewers": [
    "c3783e6c-5562-aafc-2cfc-ebd2eaff40a5",
    "2c235b68-0283-cace-3195-20cb93baada7"
  ]
}
```
