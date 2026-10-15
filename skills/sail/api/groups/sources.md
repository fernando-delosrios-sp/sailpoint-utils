# Sources

Use this API to implement and customize source functionality.

77 endpoints. Paths are relative to the environment API host.

## List sources

`GET /sources/v1`

Success: 200.

This end-point lists all the sources.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in, ge, gt, le, lt, ne, isnull, sw); name (co, eq, in, sw, ge, gt, ne, isnull); type (eq, in, ge, gt, ne, isnull, sw); owner.id (eq, in, ge, gt, le, lt, ne, isnull, sw); features (ca, co); created (eq, ge, gt, in, le, lt, ne, isnull, sw); modified (eq, ge, gt, in, le, lt, ne, isnull, sw); managementWorkgroup.id (eq, ge, gt, in, le, lt, ne, isnull, sw); description (eq, sw); authoritative (eq, ne, isnull); healthy (isnull); status (eq, in, ge, gt, le, lt, ne, isnull, sw); connectionType (eq, ge, gt, in, le, lt, ne, isnull, sw); connectorName (eq, ge, gt, in, ne, isnull, sw); category (co, eq, ge, gt, in, le, lt, ne, sw)
- sorters: type, created, modified, name, owner.name, healthy, status, id, description, owner.id, accountCorrelationConfig.id, accountCorrelationConfig.name, managerCorrelationRule.type, managerCorrelationRule.id, managerCorrelationRule.name, authoritative, managementWorkgroup.id, connectorName, connectionType
- `for-subadmin`: Filter the returned list of sources for the identity specified by the parameter, which is the id of an identity with the role SOURCE_SUBADMIN. By convention, the value **me** indicates the identity id of the current user. Subadmins may…
- `includeIDNSource`: Include the IdentityNow source in the response.

## Create source

`POST /sources/v1`

Success: 201.

This creates a specific source with a full source JSON representation. Any passwords are submitted as plain-text and encrypted upon receipt.

Query:

- `provisionAsCsv`: If this parameter is `true`, it configures the source as a Delimited File (CSV) source. Setting this to `true` will automatically set the `type` of the source to `DelimitedFile`. You must use this query parameter to create a Delimited File…

Body:

```json
{
  "name": "My Source",
  "owner": {
    "type": "IDENTITY",
    "id": "2c91808568c529c60168cca6f90c1313",
    "name": "MyName"
  },
  "connector": "active-directory",
  "description": "This is the corporate directory.",
  "cluster": {
    "name": "Corporate Cluster",
    "id": "2c9180866166b5b0016167c32ef31a66",
    "type": "CLUSTER"
  },
  "accountCorrelationConfig": {
    "type": "ACCOUNT_CORRELATION_CONFIG",
    "id": "2c9180855d191c59015d28583727245a",
    "name": "Directory [source-62867] Account Correlation"
  },
  "accountCorrelationRule": {
    "type": "RULE",
    "id": "2c918085708c274401708c2a8a760001",
    "name": "Example Rule"
  },
  "managerCorrelationMapping": {
    "accountAttributeName": "manager",
    "identityAttributeName": "manager"
  },
  "managerCorrelationRule": {
    "type": "RULE",
    "id": "2c918085708c274401708c2a8a760001",
    "name": "Example Rule"
  },
  "beforeProvisioningRule": {
    "type": "RULE",
    "id": "2c918085708c274401708c2a8a760001",
    "name": "Example Rule"
  },
  "schemas": [
    {
      "type": "CONNECTOR_SCHEMA",
      "name": "account"
    },
    {
      "type": "CONNECTOR_SCHEMA",
      "name": "group"
    }
  ],
```

Body example truncated.

## Get source by id

`GET /sources/v1/:id`

Success: 200.

Use this API to get a source by a specified ID in Identity Security Cloud (ISC).

## Update source (full)

`PUT /sources/v1/:id`

Success: 200.

Use this API to update a source in Identity Security Cloud (ISC), using a full object representation. This means that when you use this API, it completely replaces the existing source configuration.

These fields are immutable, so they cannot be changed:

* id
* type
* authoritative
* connector
* connectorClass
* passwordPolicies

Attempts to modify these fields will result in a 400 error.

Body:

```json
{
  "name": "My Source",
  "owner": {
    "type": "IDENTITY",
    "id": "2c91808568c529c60168cca6f90c1313",
    "name": "MyName"
  },
  "connector": "active-directory",
  "description": "This is the corporate directory.",
  "cluster": {
    "name": "Corporate Cluster",
    "id": "2c9180866166b5b0016167c32ef31a66",
    "type": "CLUSTER"
  },
  "accountCorrelationConfig": {
    "type": "ACCOUNT_CORRELATION_CONFIG",
    "id": "2c9180855d191c59015d28583727245a",
    "name": "Directory [source-62867] Account Correlation"
  },
  "accountCorrelationRule": {
    "type": "RULE",
    "id": "2c918085708c274401708c2a8a760001",
    "name": "Example Rule"
  },
  "managerCorrelationMapping": {
    "accountAttributeName": "manager",
    "identityAttributeName": "manager"
  },
  "managerCorrelationRule": {
    "type": "RULE",
    "id": "2c918085708c274401708c2a8a760001",
    "name": "Example Rule"
  },
  "beforeProvisioningRule": {
    "type": "RULE",
    "id": "2c918085708c274401708c2a8a760001",
    "name": "Example Rule"
  },
  "schemas": [
    {
      "type": "CONNECTOR_SCHEMA",
      "name": "account"
    },
    {
      "type": "CONNECTOR_SCHEMA",
      "name": "group"
    }
  ],
```

