# Certification Campaigns

Use this API to implement certification campaign functionality.

22 endpoints. Paths are relative to the environment API host.

## List campaigns

`GET /campaigns/v1`

Success: 200.

Use this API to get a list of campaigns. This API can provide increased level of detail for each campaign for the correct provided query.

Query:

- standard: `limit`, `offset`, `count`
- `detail`: Determines whether slim, or increased level of detail is provided for each campaign in the returned list. Slim is the default behavior. (This can only be one of SLIM,FULL)
- filters: id (eq, in); name (eq, sw); status (eq, in)
- sorters: name, created

## Create a campaign

`POST /campaigns/v1`

Success: 202.

Use this API to create a certification campaign with the information provided in the request body.

When the request body references a campaign filter (`filter.type: CAMPAIGN_FILTER`), the token must include both
`idn:campaign:manage` and `idn:campaign-filter:read`.

Body:

```json
{
  "name": "Manager Review",
  "description": "A review of everyone's access by their manager.",
  "deadline": "2020-12-25T06:00:00.468Z",
  "type": "MANAGER",
  "emailNotificationEnabled": false,
  "autoRevokeAllowed": false,
  "recommendationsEnabled": false,
  "filter": {
    "type": "CAMPAIGN_FILTER",
    "id": "0c46fb26c6b20967a55517ee90d15b93"
  },
  "mandatoryCommentRequirement": "NO_DECISIONS"
}
```

## Get campaign

`GET /campaigns/v1/:id`

Success: 200.

Use this API to get information for an existing certification campaign by the campaign's ID.

Query:

- `detail`: Determines whether slim, or increased level of detail is provided for each campaign in the returned list. Slim is the default behavior. (This can only be one of SLIM,FULL)

## Update a campaign

`PATCH /campaigns/v1/:id`

Success: 200.

Use this API to update individual fields on a certification campaign, using the JSON Patch standard.

Body:

```json
[
  {
    "op": "replace",
    "path": "/name",
    "value": "This field has been updated!"
  },
  {
    "op": "copy",
    "from": "/name",
    "path": "/description"
  }
]
```

## Reassign certifications

`POST /campaigns/v1/:id/reassign`

Success: 202.

This API reassigns the specified certifications from one identity to another.

Body:

```json
{
  "certificationIds": [
    "af3859464779471211bb8424a563abc1",
    "af3859464779471211bb8424a563abc2",
    "af3859464779471211bb8424a563abc3"
  ],
  "reassignTo": {
    "id": "ef38f94347e94562b5bb8424a56397d8",
    "type": "IDENTITY"
  },
  "reason": "reassigned for some reason"
}
```

## Activate a campaign

`POST /campaigns/v1/:id/activate`

Success: 202.

Use this API to submit a job to activate the certified campaign with the specified ID. The campaign must be staged.

Body:

```json
{
  "timeZone": "-05:00"
}
```

## Complete a campaign

`POST /campaigns/v1/:id/complete`

Success: 202.

:::caution

This endpoint will run successfully for any campaigns that are **past due**.

This endpoint will return a content error if the campaign is **not past due**.

:::

Use this API to complete a certification campaign. This functionality is provided to admins so that they
can complete a certification even if all items have not been completed.

Body:

```json
{
  "autoCompleteAction": "REVOKE"
}
```

## Delete campaigns

`POST /campaigns/v1/delete`

Success: 202.

Use this API to delete certification campaigns whose IDs are specified in the provided list of campaign IDs.

Body:

```json
{
  "ids": [
    "2c9180887335cee10173490db1776c26",
    "2c9180836a712436016a7125a90c0021"
  ]
}
```

## Run campaign remediation scan

`POST /campaigns/v1/:id/run-remediation-scan`

Success: 202.

Use this API to run a remediation scan task for a certification campaign.

## Get campaign reports

`GET /campaigns/v1/:id/reports`

Success: 200.

Use this API to fetch all reports for a certification campaign by campaign ID.

## Run campaign report

`POST /campaigns/v1/:id/run-report/:type`

Success: 202.

