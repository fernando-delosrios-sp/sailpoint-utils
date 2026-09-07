Utils | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/api-reference/utils.md).GitBook AssistantAskOn this page

Get reporting data
GitBook Assistant
### List risk sources[#get-v1-utils-risk-source](#get-v1-utils-risk-source)
gethttps://api.entro.security/v1/utils/risk-sourceAuthorizationsApi-KeyAuthorizationstringRequiredResponses200

Successful response
application/jsonget/v1/utils/risk-sourceHTTPGitBook AssistantAskCopy
```
GET /v1/utils/risk-source HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "riskSources": [
    "AWS_LAMBDA",
    "GCP_FUNCTION",
    "BITBUCKET_REPO_COMMIT",
    "AZURE_FUNCTION_APP",
    "AZURE_DEV_OPS_WIKI_PAGE"
  ]
}
```

### List risk categories[#get-v1-utils-risk-category](#get-v1-utils-risk-category)
gethttps://api.entro.security/v1/utils/risk-categoryAuthorizationsApi-KeyAuthorizationstringRequiredResponses200

Successful response
application/jsonget/v1/utils/risk-categoryHTTPGitBook AssistantAskCopy
```
GET /v1/utils/risk-category HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "riskCategories": [
    "CLOUD_SERVICE_RISKS",
    "ABNORMAL_BEHAVIOR",
    "MISCONFIGURATION",
    "SECRET_HYGINE",
    "EXPOSED_SECRET",
    "LEAST_PRIVILEGE",
    "MONITORING"
  ]
}
```

### List secret types[#get-v1-utils-secret-type](#get-v1-utils-secret-type)
gethttps://api.entro.security/v1/utils/secret-typeAuthorizationsApi-KeyAuthorizationstringRequiredResponses200

Successful response
application/jsonget/v1/utils/secret-typeHTTPGitBook AssistantAskCopy
```
GET /v1/utils/secret-type HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "secretTypes": [
    "AWS_IAM_ACCESS_KEY"
  ]
}
```
[PreviousReporting](/api-reference/reporting)[NextEmployee](/api-reference/employee)

Last updated 9 months ago

- [getList risk sources](#get-v1-utils-risk-source)
- [getList risk categories](#get-v1-utils-risk-category)
- [getList secret types](#get-v1-utils-secret-type)
