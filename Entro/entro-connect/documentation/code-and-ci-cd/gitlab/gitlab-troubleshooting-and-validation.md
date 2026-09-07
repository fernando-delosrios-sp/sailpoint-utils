GitLab Troubleshooting And Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/gitlab/gitlab-troubleshooting-and-validation.md).
## Validation Steps After Connection[#validation-steps-after-connection](#validation-steps-after-connection)
1
#### In Entro Dashboard[#in-entro-dashboard](#in-entro-dashboard)

Go to **Management → Accounts & Integrations → GitLab**.
GitBook Assistant2
#### Verify Status[#verify-status](#verify-status)

Ensure the status shows **Verified**.
GitBook Assistant3
#### Confirm Last Sync[#confirm-last-sync](#confirm-last-sync)

Confirm the **Last Sync Timestamp** updates after successful connection.
GitBook Assistant4
#### Check Findings[#check-findings](#check-findings)

Check **Findings** for results from GitLab repositories.
GitBook Assistant
## API Scope Validation (Optional)[#api-scope-validation-optional](#api-scope-validation-optional)

Use curl to verify token access:
GitBook AssistantGitBook AssistantAskCopy
```
curl -H "Authorization: <redacted> https://gitlab.com/api/v4/user
```

Expected: JSON response with user information. If you receive `401` or `403`, confirm scopes and token validity.
GitBook Assistant
## Common Issues[#common-issues](#common-issues)
IssueCauseResolution

401 Unauthorized
GitBook Assistant

Expired or invalid token
GitBook Assistant

Recreate the token
GitBook Assistant

403 Forbidden
GitBook Assistant

Missing `read_api` or `read_repository` scopes
GitBook Assistant

Add scopes and retry
GitBook Assistant

Connection timeout
GitBook Assistant

Network or firewall block
GitBook Assistant

Check connector and outbound access
GitBook Assistant

Worker offline
GitBook Assistant

Worker Group not active
GitBook Assistant

If remote connector, verify its health
GitBook Assistant[PreviousGitLab Onboarding](/integrations/code-and-ci-cd/gitlab/gitlab-onboarding)[NextGit Clone Scanning (optional)](/integrations/code-and-ci-cd/git-clone-scanning-optional)

Last updated 2 months ago

- [Validation Steps After Connection](#validation-steps-after-connection)
- [API Scope Validation (Optional)](#api-scope-validation-optional)
- [Common Issues](#common-issues)
