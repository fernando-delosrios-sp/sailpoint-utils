# SOD Policies

Use this API to implement and manage "separation of duties" (SOD) policies.

17 endpoints. Paths are relative to the environment API host.

## Create sod policy

`POST /sod-policies/v1`

Success: 201.

This creates both General and Conflicting Access Based policy, with a limit of 50 entitlements for each (left & right) criteria for Conflicting Access Based SOD policy.
Requires role of ORG_ADMIN.

Body:

```json
{
  "name": "Conflicting-Policy-Name",
  "description": "This policy ensures compliance of xyz",
  "ownerRef": {
    "type": "IDENTITY",
    "id": "2c91808568c529c60168cca6f90c1313",
    "name": "Owner Name"
  },
  "externalPolicyReference": "XYZ policy",
  "compensatingControls": "Have a manager review the transaction decisions for their \"out of compliance\" employee",
  "correctionAdvice": "Based on the role of the employee, managers should remove access that is not required for their job function.",
  "state": "ENFORCED",
  "tags": [
    "string"
  ],
  "creatorId": "0f11f2a4-7c94-4bf3-a2bd-742580fe3bde",
  "modifierId": "0f11f2a4-7c94-4bf3-a2bd-742580fe3bde",
  "violationOwnerAssignmentConfig": {
    "assignmentRule": "MANAGER",
    "ownerRef": {
      "type": "IDENTITY",
      "id": "2c91808568c529c60168cca6f90c1313",
      "name": "Violation Owner Name"
    }
  },
  "scheduled": true,
  "type": "CONFLICTING_ACCESS_BASED",
  "conflictingAccessCriteria": {
    "leftCriteria": {
      "name": "money-in",
      "criteriaList": [
        {
          "type": "ENTITLEMENT",
          "id": "2c9180866166b5b0016167c32ef31a66"
        },
        {
          "type": "ENTITLEMENT",
```

Body example truncated.

## List sod policies

`GET /sod-policies/v1`

Success: 200.

This gets list of all SOD policies.
Requires role of ORG_ADMIN

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in); name (eq, in, sw, co); state (eq, in); level (eq, in); type (eq); description (eq, co, sw); ownerRef.name (eq, sw)
- sorters: id, name, created, modified, description, ownerRef.name

## Get sod policy by id

`GET /sod-policies/v1/:id`

Success: 200.

This gets specified SOD policy.
Requires role of ORG_ADMIN.

## Update sod policy by id

`PUT /sod-policies/v1/:id`

Success: 200.

This updates a specified SOD policy.
Requires role of ORG_ADMIN.

Body:

```json
{
  "name": "Conflicting-Policy-Name",
  "description": "Modified Description",
  "externalPolicyReference": "XYZ policy",
  "compensatingControls": "Have a manager review the transaction decisions for their \"out of compliance\" employee",
  "correctionAdvice": "Based on the role of the employee, managers should remove access that is not required for their job function.",
  "state": "ENFORCED",
  "tags": [
    "string"
  ],
  "violationOwnerAssignmentConfig": {
    "assignmentRule": "MANAGER",
    "ownerRef": {
      "type": "IDENTITY",
      "id": "2c91808568c529c60168cca6f90c1313",
      "name": "Violation Owner Name"
    }
  },
  "scheduled": true,
  "type": "CONFLICTING_ACCESS_BASED",
  "conflictingAccessCriteria": {
    "leftCriteria": {
      "name": "money-in",
      "criteriaList": [
        {
          "type": "ENTITLEMENT",
          "id": "2c9180866166b5b0016167c32ef31a66"
        },
        {
          "type": "ENTITLEMENT",
          "id": "2c9180866166b5b0016167c32ef31a67"
        }
      ]
    },
    "rightCriteria": {
      "name": "money-out",
      "criteriaList": [
        {
          "type": "ENTITLEMENT",
          "id": "2c9180866166b5b0016167c32ef31a68"
```

Body example truncated.

## Delete sod policy by id

`DELETE /sod-policies/v1/:id`

Success: 204.

This deletes a specified SOD policy.
Requires role of ORG_ADMIN.

Query:

- `logical`: Indicates whether this is a soft delete (logical true) or a hard delete. Soft delete marks the policy as deleted and just save it with this status. It could be fully deleted or recovered further. Hard delete vise versa permanently delete…