Body example truncated.

## Update source (partial)

`PATCH /sources/v1/:id`

Success: 200.

Use this API to partially update a source in Identity Security Cloud (ISC), using a list of patch operations according to the
JSON Patch standard.

These fields are immutable, so they cannot be changed:

* id
* type
* authoritative
* created
* modified
* connector
* connectorClass
* passwordPolicies

Attempts to modify these fields will result in a 400 error.

Body:

```json
[
  {
    "op": "replace",
    "path": "/description",
    "value": "new description"
  }
]
```

## Delete source by id

`DELETE /sources/v1/:id`

Success: 202.

Use this API to delete a specific source in Identity Security Cloud (ISC).
The API removes all the accounts on the source first, and then it deletes the source. You can retrieve the actual task execution status with this method: GET `/task-status/{id}`

## Lists provisioningpolicies

`GET /sources/v1/:sourceId/provisioning-policies`

Success: 200.

This end-point lists all the ProvisioningPolicies in IdentityNow.

Query:

- standard: `limit`, `offset`

## Create provisioning policy (POST /sources/v1/:sourceId/provisioning-policies)

`POST /sources/v1/:sourceId/provisioning-policies`

Success: 201.

This API generates a create policy/template based on field value transforms. This API is intended for use when setting up JDBC Provisioning type sources, but it will also work on other source types.
Transforms can be used in the provisioning policy to create a new attribute that you only need during provisioning.
Refer to Transforms in Provisioning Policies for more information.

Body:

```json
{
  "name": "Account",
  "description": "Account Provisioning Policy",
  "usageType": "CREATE",
  "fields": [
    {
      "name": "displayName",
      "transform": {
        "type": "identityAttribute",
        "attributes": {
          "name": "displayName"
        }
      },
      "attributes": {},
      "isRequired": false,
      "type": "string",
      "isMultiValued": false
    },
    {
      "name": "distinguishedName",
      "transform": {
        "type": "usernameGenerator",
        "attributes": {
          "sourceCheck": true,
          "patterns": [
            "CN=$fi $ln,OU=zzUsers,OU=Demo,DC=seri,DC=sailpointdemo,DC=com",
            "CN=$fti $ln,OU=zzUsers,OU=Demo,DC=seri,DC=sailpointdemo,DC=com",
            "CN=$fn $ln,OU=zzUsers,OU=Demo,DC=seri,DC=sailpointdemo,DC=com",
            "CN=$fn$ln${uniqueCounter},OU=zzUsers,OU=Demo,DC=seri,DC=sailpointdemo,DC=com"
          ],
          "fn": {
            "type": "identityAttribute",
            "attributes": {
              "name": "firstname"
            }
          },
          "ln": {
            "type": "identityAttribute",
            "attributes": {
              "name": "lastname"
            }
          },
```

Body example truncated.

## Get provisioning policy by usagetype

`GET /sources/v1/:sourceId/provisioning-policies/:usageType`

Success: 200.

This end-point retrieves the ProvisioningPolicy with the specified usage on the specified Source in IdentityNow.

## Update provisioning policy by usagetype

`PUT /sources/v1/:sourceId/provisioning-policies/:usageType`

Success: 200.

This end-point updates the provisioning policy with the specified usage on the specified source in IdentityNow.
Transforms can be used in the provisioning policy to create a new attribute that you only need during provisioning.
Refer to Transforms in Provisioning Policies for more information.

Body:

```json
{
  "name": "example provisioning policy for inactive identities",
  "description": "this provisioning policy creates access based on an identity going inactive",
  "usageType": "CREATE",
  "fields": [
    {
      "name": "userName",
      "transform": {
        "type": "rule",
        "attributes": {
          "name": "Create Unique LDAP Attribute"
        }
      },
      "attributes": {
        "template": "{firstname}.{lastname}{uniqueCounter}",
        "cloudMaxUniqueChecks": "50",
        "cloudMaxSize": "20",
        "cloudRequired": "true"
      },
      "type": "string",
      "isMultiValued": false
    },
    {
      "name": "userName",
      "transform": {
        "type": "rule",
        "attributes": {
          "name": "Create Unique LDAP Attribute"
        }
      },
      "attributes": {
        "template": "{firstname}.{lastname}{uniqueCounter}",
        "cloudMaxUniqueChecks": "50",
        "cloudMaxSize": "20",
        "cloudRequired": "true"
      },
      "type": "string",
      "isMultiValued": false
    }
  ]
}
```

## Partial update of provisioning policy (PATCH /sources/v1/:sourceId/provisioning-policies/:usageType)

`PATCH /sources/v1/:sourceId/provisioning-policies/:usageType`

Success: 200.

This API selectively updates an existing Provisioning Policy using a JSONPatch payload.
Transforms can be used in the provisioning policy to create a new attribute that you only need during provisioning.
Refer to Transforms in Provisioning Policies for more information.

Body:

```json
[
  {
    "op": "add",
    "path": "/fields/0",
    "value": {
      "name": "email",
      "transform": {
        "type": "identityAttribute",
        "attributes": {
          "name": "email"
        }
      },
      "attributes": {},
      "isRequired": false,
      "type": "string",
      "isMultiValued": false
    }
  }
]
```

