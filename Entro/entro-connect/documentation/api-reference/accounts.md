Accounts | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/api-reference/accounts.md).GitBook AssistantAskOn this page

Get integration account data
GitBook Assistant
### List integrated accounts[#get-v1-accounts](#get-v1-accounts)
gethttps://api.entro.security/v1/accountsAuthorizationsApi-KeyAuthorizationstringRequiredResponses200

Successful response
application/jsonget/v1/accountsHTTPGitBook AssistantAskCopy
```
GET /v1/accounts HTTP/1.1
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
    "uid": "d10f7245-c3af-4653-911e-647d10a66f59",
    "accountType": "GITHUB",
    "environment": "entro-github-test",
    "status": "active",
    "connectorId": "29175b39-36c7-442a-9ac0-dc3dbc108b6e",
    "createdAt": "2025-07-30T12:31:27.452Z"
  },
  {
    "uid": "3e34ad66-16b8-446c-a7fa-c9e5e8ab69ff",
    "accountType": "SERVICE_NOW",
    "environment": "entro-servicenow-test",
    "status": "active",
    "connectorId": "1a9461fe-08ff-4c45-8294-6a3d1645c66e",
    "createdAt": "2025-08-18T19:37:08.719Z"
  },
  {
    "uid": "9c3cb14c-3dbd-44c3-b30c-3b2c027ae0eb",
    "accountType": "ATLASSIAN",
    "environment": "entro-jira-test",
    "status": "active",
    "connectorId": "29075f39-31c7-442c-9ec0-ad3fbc118b5e",
    "createdAt": "2025-09-16T14:26:17.588Z"
  }
]
```

### Check account status[#get-v1-accounts-health](#get-v1-accounts-health)
gethttps://api.entro.security/v1/accounts/healthAuthorizationsApi-KeyAuthorizationstringRequiredQuery parametersaccountUidstringRequired

The unique identifier for the account
Responses200

Successful response
application/jsonget/v1/accounts/healthHTTPGitBook AssistantAskCopy
```
GET /v1/accounts/health?accountUid=text HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "status": "ACTIVE",
  "lastVerified": "Oct 06, 2025 12:30 AM",
  "lastChecked": "Oct 06, 2025 12:30 AM",
  "nextVerification": "Oct 07, 2025 8:00 AM",
  "policies": {
    "Repository permissions ": [
      {
        "name": "security_events:read",
        "granted": false
      },
      {
        "name": "actions_variables:read",
        "granted": false
      },
      {
        "name": "checks:read",
        "granted": false
      },
      {
        "name": "deployments:read",
        "granted": false
      },
      {
        "name": "packages:read",
        "granted": false
      },
      {
        "name": "repository_hooks:read",
        "granted": false
      },
      {
        "name": "repository_projects:read",
        "granted": false
      },
      {
        "name": "secret_scanning_alerts:read",
        "granted": false
      },
      {
        "name": "vulnerability_alerts:read",
        "granted": false
      },
      {
        "name": "actions:read",
        "granted": false
      },
      {
        "name": "metadata:read",
        "granted": false
      },
      {
        "name": "pull_requests:read",
        "granted": false
      },
      {
        "name": "contents:read",
        "granted": false
      },
      {
        "name": "issues:read",
        "granted": false
      },
      {
        "name": "statuses:read",
        "granted": false
      }
    ],
    "Organization permissions": [
      {
        "name": "administration:read",
        "granted": false
      },
      {
        "name": "secrets:read",
        "granted": false
      },
      {
        "name": "environments:read",
        "granted": false
      },
      {
        "name": "pages:read",
        "granted": false
      }
    ],
    "Classic token": [
      {
        "name": "repo:status",
        "granted": true
      },
      {
        "name": "repo_deployment",
        "granted": true
      },
      {
        "name": "public_repo",
        "granted": true
      },
      {
        "name": "repo:invite",
        "granted": true
      },
      {
        "name": "security_events",
        "granted": true
      },
      {
        "name": "read:packages",
        "granted": true
      },
      {
        "name": "read:org",
        "granted": true
      },
      {
        "name": "read:public_key",
        "granted": true
      },
      {
        "name": "read:repo_hook",
        "granted": true
      },
      {
        "name": "notifications",
        "granted": true
      },
      {
        "name": "read:user",
        "granted": true
      },
      {
        "name": "user:email",
        "granted": true
      },
      {
        "name": "user:follow",
        "granted": true
      },
      {
        "name": "read:discussion",
        "granted": true
      },
      {
        "name": "read:enterprise",
        "granted": true
      },
      {
        "name": "read:audit_log",
        "granted": true
      },
      {
        "name": "read:project",
        "granted": true
      },
      {
        "name": "read:gpg_key",
        "granted": true
      },
      {
        "name": "read:ssh_signing_key",
        "granted": true
      }
    ]
  }
}
```
[PreviousConnectors](/api-reference/connectors)[NextIntegrations](/api-reference/integrations)

Last updated 9 months ago

- [getList integrated accounts](#get-v1-accounts)
- [getCheck account status](#get-v1-accounts-health)