## Patch sod policy by id

`PATCH /sod-policies/v1/:id`

Success: 200.

Allows updating SOD Policy fields other than ["id","created","creatorId","policyQuery","type"] using the JSON Patch standard.
Requires role of ORG_ADMIN.
This endpoint can only patch CONFLICTING_ACCESS_BASED type policies. Do not use this endpoint to patch general policies - doing so will build an API exception.

Body:

```json
[
  {
    "op": "replace",
    "path": "/description",
    "value": "Modified description"
  },
  {
    "op": "replace",
    "path": "/conflictingAccessCriteria/leftCriteria/name",
    "value": "money-in-modified"
  },
  {
    "op": "replace",
    "path": "/conflictingAccessCriteria/rightCriteria",
    "value": {
      "name": "money-out-modified",
      "criteriaList": [
        {
          "type": "ENTITLEMENT",
          "id": "2c918087682f9a86016839c0509c1ab2"
        }
      ]
    }
  }
]
```

## Evaluate one policy by id

`POST /sod-policies/v1/:id/evaluate`

Success: 200.

Runs the scheduled report for the policy retrieved by passed policy ID.  The report schedule is fetched from the policy retrieved by ID.

## Get sod policy schedule

`GET /sod-policies/v1/:id/schedule`

Success: 200.

This endpoint gets a specified SOD policy's schedule.

## Update sod policy schedule

`PUT /sod-policies/v1/:id/schedule`

Success: 200.

This updates schedule for a specified SOD policy.

Body:

```json
{
  "name": "SCH-1584312283015",
  "description": "Schedule for policy xyz",
  "schedule": {
    "type": "WEEKLY",
    "hours": {
      "type": "RANGE",
      "values": [
        "9",
        "18"
      ],
      "interval": 3
    },
    "months": {
      "type": "LIST",
      "values": [
        "3",
        "6",
        "9",
        "12"
      ]
    },
    "days": {
      "type": "LIST",
      "values": [
        "MON",
        "WED",
        "FRI"
      ]
    },
    "expiration": "2018-06-25T20:22:28.104Z",
    "timeZoneId": "America/Chicago"
  },
  "recipients": [
    {
      "type": "IDENTITY",
      "id": "2c7180a46faadee4016fb4e018c20642",
      "name": "Michael Michaels"
    },
    {
      "type": "IDENTITY",
      "id": "2c7180a46faadee4016fb4e018c20642",
      "name": "Michael Michaels"
    }
  ],
  "emailEmptyResults": false
}
```

## Delete sod policy schedule

`DELETE /sod-policies/v1/:id/schedule`

Success: 204.

This deletes schedule for a specified SOD policy by ID.

## Runs sod policy violation report

`POST /sod-policies/v1/:id/violation-report/run`

Success: 200.

This invokes processing of violation report for given SOD policy. If the policy reports more than 5000 violations, the report returns with violation limit exceeded message.

## Get sod violation report status

`GET /sod-policies/v1/:id/violation-report`

Success: 200.

This gets the status for a violation report run task that has already been invoked.

## Get violation report run status

`GET /sod-policies/v1/sod-violation-report-status/:reportResultId`

Success: 200.

This gets the status for a violation report run task that has already been invoked.

## Runs all policies for org

`POST /sod-violation-report/v1/run`

Success: 200.

Runs multi-policy report for the org. If a policy reports more than 5000 violations, the report mentions that the violation limit was exceeded for that policy. If the request is empty, the report runs for all policies. Otherwise, the report runs for only the filtered policy list provided.

Body:

```json
{
  "filteredPolicyList": [
    "b868cd40-ffa4-4337-9c07-1a51846cfa94",
    "63a07a7b-39a4-48aa-956d-50c827deba2a"
  ]
}
```

## Get multi-report run task status

`GET /sod-violation-report/v1`

Success: 200.

This endpoint gets the status for a violation report for all policy run.

## Download violation report

`GET /sod-violation-report/v1/:reportResultId/download`

Success: 200.

This allows to download a violation report for a given report reference.

## Download custom violation report

`GET /sod-violation-report/v1/:reportResultId/download/:fileName`

Success: 200.

This allows to download a specified named violation report for a given report reference.
