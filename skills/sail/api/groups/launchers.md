# Launchers

Use this API to manage Launchers. A launcher lets users start a workflow on demand from Identity Security Cloud, such as a Privileged Workflow or a workflow that creates an Active Directory group.

6 endpoints. Paths are relative to the environment API host.

## List all launchers for tenant

`GET /launchers/v1`

Success: 200.

Return a list of Launchers for the authenticated tenant

Query:

- standard: `limit`
- filters: description (sw); disabled (eq); name (sw)
- `next`: Pagination marker

## Create launcher

`POST /launchers/v1`

Success: 201.

Create a Launcher with given information

Body:

```json
{
  "name": "Group Create",
  "description": "Create a new Active Directory Group",
  "type": "INTERACTIVE_PROCESS",
  "disabled": false,
  "config": "{}",
  "reference": {
    "id": "2fd6ff94-2081-4d29-acbc-83a0a2f744a5",
    "type": "WORKFLOW"
  }
}
```

## Get launcher by id

`GET /launchers/v1/:launcherID`

Success: 200.

Get details for the given Launcher ID

## Replace launcher

`PUT /launchers/v1/:launcherID`

Success: 200.

Replace the given Launcher ID with given payload

Body:

```json
{
  "name": "Group Create",
  "description": "Create a new Active Directory Group",
  "type": "INTERACTIVE_PROCESS",
  "disabled": false,
  "config": "{}",
  "reference": {
    "id": "2fd6ff94-2081-4d29-acbc-83a0a2f744a5",
    "type": "WORKFLOW"
  }
}
```

## Delete launcher

`DELETE /launchers/v1/:launcherID`

Success: 204.

Delete the given Launcher ID

## Launch a launcher

`POST /launchers/v1/:launcherID/launch`

Success: 200.

Launch the given Launcher ID
