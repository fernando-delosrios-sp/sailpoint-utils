# Identity Profiles

Use this API to implement identity profile functionality.

11 endpoints. Paths are relative to the environment API host.

## List identity profiles

`GET /identity-profiles/v1`

Success: 200.

Get a list of identity profiles, based on the specified query parameters.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, ne, ge, gt, in, le, sw); name (eq, ne, ge, gt, in, le, sw); priority (eq, ne)
- sorters: id, name, priority, created, modified, owner.id, owner.name

## Create identity profile

`POST /identity-profiles/v1`

Success: 201.

Creates an identity profile.

Body:

```json
{
  "authoritativeSource": {
    "type": "SOURCE",
    "id": "2c9180835d191a86015d28455b4b232a",
    "name": "HR Active Directory"
  },
  "name": "aName",
  "description": "My custom flat file profile",
  "owner": {
    "type": "IDENTITY",
    "id": "2c9180835d191a86015d28455b4b232a",
    "name": "William Wilson"
  },
  "priority": 10,
  "identityRefreshRequired": true,
  "identityCount": 8,
  "identityAttributeConfig": {
    "enabled": true,
    "attributeTransforms": [
      {
        "identityAttributeName": "email",
        "transformDefinition": {
          "type": "accountAttribute",
          "attributes": {
            "attributeName": "e-mail",
            "sourceName": "MySource",
            "sourceId": "2c9180877a826e68017a8c0b03da1a53"
          }
        }
      },
      {
        "identityAttributeName": "email",
        "transformDefinition": {
          "type": "accountAttribute",
          "attributes": {
            "attributeName": "e-mail",
            "sourceName": "MySource",
            "sourceId": "2c9180877a826e68017a8c0b03da1a53"
          }
        }
      }
    ]
  },
  "identityExceptionReportReference": {
```

Body example truncated.

## Delete identity profiles

`POST /identity-profiles/v1/bulk-delete`

Success: 202.

This deletes multiple Identity Profiles via a list of supplied IDs.

On success, this endpoint will return a reference to the bulk delete task result.

The following rights are required to access this endpoint: idn:identity-profile:delete

Body:

```json
[
  "2c9180867b2a34e0017b3078d60b0699",
  "2c9180867b2a34e0017b3078d60b0698"
]
```

## Export identity profiles

`GET /identity-profiles/v1/export`

Success: 200.

This exports existing identity profiles in the format specified by the sp-config service.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, ne); name (eq, ne); priority (eq, ne)
- sorters: id, name, priority

## Import identity profiles

`POST /identity-profiles/v1/import`

Success: 200.

This imports previously exported identity profiles.

Body:

```json
[
  {
    "version": 1,
    "self": {
      "type": "SOURCE",
      "id": "2c9180835d191a86015d28455b4b232a",
      "name": "HR Active Directory"
    },
    "object": {
      "authoritativeSource": {
        "type": "SOURCE",
        "id": "2c9180835d191a86015d28455b4b232a",
        "name": "HR Active Directory"
      },
      "name": "aName",
      "description": "My custom flat file profile",
      "owner": {
        "type": "IDENTITY",
        "id": "2c9180835d191a86015d28455b4b232a",
        "name": "William Wilson"
      },
      "priority": 10,
      "identityRefreshRequired": true,
      "identityCount": 8,
      "identityAttributeConfig": {
        "enabled": true,
        "attributeTransforms": [
          {
            "identityAttributeName": "email",
            "transformDefinition": {
              "type": "accountAttribute",
              "attributes": {
                "attributeName": "e-mail",
                "sourceName": "MySource",
                "sourceId": "2c9180877a826e68017a8c0b03da1a53"
              }
            }
          },
          {
            "identityAttributeName": "email",
            "transformDefinition": {
```

Body example truncated.

## Get identity profile

`GET /identity-profiles/v1/:identity-profile-id`

Success: 200.

Get a single identity profile by ID.

## Delete identity profile

`DELETE /identity-profiles/v1/:identity-profile-id`

Success: 202.

Delete an identity profile by ID.
On success, this endpoint will return a reference to the bulk delete task result.

## Update identity profile

`PATCH /identity-profiles/v1/:identity-profile-id`

Success: 200.

Update a specified identity profile with this PATCH request.

You cannot update these fields:
* id
* created
* modified
* identityCount
* identityRefreshRequired
* Authoritative Source and Identity Attribute Configuration cannot be modified at the same time.

Body:

```json
[
  {
    "op": "add",
    "path": "/identityAttributeConfig/attributeTransforms/0",
    "value": {
      "identityAttributeName": "location",
      "transformDefinition": {
        "type": "accountAttribute",
        "attributes": {
          "sourceName": "Employees",
          "attributeName": "location",
          "sourceId": "2c91808878b7d63b0178c66ffcdc4ce4"
        }
      }
    }
  }
]
```

## Get default identity attribute config

`GET /identity-profiles/v1/:identity-profile-id/default-identity-attribute-config`

Success: 200.

This returns the default identity attribute config.

## Process identities under profile

`POST /identity-profiles/v1/:identity-profile-id/process-identities`

Success: 202.

Process identities under the profile
This operation should not be used to schedule your own identity processing or to perform system wide identity refreshes. The system will use a combination of event-based processing and scheduled processing that runs every day at 8:00 AM and 8:00 PM in the tenant's timezone to keep your identities synchronized.
This should only be run on identity profiles that have the `identityRefreshRequired` attribute set to `true`. If `identityRefreshRequired` is false, then there is no benefit to running this operation. Typically, this operation is performed when a change is made to the identity profile or its related lifecycle states that requires a refresh.
This operation will perform the following activities on all identities under the identity profile.
1. Updates identity attribute according to the identity profile mappings. 2. Determines the identity's correct manager through manager correlation. 3. Updates the identity's access according to their assigned lifecycle state. 4. Updates the identity's access based on role assignment criteria.

## Generate identity profile preview

`POST /identity-profiles/v1/identity-preview`

Success: 200.

This generates a non-persisted IdentityDetails object that will represent as the preview of the identities attribute when the given policy''s attribute config is applied.

Body:

```json
{
  "identityId": "cba44a6a-1c68-87c2-7b5b-fd65cd9534d8",
  "identityAttributeConfig": {
    "enabled": true,
    "attributeTransforms": [
      {
        "identityAttributeName": "email",
        "transformDefinition": {
          "type": "accountAttribute",
          "attributes": {
            "attributeName": "e-mail",
            "sourceName": "MySource",
            "sourceId": "2c9180877a826e68017a8c0b03da1a53"
          }
        }
      },
      {
        "identityAttributeName": "email",
        "transformDefinition": {
          "type": "accountAttribute",
          "attributes": {
            "attributeName": "e-mail",
            "sourceName": "MySource",
            "sourceId": "2c9180877a826e68017a8c0b03da1a53"
          }
        }
      }
    ]
  }
}
```