## Delete provisioning policy by usagetype

`DELETE /sources/v1/:sourceId/provisioning-policies/:usageType`

Success: 204.

Deletes the provisioning policy with the specified usage on an application.

## Lists Provisioning Policies

`GET /sources/v2/:sourceId/provisioning-policies`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This end-point lists all the ProvisioningPolicies in IdentityNow.

Query:

- standard: `limit`, `offset`
- filters: subtypeId (eq); usageType (eq)

## Create provisioning policy (POST /sources/v2/:sourceId/provisioning-policies)

`POST /sources/v2/:sourceId/provisioning-policies`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 201.

This API generates a create policy/template based on field value transforms. This API is intended for use when setting up JDBC Provisioning type sources, but it will also work on other source types.
Transforms can be used in the provisioning policy to create a new attribute that you only need during provisioning.
The V2 API allows you to use a unique identifier (id) for each provisioning policy instead of usageType. This enables read, update, and delete operations on policies using their id.
Note: The subtypeId field is required if usageType is CREATE_MACHINE_ACCOUNT.
Refer to Transforms in Provisioning Policies for more information.

Query:

- `useDefaultFields`: If passed as true, then it uses default fields from the connector template.

Body:

```json
{
  "name": "Account",
  "description": "Account Provisioning Policy",
  "usageType": "CREATE",
  "fields": [
    {
      "name": "displayName",
      "transform": {
        "type": "identityAttribute",
        "attributes": {
          "name": "displayName"
        }
      },
      "attributes": {},
      "isRequired": false,
      "type": "string",
      "isMultiValued": false
    },
    {
      "name": "distinguishedName",
      "transform": {
        "type": "usernameGenerator",
        "attributes": {
          "sourceCheck": true,
          "patterns": [
            "CN=$fi $ln,OU=zzUsers,OU=Demo,DC=seri,DC=sailpointdemo,DC=com",
            "CN=$fti $ln,OU=zzUsers,OU=Demo,DC=seri,DC=sailpointdemo,DC=com",
            "CN=$fn $ln,OU=zzUsers,OU=Demo,DC=seri,DC=sailpointdemo,DC=com",
            "CN=$fn$ln<uniqueCounter>,OU=zzUsers,OU=Demo,DC=seri,DC=sailpointdemo,DC=com"
          ],
          "fn": {
            "type": "identityAttribute",
            "attributes": {
              "name": "firstname"
            }
          },
          "ln": {
            "type": "identityAttribute",
            "attributes": {
              "name": "lastname"
            }
          },
```

Body example truncated.

## Get provisioning policy by ID

`GET /sources/v2/:sourceId/provisioning-policies/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This end-point retrieves the ProvisioningPolicy with the specified ID on the specified Source in Identity Security Cloud.

## Update provisioning policy by ID

`PUT /sources/v2/:sourceId/provisioning-policies/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This end-point updates the provisioning policy with the specified ID on the specified source in Identity Security Cloud.
Transforms can be used in the provisioning policy to create a new attribute that you only need during provisioning.
Refer to Transforms in Provisioning Policies for more information.

Body:

```json
{
  "name": "example provisioning policy for inactive identities",
  "id": "d7ae9ea3-507f-4d00-9d4f-b4464b344b88",
  "subtypeId": "d7ae9ea3-507f-4d00-9d4f-b4464b344b88",
  "description": "this provisioning policy creates access based on an identity going inactive",
  "usageType": "CREATE",
  "fields": [
    {
      "name": "userName",
      "transform": {
        "type": "rule",
        "attributes": {
          "name": "Create Unique LDAP Attribute"
        }
      },
      "attributes": {
        "template": "firstname.lastname.uniqueCounter",
        "cloudMaxUniqueChecks": "50",
        "cloudMaxSize": "20",
        "cloudRequired": "true"
      },
      "type": "string",
      "isMultiValued": false
    },
    {
      "name": "userName",
      "transform": {
        "type": "rule",
        "attributes": {
          "name": "Create Unique LDAP Attribute"
        }
      },
      "attributes": {
        "template": "firstname.lastname.uniqueCounter",
        "cloudMaxUniqueChecks": "50",
        "cloudMaxSize": "20",
        "cloudRequired": "true"
      },
      "type": "string",
      "isMultiValued": false
    }
  ]
}
```

## Partial update of provisioning policy (PATCH /sources/v2/:sourceId/provisioning-policies/:id)

`PATCH /sources/v2/:sourceId/provisioning-policies/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API selectively updates an existing Provisioning Policy using a JSONPatch payload.
Transforms can be used in the provisioning policy to create a new attribute that you only need during provisioning.
Refer to Transforms in Provisioning Policies for more information.

Body:

```json
[
  {
    "op": "add",
    "path": "/fields/0",
    "value": {
      "name": "email",
      "transform": {
        "type": "identityAttribute",
        "attributes": {
          "name": "email"
        }
      },
      "attributes": {},
      "isRequired": false,
      "type": "string",
      "isMultiValued": false
    }
  }
]
```

## Delete provisioning policy by ID

`DELETE /sources/v2/:sourceId/provisioning-policies/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

Deletes the provisioning policy with the specified ID on an application.

