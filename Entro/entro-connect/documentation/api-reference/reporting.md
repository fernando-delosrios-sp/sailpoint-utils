Reporting | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/api-reference/reporting.md).GitBook AssistantAskOn this page

Get reporting data
GitBook Assistant
### Get exposed secrets reporting data[#get-v1-reporting](#get-v1-reporting)
gethttps://api.entro.security/v1/reportingAuthorizationsApi-KeyAuthorizationstringRequiredResponses200

Successful response
application/jsonget/v1/reportingHTTPGitBook AssistantAskCopy
```
GET /v1/reporting HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "message": "[{\"account\": \"GITHUB\", \"exposedRisk\": \"exposed Risk\", \"total\": 10, \"resolved\": \"10%\"}]"
}
```
[PreviousScanner](/api-reference/scanner)[NextUtils](/api-reference/utils)

Last updated 9 months ago
