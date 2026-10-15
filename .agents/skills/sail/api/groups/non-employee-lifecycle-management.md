# Non-Employee Lifecycle Management

Use this API to implement non-employee lifecycle management functionality.

32 endpoints. Paths are relative to the environment API host.

## Create non-employee record

`POST /non-employee-records/v1`

Success: 200.

This request will create a non-employee record.
Requires role context of `idn:nesr:create`

Body:

```json
{
  "accountName": "william.smith",
  "firstName": "William",
  "lastName": "Smith",
  "email": "william.smith@example.com",
  "phone": "5125555555",
  "manager": "jane.doe",
  "sourceId": "2c91808568c529c60168cca6f90c1313",
  "startDate": "2020-03-24T00:00:00-05:00",
  "endDate": "2021-03-25T00:00:00-05:00",
  "data": {
    "description": "Auditing"
  }
}
```

## List non-employee records

`GET /non-employee-records/v1`

Success: 200.

This gets a list of non-employee records. There are two contextual uses for this endpoint:
  1. The user has the role context of `idn:nesr:read`, in which case they can get a list of all of the non-employees.
  2. The user is an account manager, in which case they can get a list of the non-employees that they manage.

Query:

- standard: `limit`, `offset`, `count`
- sorters: id, accountName, sourceId, manager, firstName, lastName, email, phone, startDate, endDate, created, modified
- filters: sourceId (eq)

## Get a non-employee record

`GET /non-employee-records/v1/:id`

Success: 200.

This gets a non-employee record.
Requires role context of `idn:nesr:read`

## Update non-employee record

`PUT /non-employee-records/v1/:id`

Success: 200.

This request will update a non-employee record. There are two contextual uses for this endpoint:
  1. The user has the role context of `idn:nesr:update`, in which case they
update all available fields.
  2. The user is owner of the source, in this case they can only update the
end date.

Body:

```json
{
  "accountName": "william.smith",
  "firstName": "William",
  "lastName": "Smith",
  "email": "william.smith@example.com",
  "phone": "5125555555",
  "manager": "jane.doe",
  "sourceId": "2c91808568c529c60168cca6f90c1313",
  "startDate": "2020-03-24T00:00:00-05:00",
  "endDate": "2021-03-25T00:00:00-05:00",
  "data": {
    "description": "Auditing"
  }
}
```

## Patch non-employee record

`PATCH /non-employee-records/v1/:id`

Success: 200.

This request will patch a non-employee record. There are two contextual uses for this endpoint:
  1. The user has the role context of `idn:nesr:update`, in which case they
update all available fields.
  2. The user is owner of the source, in this case they can only update the
end date.

Body:

```json
[
  {
    "op": "replace",
    "path": "/endDate",
    "value": "2019-08-23T18:40:35.772Z"
  }
]
```

## Delete non-employee record

`DELETE /non-employee-records/v1/:id`

Success: 204.

This request will delete a non-employee record.
Requires role context of `idn:nesr:delete`

## Delete multiple non-employee records

`POST /non-employee-records/v1/bulk-delete`

Success: 204.

This request will delete multiple non-employee records based on the non-employee ids provided. Requires role context of `idn:nesr:delete`

Body:

```json
{
  "ids": [
    "2b838de9-db9b-abcf-e646-d4f274ad4238",
    "2d838de9-db9b-abcf-e646-d4f274ad4238"
  ]
}
```

## Create non-employee request

`POST /non-employee-requests/v1`

Success: 200.

This request will create a non-employee request and notify the approver. Requires role context of `idn:nesr:create` or the user must own the source.

Body:

```json
{
  "accountName": "william.smith",
  "firstName": "William",
  "lastName": "Smith",
  "email": "william.smith@example.com",
  "phone": "5125555555",
  "manager": "jane.doe",
  "sourceId": "2c91808568c529c60168cca6f90c1313",
  "startDate": "2020-03-24T00:00:00-05:00",
  "endDate": "2021-03-25T00:00:00-05:00",
  "data": {
    "description": "Auditing"
  }
}
```

## List non-employee requests

`GET /non-employee-requests/v1`

Success: 200.

This gets a list of non-employee requests. There are two contextual uses for the `requested-for` path parameter:
  1. The user has the role context of `idn:nesr:read`, in which case he or
she may request a list non-employee requests assigned to a particular account manager by passing in that manager's id.
  2. The current user is an account manager, in which case "me" should be
provided as the `requested-for` value. This will provide the user with a list of the non-employee requests in the source(s) he or she manages.