## Bulk update provisioning policies

`POST /sources/v1/:sourceId/provisioning-policies/bulk-update`

Success: 200.

This end-point updates a list of provisioning policies on the specified source in IdentityNow.

Body:

```json
[
  {
    "name": "example provisioning policy for inactive identities",
    "description": "this provisioning policy creates access based on an identity going inactive",
    "usageType": "CREATE",
    "fields": [
      {
        "name": "userName",
        "transform": {
          "type": "rule",
          "attributes": {
            "name": "Create Unique LDAP Attribute"
          }
        },
        "attributes": {
          "template": "{firstname}.{lastname}{uniqueCounter}",
          "cloudMaxUniqueChecks": "50",
          "cloudMaxSize": "20",
          "cloudRequired": "true"
        },
        "type": "string",
        "isMultiValued": false
      },
      {
        "name": "userName",
        "transform": {
          "type": "rule",
          "attributes": {
            "name": "Create Unique LDAP Attribute"
          }
        },
        "attributes": {
          "template": "{firstname}.{lastname}{uniqueCounter}",
          "cloudMaxUniqueChecks": "50",
          "cloudMaxSize": "20",
          "cloudRequired": "true"
        },
        "type": "string",
        "isMultiValued": false
      }
    ]
  },
  {
```

Body example truncated.

## List datasets on source

`GET /sources/v1/:sourceId/datasets`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to list datasets for the specified source in Identity Security Cloud (ISC).

Query:

- standard: `limit`, `offset`, `count`

## Create dataset on source

`POST /sources/v1/:sourceId/datasets`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 201.

Use this API to create a dataset on the specified source in Identity Security Cloud (ISC).

This operation requires a connector with the `supportDatasetCreation` label. `name` is required.
The dataset `id` is always server-generated from `name` as `customer:` plus a normalized form of
the name; any client-supplied `id` is ignored.

Body:

```json
{
  "name": "Applications",
  "description": "CMDB application records for this source."
}
```

## Get source dataset by id

`GET /sources/v1/:sourceId/datasets/:datasetId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to get a dataset by id for the specified source in Identity Security Cloud (ISC).

## Update source dataset (full)

`PUT /sources/v1/:sourceId/datasets/:datasetId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to replace a dataset on the specified source in Identity Security Cloud (ISC).

Callers should round-trip the GET representation. `id` is required in the request body and must
match the path. `aggregationEnabled` may always be updated. `name`, `description`, and `resources`
can be changed only when the connector has the `supportDatasetCreation` label.

Body:

```json
{
  "id": "cmdb-servicenow:applications",
  "name": "Applications",
  "description": "CMDB application records for this source.",
  "aggregationEnabled": true,
  "resources": [
    {
      "id": "aws:iam-role",
      "name": "Role",
      "type": "std:resource"
    }
  ]
}
```

## Update source dataset (partial)

`PATCH /sources/v1/:sourceId/datasets/:datasetId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to selectively update an existing dataset using a JSONPatch payload.

`aggregationEnabled` may always be updated. `name`, `description`, and `resources` can be changed
only when the connector has the `supportDatasetCreation` label. `id` is immutable.

Body:

```json
[
  {
    "op": "replace",
    "path": "/aggregationEnabled",
    "value": true
  }
]
```

## Delete source dataset by id

`DELETE /sources/v1/:sourceId/datasets/:datasetId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

Use this API to delete a dataset on the specified source in Identity Security Cloud (ISC).

This operation requires a connector with the `supportDatasetCreation` label. Linked resource
schemas are not deleted.

## Aggregate source dataset

`POST /sources/v1/:sourceId/datasets/:datasetId/aggregate`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Starts an aggregation for the specified dataset on the source in Identity Security Cloud (ISC).
An optional `config` object can be supplied for connector-specific aggregation settings.

Body:

```json
{
  "config": {
    "region": "us-east-1"
  }
}
```

## Delete objects for source dataset

`POST /sources/v1/:sourceId/datasets/:datasetId/delete-objects`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Starts a task to delete aggregated objects for the specified dataset on the source in Identity
Security Cloud (ISC). Linked dataset and resource definitions are not deleted.

## List resources for a source

`GET /sources/v1/:sourceId/resources`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to list resources defined on the specified source in Identity Security Cloud (ISC).

Query:

- standard: `limit`, `offset`, `count`

## Create resource on source

`POST /sources/v1/:sourceId/resources`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 201.

Use this API to create a resource on the specified source in Identity Security Cloud (ISC).

This operation requires a connector with the `supportDatasetCreation` label. `name`, `type`,
`datasetId`, and `schema` are required. The `schema` must define at least one attribute plus
`identityAttribute` and `displayAttribute`. The resource `id` is always server-generated from
`name` as `customer:` plus a normalized form of the name; any client-supplied `id` is ignored.
After creation, schema attribute edits are made through the source schema APIs.

Body:

```json
{
  "name": "Account",
  "type": "std:resource",
  "datasetId": "cmdb-servicenow:applications",
  "features": [
    "Create",
    "Delete"
  ],
  "schema": {
    "identityAttribute": "NAME",
    "displayAttribute": "NAME",
    "attributes": [
      {
        "name": "NAME",
        "type": "STRING",
        "isMultiValued": false,
        "isEntitlement": false,
        "isGroup": false
      }
    ]
  }
}
```

## Get source resource mappings

