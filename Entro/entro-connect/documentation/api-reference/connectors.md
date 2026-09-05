Connectors | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/api-reference/connectors.md).GitBook AssistantAskOn this page

Get connector data
GitBook Assistant
### List connectors[#get-v1-connectors](#get-v1-connectors)
gethttps://api.entro.security/v1/connectorsAuthorizationsApi-KeyAuthorizationstringRequiredResponses200

Successful response
application/jsonget/v1/connectorsHTTPGitBook AssistantAskCopy
```
GET /v1/connectors HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
[
  {
    "uid": "20975b39-33c7-442c-9ec0-ad3aec10ab5e",
    "name": "Fearful Elephant",
    "status": "active",
    "integrations": [
      "JENKINS",
      "GITHUB",
      "OKTA",
      "ATLASSIAN",
      "GITLAB",
      "SLACK_ONPREM",
      "SLACK",
      "JFROG",
      "AWS",
      "BITBUCKET",
      "AZURE",
      "GCP",
      "SERVICE_NOW",
      "SNOWFLAKE",
      "AZURE_DEVOPS",
      "FILES_SHARING",
      "VAULT",
      "GOOGLE_WORKSPACE",
      "AKEYLESS"
    ]
  },
  {
    "uid": "c9061eb3-28f6-4790-b594-d0f175264b5a",
    "name": "Fast Koala",
    "status": "active",
    "integrations": []
  }
]
```
[PreviousEmployee](/api-reference/employee)[NextAccounts](/api-reference/accounts)

Last updated 9 months ago