Query:

- standard: `limit`, `offset`, `count`
- `requested-for`: (Required) The identity for whom the request was made. *me* indicates the current user.
- sorters: created, approvalStatus, firstName, lastName, email, phone, accountName, startDate, endDate
- filters: sourceId (eq)

## Get a non-employee request

`GET /non-employee-requests/v1/:id`

Success: 200.

This gets a non-employee request.
There are two contextual uses for this endpoint:
  1. The user has the role context of `idn:nesr:read`, in this case the user
can get the non-employee request for any user.
  2. The user must be the owner of the non-employee request.

## Delete non-employee request

`DELETE /non-employee-requests/v1/:id`

Success: 204.

This request will delete a non-employee request.
Requires role context of `idn:nesr:delete`

## Get summary of non-employee requests

`GET /non-employee-requests/v1/summary/:requested-for`

Success: 200.

This request will retrieve a summary of non-employee requests. There are two contextual uses for the `requested-for` path parameter:
  1. The user has the role context of `idn:nesr:read`, in which case he or
she may request a summary of all non-employee approval requests assigned to a particular account manager by passing in that manager's id.
  2. The current user is an account manager, in which case "me" should be
provided as the `requested-for` value. This will provide the user with a summary of the non-employee requests in the source(s) he or she manages.

## Create non-employee source

`POST /non-employee-sources/v1`

Success: 200.

Create a non-employee source.

Body:

```json
{
  "owner": {
    "id": "2c91808570313110017040b06f344ec9"
  },
  "name": "Retail",
  "description": "Source description",
  "managementWorkgroup": "123299",
  "approvers": [
    {
      "id": "2c91808570313110017040b06f344ec9"
    },
    {
      "id": "2c91808570313110017040b06f344ec9"
    }
  ],
  "accountManagers": [
    {
      "id": "2c91808570313110017040b06f344ec9"
    },
    {
      "id": "2c91808570313110017040b06f344ec9"
    }
  ]
}
```

## List non-employee sources

`GET /non-employee-sources/v1`

Success: 200.

Get a list of non-employee sources. There are two contextual uses for the `requested-for` path parameter:
  1. If the user has the role context of `idn:nesr:read`, he or she may request a list sources assigned to a particular account manager by passing in that manager's `id`.
  2. If the current user is an account manager, the user should provide 'me' as the `requested-for` value. Doing so provide the user with a list of the sources he or she owns.

Query:

- standard: `limit`, `offset`, `count`
- `requested-for`: Identity the request was made for. Use 'me' to indicate the current user.
- `non-employee-count`: Flag that determines whether the API will return a non-employee count associated with the source.
- sorters: name, created, sourceId

## Get a non-employee source

`GET /non-employee-sources/v1/:sourceId`

Success: 200.

This gets a non-employee source. There are two contextual uses for the requested-for path parameter:
  1. The user has the role context of `idn:nesr:read`, in which case he or
she may request any source.
  2. The current user is an account manager, in which case the user can only
request sources that they own.

## Patch a non-employee source

`PATCH /non-employee-sources/v1/:sourceId`

Success: 200.

patch a non-employee source. (partial update) <br/> Patchable field: **name, description, approvers, accountManagers** Requires role context of `idn:nesr:update`.

Body:

```json
[
  {
    "op": "replace",
    "path": "/name",
    "value": {
      "new name": null
    }
  },
  {
    "op": "replace",
    "path": "/approvers",
    "value": [
      "2c91809f703bb37a017040a2fe8748c7",
      "48b1f463c9e8427db5a5071bd81914b8"
    ]
  }
]
```

## Delete non-employee source

`DELETE /non-employee-sources/v1/:sourceId`

Success: 204.

This request will delete a non-employee source. Requires role context of `idn:nesr:delete`.

## Exports non-employee records to csv

`GET /non-employee-sources/v1/:id/non-employees/download`

Success: 200.

This requests a CSV download for all non-employees from a provided source. Requires role context of `idn:nesr:read`

## Imports, or updates, non-employee records

`POST /non-employee-sources/v1/:id/non-employee-bulk-upload`

Success: 202.

This post will import, or update, Non-Employee records found in the CSV. Requires role context of `idn:nesr:create`

## Obtain the status of bulk upload on the source

`GET /non-employee-sources/v1/:id/non-employee-bulk-upload/status`

Success: 200.

The nonEmployeeBulkUploadStatus API returns the status of the newest bulk upload job for the specified source.
Requires role context of `idn:nesr:read`

## Exports source schema template