`GET /sources/v1/:sourceId/resources/mappings`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to get aggregation metadata for resources on the specified source in Identity
Security Cloud (ISC). The response is keyed by resource id. Each value includes the linked
dataset id, resource type, and connector object type. Resources without a matching schema are
omitted.

## Get source resource by id

`GET /sources/v1/:sourceId/resources/:resourceId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to get a resource by id on the specified source in Identity Security Cloud (ISC).
The response includes the full CIS schema for the resource.

## Update source resource (full)

`PUT /sources/v1/:sourceId/resources/:resourceId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to replace a resource on the specified source in Identity Security Cloud (ISC).

After creation, schema attribute edits should be made through the source schema APIs. Connectors
with the `supportDatasetCreation` label can update additional resource fields.

Body:

```json
{
  "name": "Account",
  "features": [
    "Create",
    "Delete"
  ],
  "type": "std:resource",
  "datasetId": "cmdb-servicenow:applications",
  "schema": {
    "id": "2c9180835d191a86015d28455b4a2329",
    "name": "account",
    "nativeObjectType": "User",
    "identityAttribute": "sAMAccountName",
    "displayAttribute": "distinguishedName",
    "hierarchyAttribute": "memberOf",
    "includePermissions": false,
    "features": [
      "PROVISIONING",
      "NO_PERMISSIONS_PROVISIONING",
      "GROUPS_HAVE_MEMBERS"
    ],
    "configuration": {
      "groupMemberAttribute": "member"
    },
    "attributes": [
      {
        "name": "sAMAccountName",
        "type": "STRING",
        "isMultiValued": false,
        "isEntitlement": false,
        "isGroup": false
      },
      {
        "name": "memberOf",
        "type": "STRING",
        "schema": {
          "type": "CONNECTOR_SCHEMA",
          "name": "group"
        },
        "description": "Group membership",
        "isMultiValued": true,
        "isEntitlement": true,
        "isGroup": true
      }
    ],
    "created": "2019-12-24T22:32:58.104Z",
    "modified": "2019-12-31T20:22:28.104Z"
  }
}
```

## Update source resource (partial)

`PATCH /sources/v1/:sourceId/resources/:resourceId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to selectively update an existing resource using a JSONPatch payload.

After creation, schema attribute edits should be made through the source schema APIs. Connectors
with the `supportDatasetCreation` label can update additional resource fields.

Body:

```json
[
  {
    "op": "replace",
    "path": "/features",
    "value": [
      "Create",
      "Delete"
    ]
  }
]
```

## Delete source resource by id

`DELETE /sources/v1/:sourceId/resources/:resourceId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

Use this API to delete a resource on the specified source in Identity Security Cloud (ISC).

The resource schema is deleted and the resource is unlinked from any dataset rows on the source.

## List schemas on source

`GET /sources/v1/:sourceId/schemas`

Success: 200.

Use this API to list the schemas that exist on the specified source in Identity Security Cloud (ISC).

Query:

- `include-types`: If set to 'group', then the account schema is filtered and only group schemas are returned. Only a value of 'group' is recognized presently. Note: The API will check whether include-types is group or not, if not, it will list schemas based…
- `include-names`: A comma-separated list of schema names to filter result.

## Create schema on source

`POST /sources/v1/:sourceId/schemas`

Success: 201.

Use this API to create a new schema on the specified source in Identity Security Cloud (ISC).

Body:

```json
{
  "id": "2c9180835d191a86015d28455b4a2329",
  "name": "account",
  "nativeObjectType": "User",
  "identityAttribute": "sAMAccountName",
  "displayAttribute": "distinguishedName",
  "hierarchyAttribute": "memberOf",
  "includePermissions": false,
  "features": [
    "PROVISIONING",
    "NO_PERMISSIONS_PROVISIONING",
    "GROUPS_HAVE_MEMBERS"
  ],
  "configuration": {
    "groupMemberAttribute": "member"
  },
  "attributes": [
    {
      "name": "sAMAccountName",
      "type": "STRING",
      "isMultiValued": false,
      "isEntitlement": false,
      "isGroup": false
    },
    {
      "name": "memberOf",
      "type": "STRING",
      "schema": {
        "type": "CONNECTOR_SCHEMA",
        "name": "group"
      },
      "description": "Group membership",
      "isMultiValued": true,
      "isEntitlement": true,
      "isGroup": true
    }
  ],
  "created": "2019-12-24T22:32:58.104Z",
  "modified": "2019-12-31T20:22:28.104Z"
}
```

## List schedules on source

`GET /sources/v1/:sourceId/schedules`

Success: 200.

Use this API to list the schedules that exist on the specified source in Identity Security Cloud (ISC).
:::info
This endpoint uses a **cron expression** to schedule a task, following standard **cron job syntax**.

For example, `0 0 12 1/1 * ? *` runs the task **daily at 12:00 PM**.

**Days of the week are represented as 1-7 (Sunday-Saturday).**
:::

## Create schedule on source

`POST /sources/v1/:sourceId/schedules`

Success: 201.

Use this API to create a new schedule for a type on the specified source in Identity Security Cloud (ISC).

Body:

```json
{
  "type": "ACCOUNT_AGGREGATION",
  "cronExpression": "0 0 5,13,21 * * ?"
}
```

## Get source schedule by type

`GET /sources/v1/:sourceId/schedules/:scheduleType`

