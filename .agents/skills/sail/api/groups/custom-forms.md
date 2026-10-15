# Custom Forms

Use this API to build and manage custom forms.

18 endpoints. Paths are relative to the environment API host.

## List form definitions by tenant.

`GET /form-definitions/v1`

Success: 200.

No parameters required.

Query:

- standard: `limit`, `offset`
- filters: name (eq, gt, sw, in); description (eq, gt, sw, in); created (eq, gt, sw, in); modified (eq, gt, sw, in)
- sorters: name, description, created, modified

## Creates a form definition.

`POST /form-definitions/v1`

Success: 201.

Body:

```json
{
  "name": "my form",
  "description": "my form description",
  "owner": {
    "type": "IDENTITY",
    "id": "00000000-0000-0000-0000-000000000000"
  },
  "formElements": [
    {
      "id": "000000000000",
      "elementType": "SECTION",
      "config": {
        "alignment": "LEFT",
        "description": "elementType must be 'SECTION' for the root formElements,  child formElements must be within the 'config' attribute",
        "label": "Section",
        "labelStyle": "h2",
        "showLabel": true,
        "formElements": [
          {
            "id": "0000000000000",
            "key": "textField",
            "elementType": "TEXT",
            "config": {
              "default": "",
              "description": "",
              "helpText": "form element type text",
              "label": "Text Field",
              "placeholder": "",
              "required": false
            },
            "validations": []
          }
        ]
      }
    }
  ]
}
```

## Return a form definition.

`GET /form-definitions/v1/:formDefinitionID`

Success: 200.

Parameter `{formDefinitionID}` should match a form definition ID.

## Deletes a form definition.

`DELETE /form-definitions/v1/:formDefinitionID`

Success: 204.

Parameter `{formDefinitionID}` should match a form definition ID.

## Patch a form definition.

`PATCH /form-definitions/v1/:formDefinitionID`

Success: 200.

Parameter `{formDefinitionID}` should match a form definition ID.

Body:

```json
[
  {
    "op": "replace",
    "path": "/description",
    "value": "test-description"
  }
]
```

## Preview form definition data source.

`POST /form-definitions/v1/:formDefinitionID/data-source`

Success: 200.

Query:

- standard: `limit`
- filters: value (eq, ne, in)
- `query`: String that is passed to the underlying API to filter other (non-ID) fields. For example, for access profile data sources, this string will be passed to the access profile api and used with a "starts with" filter against several fields.

Body:

```json
{
  "dataSource": {
    "config": {
      "aggregationBucketField": "attributes.cloudStatus.exact",
      "indices": [
        "identities"
      ],
      "objectType": "IDENTITY",
      "query": "*"
    },
    "dataSourceType": "STATIC"
  }
}
```

## Export form definitions by tenant.

`GET /form-definitions/v1/export`

Success: 200.

No parameters required.

Query:

- standard: `limit`, `offset`
- filters: name (eq, gt, sw, in); description (eq, gt, sw, in); created (eq, gt, sw, in); modified (eq, gt, sw, in)
- sorters: name, description, created, modified

## Generate json schema dynamically.

`POST /form-definitions/v1/forms-action-dynamic-schema`

Success: 200.

Body:

```json
{
  "id": "sp:forms",
  "attributes": {
    "formDefinitionId": "00000000-0000-0000-0000-000000000000"
  },
  "description": "AnotherDescription",
  "type": "action",
  "versionNumber": 1
}
```

## Import form definitions from export.

`POST /form-definitions/v1/import`

Success: 202.

Body:

```json
[
  {
    "version": 1,
    "self": {
      "name": "All fields not required",
      "id": "05ed4edb-d0a9-41d9-ad0c-2f6e486ec4aa",
      "type": "FORM_DEFINITION"
    },
    "object": {
      "id": "05ed4edb-d0a9-41d9-ad0c-2f6e486ec4aa",
      "name": "All fields not required",
      "description": "description",
      "owner": {
        "type": "IDENTITY",
        "id": "3447d8ec2602455ab6f1e8408a0f0150"
      },
      "usedBy": [
        {
          "type": "WORKFLOW",
          "id": "5008594c-dacc-4295-8fee-41df60477304"
        },
        {
          "type": "WORKFLOW",
          "id": "97e75a75-c179-4fbc-a2da-b5fa4aaa8743"
        }
      ],
      "formInput": [
        {
          "type": "STRING",
          "label": "input1",
          "description": "A single dynamic scalar value (i.e. number, string, date, etc) that can be passed into the form for use in conditional logic"
        }
      ],
      "formElements": [
        {
          "id": "3069272797630701",
          "elementType": "SECTION",
          "config": {
            "label": "First Section",
            "formElements": [
              {
                "id": "3069272797630700",
```

Body example truncated.

## Upload new form definition file.

`POST /form-definitions/v1/:formDefinitionID/upload`

Success: 201.

Parameter `{formDefinitionID}` should match a form definition ID.

## Download definition file by fileid.

`GET /form-definitions/v1/:formDefinitionID/file/:fileID`

Success: 200.

## List form instances by tenant.

`GET /form-instances/v1`

Success: 200.

Returns a list of form instances for the tenant. Optionally filter by form definition ID.

Query:

- standard: `limit`
- filters: formDefinitionId (eq)

## Creates a form instance.

`POST /form-instances/v1`

Success: 201.

Body:

```json
{
  "expire": "2023-06-20T15:57:55.332882Z",
  "formDefinitionId": "00000000-0000-0000-0000-000000000000",
  "recipients": [
    {
      "type": "IDENTITY",
      "id": "an-identity-id"
    }
  ],
  "createdBy": {
    "type": "WORKFLOW_EXECUTION",
    "id": "a-workflow-execution-id"
  }
}
```

## Returns a form instance.

`GET /form-instances/v1/:formInstanceID`

Success: 200.

Parameter `{formInstanceID}` should match a form instance ID.

Only the assigned recipient (`recipients[].id` when `type` is `IDENTITY`) may call this.

## Patch a form instance.

`PATCH /form-instances/v1/:formInstanceID`

Success: 200.

Parameter `{formInstanceID}` should match a form instance ID.

Only the assigned recipient (`recipients[].id` when `type` is `IDENTITY`) may call this.

Body:

```json
[
  {
    "op": "replace",
    "path": "/state",
    "value": "SUBMITTED"
  },
  {
    "op": "replace",
    "path": "/formData",
    "value": {
      "a-key-1": "a-value-1",
      "a-key-2": true,
      "a-key-3": 1
    }
  }
]
```

## Retrieves dynamic data by element.

`GET /form-instances/v1/:formInstanceID/data-source/:formElementID`

Success: 200.

Parameter `{formInstanceID}` should match a form instance ID.
Parameter `{formElementID}` should match a form element ID at the data source configuration.

Query:

- standard: `limit`
- filters: value (eq, ne, in)
- `query`: String that is passed to the underlying API to filter other (non-ID) fields. For example, for access profile data sources, this string will be passed to the access profile api and used with a "starts with" filter against several fields.

## Download instance file by fileid.

`GET /form-instances/v1/:formInstanceID/file/:fileID`

Success: 200.

## List predefined select options.

`GET /form-definitions/v1/predefined-select-options`

Success: 200.

No parameters required.