`GET /non-employee-sources/v1/:id/schema-attributes-template/download`

Success: 200.

This requests a download for the Source Schema Template for a provided source. Requires role context of `idn:nesr:read`

## Get list of non-employee approval requests

`GET /non-employee-approvals/v1`

Success: 200.

This gets a list of non-employee approval requests.
There are two contextual uses for this endpoint:
  1. The user has the role context of `idn:nesr:read`, in which case they
can list the approvals for any approver.
  2. The user owns the requested approval.

Query:

- standard: `limit`, `offset`, `count`
- `requested-for`: The identity for whom the request was made. *me* indicates the current user.
- filters: approvalStatus (eq)
- sorters: created, modified

## Get a non-employee approval item detail

`GET /non-employee-approvals/v1/:id`

Success: 200.

Gets a non-employee approval item detail. There are two contextual uses for this endpoint:
  1. The user has the role context of `idn:nesr:read`, in which case they
can get any approval.
  2. The user owns the requested approval.

Query:

- `include-detail`: The object nonEmployeeRequest will not be included detail when set to false. *Default value is true*

## Approve a non-employee request

`POST /non-employee-approvals/v1/:id/approve`

Success: 200.

Approves a non-employee approval request and notifies the next approver. The current user must be the requested approver.

Body:

```json
{
  "comment": "Approved by manager"
}
```

## Reject a non-employee request

`POST /non-employee-approvals/v1/:id/reject`

Success: 200.

This endpoint will reject an approval item request and notify user. The current user must be the requested approver.

Body:

```json
{
  "comment": "approved"
}
```

## Get summary of non-employee approval requests

`GET /non-employee-approvals/v1/summary/:requested-for`

Success: 200.

This request will retrieve a summary of non-employee approval requests. There are two contextual uses for the `requested-for` path parameter:
  1. The user has the role context of `idn:nesr:read`, in which case he or
she may request a summary of all non-employee approval requests assigned to a particular approver by passing in that approver's id.
  2. The current user is an approver, in which case "me" should be provided
as the `requested-for` value. This will provide the approver with a summary of the approval items assigned to him or her.

## List schema attributes non-employee source

`GET /non-employee-sources/v1/:sourceId/schema-attributes`

Success: 200.

This API gets the list of schema attributes for the specified Non-Employee SourceId. There are 8 mandatory attributes added to each new Non-Employee Source automatically. Additionaly, user can add up to 10 custom attributes. This interface returns all the mandatory attributes followed by any custom attributes. At most, a total of 18 attributes will be returned.
Requires role context of `idn:nesr:read` or the user must be an account manager of the source.

## Create a new schema attribute for non-employee source

`POST /non-employee-sources/v1/:sourceId/schema-attributes`

Success: 200.

This API creates a new schema attribute for Non-Employee Source. The schema technical name must be unique in the source. Attempts to create a schema attribute with an existing name will result in a "400.1.409 Reference conflict" response. At most, 10 custom attributes can be created per schema. Attempts to create more than 10 will result in a "400.1.4 Limit violation" response.
Requires role context of `idn:nesr:create`

Body:

```json
{
  "type": "TEXT",
  "technicalName": "account.name",
  "label": "Account Name",
  "helpText": "The unique identifier for the account",
  "placeholder": "Enter a unique user name for this account.",
  "required": true
}
```

## Delete all custom schema attributes for non-employee source

`DELETE /non-employee-sources/v1/:sourceId/schema-attributes`

Success: 204.

This end-point deletes all custom schema attributes for a non-employee source. Requires role context of `idn:nesr:delete`

## Get schema attribute non-employee source

`GET /non-employee-sources/v1/:sourceId/schema-attributes/:attributeId`

Success: 200.

This API gets a schema attribute by Id for the specified Non-Employee SourceId. Requires role context of `idn:nesr:read` or the user must be an account manager of the source.

## Patch a schema attribute for non-employee source

`PATCH /non-employee-sources/v1/:sourceId/schema-attributes/:attributeId`

Success: 200.

This end-point patches a specific schema attribute for a non-employee SourceId.
Requires role context of `idn:nesr:update`

Body:

```json
[
  {
    "op": "replace",
    "path": "/label",
    "value": {
      "new attribute label": null
    }
  }
]
```

## Delete a schema attribute for non-employee source

`DELETE /non-employee-sources/v1/:sourceId/schema-attributes/:attributeId`

Success: 204.

This end-point deletes a specific schema attribute for a non-employee source.
Requires role context of `idn:nesr:delete`
