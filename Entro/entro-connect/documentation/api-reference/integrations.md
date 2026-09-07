Integrations | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/api-reference/integrations.md).GitBook AssistantAskOn this page

Onboard new integrations
GitBook Assistant
### Onboard new Atlassian account or update existing[#post-v1-integrations-atlassian](#post-v1-integrations-atlassian)
posthttps://api.entro.security/v1/integrations/atlassianAuthorizationsApi-KeyAuthorizationstringRequiredBodyapplication/jsonenvironmentstringRequiredurlstringRequiredusernamestringRequiredtokenstringRequiredconnector_idstringRequiredcloudIdstringRequiredis_cloudbooleanRequireduidstringOptional

Use the account UID to update the account
Responses200

Successful response
application/jsonpost/v1/integrations/atlassianHTTPGitBook AssistantAskCopy
```
POST /v1/integrations/atlassian HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Content-Type: application/json
Accept: */*
Content-Length: 241

{
  "environment": "prod",
  "url": "https://your-company.atlassian.net",
  "username": "user@example.com",
  "token": "atlassian-api-token",
  "connector_id": "connector-123",
  "cloudId": "12345678-1234-1234-1234-123456789123",
  "is_cloud": true,
  "uid": "account-123"
}
```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "message": "Atlassian onboarded successfully"
}
```

### Onboard new Gitlab account or update existing[#post-v1-integrations-gitlab](#post-v1-integrations-gitlab)
posthttps://api.entro.security/v1/integrations/gitlabAuthorizationsApi-KeyAuthorizationstringRequiredBodyapplication/jsonenvironmentstringRequiredurlstringRequiredportintegerRequiredusernamestringRequiredtokenstringRequiredconnector_idstringRequiredis_cloudbooleanRequireduidstringOptional

Use the account UID to update the account
Responses200

Successful response
application/jsonpost/v1/integrations/gitlabHTTPGitBook AssistantAskCopy
```
POST /v1/integrations/gitlab HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Content-Type: application/json
Accept: */*
Content-Length: 180

{
  "environment": "dev",
  "url": "https://gitlab.company.com",
  "port": 443,
  "username": "gitlab_user",
  "token": "gitlab-pat",
  "connector_id": "connector-456",
  "is_cloud": true,
  "uid": "account-123"
}
```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "message": "Gitlab onboarded successfully"
}
```
[PreviousAccounts](/api-reference/accounts)[NextIdentity Now](/api-reference/identity-now)

Last updated 9 months ago

- [postOnboard new Atlassian account or update existing](#post-v1-integrations-atlassian)
- [postOnboard new Gitlab account or update existing](#post-v1-integrations-gitlab)
