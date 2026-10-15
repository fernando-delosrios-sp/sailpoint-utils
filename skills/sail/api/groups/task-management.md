# Task Management

3 endpoints. Paths are relative to the environment API host.

## Get task status by id

`GET /task-status/v1/:id`

Success: 200.

Get task status by task ID. Types of tasks include account and entitlement aggregation and other general background processing tasks.  Data for tasks older than 90 days will not be returned.

## Update task status by id

`PATCH /task-status/v1/:id`

Success: 200.

Update a current task status by task ID. Use this API to clear a pending task by updating the completionStatus and completed attributes.

Body:

```json
[
  {
    "op": "replace",
    "path": "/completionStatus",
    "value": "Error"
  },
  {
    "op": "replace",
    "path": "/completed",
    "value": "2024-05-17 19:33:16.470000+00:00"
  }
]
```

## Retrieve task status list

`GET /task-status/v1`

Success: 200.

Use this endpoint to get a list of statuses for **all** tasks, including completed, in-progress, terminated, and errored tasks. Types of tasks include account and entitlement aggregation and other general background processing tasks. Data for tasks older than 90 days will not be returned. For a list of **in-progress** tasks, apply the isnull filter to the Completion Status field.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq, in); sourceId (eq, in); completionStatus (eq, in, isnull); type (eq, in); launcher (eq, in)
- sorters: created