Success: 200.

Get the source schedule by type in Identity Security Cloud (ISC).

## Update source schedule (partial)

`PATCH /sources/v1/:sourceId/schedules/:scheduleType`

Success: 200.

Use this API to selectively update an existing Schedule using a JSONPatch payload.

The following schedule fields are immutable and cannot be updated:

- type

Body:

```json
[
  {
    "op": "replace",
    "path": "/cronExpression",
    "value": "0 0 6 * * ?"
  }
]
```

## Delete source schedule by type.

`DELETE /sources/v1/:sourceId/schedules/:scheduleType`

Success: 204.

## Get source schema by id

`GET /sources/v1/:sourceId/schemas/:schemaId`

Success: 200.

Get the Source Schema by ID in IdentityNow.

## Update source schema (full)

`PUT /sources/v1/:sourceId/schemas/:schemaId`

Success: 200.

This API will completely replace an existing Schema with the submitted payload. Some fields of the Schema cannot be updated. These fields are listed below.

* id
* name
* created
* modified

Any attempt to modify these fields will result in an error response with a status code of 400.

> `id` must remain in the request body, but it cannot be changed.  If `id` is omitted from the request body, the result will be a 400 error.

Body:

```json
{
  "id": "2c9180835d191a86015d28455b4a2329",
  "name": "account",
  "nativeObjectType": "User",
  "identityAttribute": "sAMAccountName",
  "displayAttribute": "distinguishedName",
  "hierarchyAttribute": "memberOf",
  "includePermissions": false,
  "features": [
    "PROVISIONING",
    "NO_PERMISSIONS_PROVISIONING",
    "GROUPS_HAVE_MEMBERS"
  ],
  "configuration": {
    "groupMemberAttribute": "member"
  },
  "attributes": [
    {
      "name": "sAMAccountName",
      "type": "STRING",
      "isMultiValued": false,
      "isEntitlement": false,
      "isGroup": false
    },
    {
      "name": "memberOf",
      "type": "STRING",
      "schema": {
        "type": "CONNECTOR_SCHEMA",
        "name": "group"
      },
      "description": "Group membership",
      "isMultiValued": true,
      "isEntitlement": true,
      "isGroup": true
    }
  ],
  "created": "2019-12-24T22:32:58.104Z",
  "modified": "2019-12-31T20:22:28.104Z"
}
```

## Update source schema (partial)

`PATCH /sources/v1/:sourceId/schemas/:schemaId`

Success: 200.

Use this API to selectively update an existing Schema using a JSONPatch payload.

The following schema fields are immutable and cannot be updated:

- id
- name
- created
- modified

To switch an account attribute to a group entitlement, you need to have the following in place:

- `isEntitlement: true`
- Must define a schema for the group and add it to the source before updating the `isGroup` flag.  For example, here is the `group` account attribute referencing a schema that defines the group:
```json
{
    "name": "groups",
    "type": "STRING",
    "schema": {
        "type": "CONNECTOR_SCHEMA",
        "id": "2c9180887671ff8c01767b4671fc7d60",
        "name": "group"
    },
    "description": "The groups, roles etc. that reference account group objects",
    "isMulti": true,
    "isEntitlement": true,
    "isGroup": true
}
```

Body:

```json
[
  {
    "op": "add",
    "path": "/attributes/-",
    "value": {
      "name": "location",
      "type": "STRING",
      "schema": null,
      "description": "Employee location",
      "isMulti": false,
      "isEntitlement": false,
      "isGroup": false
    }
  }
]
```

## Delete source schema by id

`DELETE /sources/v1/:sourceId/schemas/:schemaId`

Success: 204.

## Fetches source health by id

`GET /sources/v1/:sourceId/source-health`

Success: 200.

This endpoint fetches source health by source's id

## Downloads source accounts schema template

`GET /sources/v1/:id/schemas/accounts`

Success: 200.

This API downloads the CSV schema that defines the account attributes on a source.
>**NOTE: This API is designated only for Delimited File sources.**

## Uploads source accounts schema template

`POST /sources/v1/:id/schemas/accounts`

Success: 200.

This API uploads a source schema template file to configure a source's account attributes.

To retrieve the file to modify and upload, log into Identity Now.

Click **Admin** -> **Connections** -> **Sources** -> **`{SourceName}`** -> **Import Data** -> **Account Schema** -> **Options** -> **Download Schema**

>**NOTE: This API is designated only for Delimited File sources.**

## Downloads source entitlements schema template

`GET /sources/v1/:id/schemas/entitlements`

Success: 200.

This API downloads the CSV schema that defines the entitlement attributes on a source.

>**NOTE: This API is designated only for Delimited File sources.**

Query:

- `schemaName`: Name of entitlement schema

## Uploads source entitlements schema template

`POST /sources/v1/:id/schemas/entitlements`

Success: 200.

This API uploads a source schema template file to configure a source's entitlement attributes.

To retrieve the file to modify and upload, log into Identity Now.

Click **Admin** -> **Connections** -> **Sources** -> **`{SourceName}`** -> **Import Data** -> **Import Entitlements** -> **Download**

>**NOTE: This API is designated only for Delimited File sources.**

Query:

- `schemaName`: Name of entitlement schema

## Upload connector file to source

`POST /sources/v1/:sourceId/upload-connector-file`

Success: 200.