Use this API to run a report for a certification campaign.

## Get campaign reports configuration

`GET /campaigns/v1/reports-configuration`

Success: 200.

Use this API to fetch the configuration for certification campaign reports. The configuration includes only one element - identity attributes defined as custom report columns.

## Set campaign reports configuration

`PUT /campaigns/v1/reports-configuration`

Success: 200.

Use this API to overwrite the configuration for campaign reports.

Body:

```json
{
  "identityAttributeColumns": [
    "firstname",
    "lastname"
  ]
}
```

## Create a campaign template

`POST /campaign-templates/v1`

Success: 200.

Use this API to create a certification campaign template based on campaign.

Body:

```json
{
  "name": "Manager Review",
  "description": "A review of everyone's access by their manager.",
  "deadlineDuration": "P2W",
  "campaign": {
    "name": "Manager Review",
    "description": "Review everyone's access.",
    "type": "MANAGER",
    "filter": {
      "type": "CAMPAIGN_FILTER",
      "id": "e0adaae69852e8fe8b8a3d48e5ce757c"
    },
    "emailNotificationEnabled": true,
    "autoRevokeAllowed": false,
    "recommendationsEnabled": false,
    "mandatoryCommentRequirement": "NO_DECISIONS"
  }
}
```

## List campaign templates

`GET /campaign-templates/v1`

Success: 200.

Use this API to get a list of all campaign templates. Scope can be reduced through standard V3 query params.

The API returns all campaign templates matching the query parameters.

Query:

- standard: `limit`, `offset`, `count`
- sorters: name, created, modified
- filters: name (eq, ge, gt, in, le, lt, ne, sw); id (eq, ge, gt, in, le, lt, ne, sw)

## Update a campaign template

`PATCH /campaign-templates/v1/:id`

Success: 200.

Use this API to update individual fields on a certification campaign template, using the JSON Patch standard.

Body:

```json
[
  {
    "op": "replace",
    "path": "/description",
    "value": "Updated description!"
  },
  {
    "op": "replace",
    "path": "/campaign/filter/id",
    "value": "ff80818155fe8c080155fe8d925b0316"
  }
]
```

## Get a campaign template

`GET /campaign-templates/v1/:id`

Success: 200.

Use this API to fetch a certification campaign template by ID.

## Delete a campaign template

`DELETE /campaign-templates/v1/:id`

Success: 204.

Use this API to delete a certification campaign template by ID.

## Get campaign template schedule

`GET /campaign-templates/v1/:id/schedule`

Success: 200.

Use this API to get the schedule for a certification campaign template. The API returns a 404 if there is no schedule set.

## Set campaign template schedule

`PUT /campaign-templates/v1/:id/schedule`

Success: 204.

Use this API to set the schedule for a certification campaign template. If a schedule already exists, the API overwrites it with the new one.

Body:

```json
{
  "type": "MONTHLY",
  "hours": {
    "type": "LIST",
    "values": [
      "17"
    ]
  },
  "days": {
    "type": "LIST",
    "values": [
      "15"
    ]
  }
}
```

## Delete campaign template schedule

`DELETE /campaign-templates/v1/:id/schedule`

Success: 204.

Use this API to delete the schedule for a certification campaign template. The API returns a 404 if there is no schedule set.

## Generate a campaign from template

`POST /campaign-templates/v1/:id/generate`

Success: 200.

Use this API to generate a new certification campaign from a campaign template.

When the template campaign references a campaign filter (`filter.type: CAMPAIGN_FILTER`), the token must include both `idn:campaign-template:manage` and `idn:campaign-filter:read`.

The campaign object contained in the template has special formatting applied to its name and description
fields that determine the generated campaign's name/description. Placeholders in those fields are
formatted with the current date and time upon generation.

Placeholders consist of a percent sign followed by a letter indicating what should be inserted. For
example, "%Y" inserts the current year, and a campaign template named "Campaign for %y" generates a
campaign called "Campaign for 2020" (assuming the year at generation time is 2020).

Valid placeholders are the date/time conversion suffix characters supported by java.util.Formatter.
