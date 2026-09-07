Scanner | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/api-reference/scanner.md).GitBook AssistantAskOn this page

Scan content for exposed secrets
GitBook Assistant
### Gets the scanner audit logs[#get-v1-scan-auditlogs](#get-v1-scan-auditlogs)
gethttps://api.entro.security/v1/scan/auditLogsAuthorizationsApi-KeyAuthorizationstringRequiredQuery parametersfromstringOptional

Date format dd/mm/yyyy
tostringOptional

Date format dd/mm/yyyy
Responses200

Real response is without redundancy
application/jsonget/v1/scan/auditLogsHTTPGitBook AssistantAskCopy
```
GET /v1/scan/auditLogs HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Real response is without redundancy
GitBook AssistantAskCopy
```
[
  {
    "request_id": "5ae363e4-0661-46cc-a56b-133b7fda1e9b",
    "secrets": [],
    "timestamp": 1741510628000,
    "date": "2025-03-09T08:57:08.000Z"
  },
  {
    "request_id": "b14b4819-e055-47bc-a4a5-2d6881211009",
    "secrets": [
      {
        "secret_type": "GITHUB_API_TOKEN",
        "exposed_value": "ghp_BT*******************ffv32CiUiw1R82UC7vz",
        "line_number": 1
      }
    ],
    "timestamp": 1741510053000,
    "date": "2025-03-09T08:47:33.000Z"
  }
]
```

### Scan content for exposed secrets[#post-v2-scan](#post-v2-scan)
posthttps://api.entro.security/v2/scanAuthorizationsApi-KeyAuthorizationstringRequiredQuery parametersgenericbooleanOptional

Allow generic secret type
redactbooleanOptional

Redact secrets from the response
Bodyapplication/jsonanyOptionalResponses200

Successful update
application/jsonpost/v2/scanHTTPGitBook AssistantAskCopy
```
POST /v2/scan HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Content-Type: application/json
Accept: */*
Content-Length: 51

{
  "data": "ghp_<redacted>"
}
```
Test it200

Successful update
GitBook AssistantAskCopy
```
{
  "requestId": "9752d9bd-58c4-4e98-9ab2-df5a50c79ccf",
  "totalCount": 1,
  "results": [
    {
      "origin": "GITHUB_API_TOKEN",
      "value": "ghp_<redacted>",
      "line": 1
    }
  ]
}
```
[PreviousExposed Secret](/api-reference/exposed-secret)[NextReporting](/api-reference/reporting)

Last updated 9 months ago

- [getGets the scanner audit logs](#get-v1-scan-auditlogs)
- [postScan content for exposed secrets](#post-v2-scan)