This uploads a supplemental source connector file (like jdbc driver jars) to a source's S3 bucket. This also sends ETS and Audit events.

## Get source connections by id

`GET /sources/v1/:sourceId/connections`

Success: 200.

Use this API to get all dependent Profiles, Attributes, Applications and Custom Transforms for a source by a specified ID in Identity Security Cloud (ISC).

## Get source correlation configuration

`GET /sources/v1/:id/correlation-config`

Success: 200.

This API returns the existing correlation configuration for a source specified by the given ID.

## Update source correlation configuration

`PUT /sources/v1/:id/correlation-config`

Success: 200.

Replaces the correlation configuration for the source specified by the given ID with the configuration provided in the request body.

Body:

```json
{
  "id": "2c9180835d191a86015d28455b4a2329",
  "name": "Source [source] Account Correlation",
  "attributeAssignments": [
    {
      "property": "first_name",
      "value": "firstName",
      "operation": "EQ",
      "complex": false,
      "ignoreCase": false,
      "matchMode": "ANYWHERE",
      "filterString": "first_name == \"John\""
    },
    {
      "property": "first_name",
      "value": "firstName",
      "operation": "EQ",
      "complex": false,
      "ignoreCase": false,
      "matchMode": "ANYWHERE",
      "filterString": "first_name == \"John\""
    }
  ]
}
```

## Get Password Policy for source

`GET /sources/v1/:sourceId/password-policies`

Success: 200.

This API can be used to get Password Policy in IdentityNow for the specified Source.
Source must support PASSWORD feature.

Query:

- standard: `limit`, `offset`, `count`

## Update password policy

`PATCH /sources/v1/:sourceId/password-policies`

Success: 200.

This API can be used to set up or update Password Policy in IdentityNow for the specified Source.
Source must support PASSWORD feature.

Body:

```json
[
  {
    "policyId": "2c91808e7d976f3b017d9f5ceae440c8",
    "policyName": "Default",
    "selectors": null
  },
  {
    "policyId": "2c91808e7d976f3b017d9f5ceae440c8",
    "policyName": "PasswordPolicy Example",
    "selectors": {
      "identityAttr": [
        {
          "name": "displayName",
          "value": "Robert"
        },
        {
          "name": "lastname",
          "value": "Case"
        }
      ]
    }
  }
]
```

## Check connection for source connector.

`POST /sources/v1/:sourceId/connector/check-connection`

Success: 200.

This endpoint validates that the configured credentials are valid and will properly authenticate with the source identified by the sourceId path parameter.

## Peek source connector's resource objects

`POST /sources/v1/:sourceId/connector/peek-resource-objects`

Success: 200.

Retrieves a sample of data returned from account and group aggregation requests.

Body:

```json
{
  "objectType": "resource",
  "maxCount": 50
}
```

## Ping cluster for source connector

`POST /sources/v1/:sourceId/connector/ping-cluster`

Success: 200.

This endpoint validates that the cluster being used by the source is reachable from IdentityNow.

## Test configuration for source connector

`POST /sources/v1/:sourceId/connector/test-configuration`

Success: 200.

This endpoint performs a more detailed validation of the source''s configuration that can take longer than the lighter weight credential validation performed by the checkConnection API.

## Gets source config with language-translations

`GET /sources/v1/:id/connectors/source-config`

Success: 200.

Looks up and returns the source config for the requested source id after populating the source config values and applying language translations.

Query:

- `locale`: The locale to apply to the config. If no viable locale is given, it will default to "en" (This can only be one of de,false,fi,sv,ru,pt,ko,zh-TW,en,it,fr,zh-CN,hu,es,cs,ja,pl,da,nl)

## Native change detection configuration

`GET /sources/v1/:sourceId/native-change-detection-config`

Success: 200.

This API returns the existing native change detection configuration for a source specified by the given ID.

## Update native change detection configuration

`PUT /sources/v1/:sourceId/native-change-detection-config`

Success: 200.

Replaces the native change detection configuration for the source specified by the given ID with the configuration provided in the request body.

Body:

```json
{
  "enabled": true,
  "operations": [
    "ACCOUNT_UPDATED",
    "ACCOUNT_DELETED"
  ],
  "allEntitlements": false,
  "allNonEntitlementAttributes": false,
  "selectedEntitlements": [
    "memberOf",
    "memberOfSharedMailbox"
  ],
  "selectedNonEntitlementAttributes": [
    "lastName",
    "phoneNumber",
    "objectType",
    "servicePrincipalName"
  ]
}
```

## Delete native change detection configuration

`DELETE /sources/v1/:sourceId/native-change-detection-config`

Success: 204.

Deletes the native change detection configuration for the source specified by the given ID.

## Remove all accounts in source

`POST /sources/v1/:id/remove-accounts`

Success: 202.

Use this endpoint to remove all accounts from the system without provisioning changes to the source. Accounts that are removed could be re-created during the next aggregation.

This endpoint is good for:
* Removing accounts that no longer exist on the source.
* Removing accounts that won't be aggregated following updates to the source configuration.
* Forcing accounts to be re-created following the next aggregation to re-run account processing, support testing, etc.

## Account aggregation

`POST /sources/v1/:id/load-accounts`

Success: 202.

Starts an account aggregation on the specified source.
If the target source is a delimited file source, then the CSV file needs to be included in the request body.
You will also need to set the Content-Type header to `multipart/form-data`.

