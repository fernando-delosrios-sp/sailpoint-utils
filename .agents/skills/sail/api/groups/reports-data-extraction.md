# Reports Data Extraction

Use this API to implement reports lifecycle managing and monitoring.

4 endpoints. Paths are relative to the environment API host.

## Get report result

`GET /reports/v1/:taskResultId/result`

Success: 200.

Get the report results for a report that was run or is running. Returns empty report result in case there are no active task definitions with used in payload task definition name.

Query:

- `completed`: state of task result to apply ordering when results are fetching from the DB

## Run report

`POST /reports/v1/run`

Success: 200.

Use this API to run a report according to report input details. If non-concurrent task is already running then it returns, otherwise new task creates and returns.

Body:

```json
{
  "reportType": "ACCOUNTS",
  "arguments": {
    "application": "2c9180897eSourceIde781782f705b9",
    "sourceName": "Active Directory"
  }
}
```

## Cancel report

`POST /reports/v1/:id/cancel`

Success: 204.

Cancels a running report.

## Get report file

`GET /reports/v1/:taskResultId`

Success: 200.

Gets a report in file format.

Query:

- `fileFormat`: (Required) Output format of the requested report file (This can only be one of csv,pdf)
- `name`: preferred Report file name, by default will be used report name from task result.
- `auditable`: Enables auditing for current report download. Will create an audit event and sent it to the REPORT cloud-audit kafka topic. Event will be created if there is any result present by requested taskResultId.