## Process uncorrelated accounts

`POST /sources/v1/:id/load-uncorrelated-accounts`

Success: 202.

File is required for upload. You will also need to set the Content-Type header to `multipart/form-data`

## Attribute sync config

`GET /sources/v1/:id/attribute-sync-config`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns the existing attribute synchronization configuration for a source specified by the given ID. The response contains all attributes, regardless of whether they enabled or not.

## Update attribute sync config

`PUT /sources/v1/:id/attribute-sync-config`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Replaces the attribute synchronization configuration for the source specified by the given ID with the configuration provided in the request body. Only the "enabled" field of the values in the "attributes" array is mutable. Attempting to change other attributes or add new values to the "attributes" array will result in an error.

Body:

```json
{
  "source": {
    "type": "SOURCE",
    "id": "2c9180835d191a86015d28455b4b232a",
    "name": "HR Active Directory"
  },
  "attributes": [
    {
      "name": "email",
      "displayName": "Email",
      "enabled": true,
      "target": "mail"
    },
    {
      "name": "firstname",
      "displayName": "First Name",
      "enabled": false,
      "target": "givenName"
    }
  ]
}
```

## Synchronize single source attributes.

`POST /sources/v1/:id/synchronize-attributes`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 202.

This end-point performs attribute synchronization for a selected source.

## Get source entitlement request configuration

`GET /sources/v1/:id/entitlement-request-config`

Success: 200.

This API gets the current entitlement request configuration for a source. This source-level configuration should apply for all the entitlements in the source.

Access request to any entitlements in the source should follow this configuration unless a separate entitlement-level configuration is defined.
- During access request, this source-level entitlement request configuration overrides the global organization-level configuration.
- However, the entitlement-level configuration (if defined) overrides this source-level configuration.

The `WORKFLOW` approver type is not supported in source-level configuration. To use a workflow as an approver, configure it on the entitlement with Replace entitlement request config. A source-level request that contains `WORKFLOW` fails with a 400.

## Update source entitlement request configuration

`PUT /sources/v1/:id/entitlement-request-config`

Success: 200.

This API replaces the current entitlement request configuration for a source. This source-level configuration should apply for all the entitlements in the source.

Access request to any entitlements in the source should follow this configuration unless a separate entitlement-level configuration is defined.
- During access request, this source-level entitlement request configuration overrides the global organization-level configuration.
- However, the entitlement-level configuration (if defined) overrides this source-level configuration.

The `WORKFLOW` approver type is not supported in source-level configuration. To use a workflow as an approver, configure it on the entitlement with Replace entitlement request config. A source-level request that contains `WORKFLOW` fails with a 400.

Body:

```json
{
  "accessRequestConfig": {
    "approvalSchemes": []
  }
}
```

## Entitlement aggregation

`POST /sources/v1/:sourceId/load-entitlements`

Success: 202.

Starts an entitlement aggregation on the specified source.
If the target source is a delimited file source, then the CSV file needs to be included in the request body.
You will also need to set the Content-Type header to `multipart/form-data`.
A token with ORG_ADMIN, SOURCE_ADMIN, or SOURCE_SUBADMIN authority is required to call this API.

## Machine Account Deletion Approval Config (GET /sources/v1/:sourceId/approval-config/machine-account-delete)

`GET /sources/v1/:sourceId/approval-config/machine-account-delete`

Success: 200.

Retrieves the machine account deletion approval configuration for a specific source. This endpoint returns details about the approval requirements, approvers, and comment settings that govern the deletion of machine accounts associated with the given source ID.

## Machine Account Deletion Approval Config (PATCH /sources/v1/:sourceId/approval-config/machine-account-delete)

`PATCH /sources/v1/:sourceId/approval-config/machine-account-delete`

Success: 200.

Use this endpoint to update the machine account deletion approval configuration for a specific source.
The update is performed using a JSON Patch payload, which allows partial modifications to the approval config.
This operation is typically used to change approval requirements, approvers, or comments settings for machine account deletion.
The endpoint expects the source ID as a path parameter and a valid JSON Patch array in the request body.

Body:

```json
[
  {
    "op": "replace",
    "path": "/approvalConfig/comments",
    "value": "ALL"
  }
]
```

## Human Account Deletion Approval Config (GET /sources/v1/:sourceId/approval-config/account-delete)

`GET /sources/v1/:sourceId/approval-config/account-delete`

Success: 200.

The endpoint retrieves the approval configuration for deleting human accounts from a specified source. It returns details such as whether approval is required, who the approvers are, and any additional approval settings. This helps administrators understand and manage the approval workflow for human account deletions in their organization. The response is provided as an AccountDeleteConfigDto object.

## Human Account Deletion Approval Config (PATCH /sources/v1/:sourceId/approval-config/account-delete)

`PATCH /sources/v1/:sourceId/approval-config/account-delete`

Success: 200.

Updates the approval configuration for deleting human accounts for a specific source, identified by source ID. This endpoint allows administrators to modify settings such as whether approval is required, who the approvers are, and other approval-related options. The update is performed using a JSON Patch payload, and the response returns the updated AccountDeleteConfigDto object reflecting the new approval workflow configuration.

Body:

```json
[
  {
    "op": "replace",
    "path": "/approvalConfig/comments",
    "value": "ALL"
  }
]
```
