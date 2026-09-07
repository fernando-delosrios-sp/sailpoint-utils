GitHub Cloud Troubleshooting And Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/github/github-cloud-troubleshooting-and-validation.md).
## Validation After Onboarding[#validation-after-onboarding](#validation-after-onboarding)
1
#### In Entro Dashboard[#in-entro-dashboard](#in-entro-dashboard)

Navigate to **Management → Accounts & Integrations → GitHub**.
GitBook Assistant2
#### Confirm integration status[#confirm-integration-status](#confirm-integration-status)

Confirm integration status is **Verified**.
GitBook Assistant3
#### Check sync timestamp[#check-sync-timestamp](#check-sync-timestamp)

Check **Last Sync Timestamp** for recent data.
GitBook Assistant4
#### Review findings[#review-findings](#review-findings)

Review **Findings** for GitHub secrets or configuration anomalies.
GitBook Assistant
## Common Issues[#common-issues](#common-issues)
IssueCauseResolution

401 Unauthorized
GitBook Assistant

Invalid or expired token
GitBook Assistant

Recreate or refresh token
GitBook Assistant

403 Forbidden
GitBook Assistant

Missing `read` permissions
GitBook Assistant

Adjust scopes or permissions
GitBook Assistant

Callback failed
GitBook Assistant

Wrong installation ID
GitBook Assistant

Verify URL and reattempt
GitBook Assistant

Missing logs
GitBook Assistant

S3 not configured
GitBook Assistant

Check AWS S3 setup
GitBook Assistant
## API Validation Example[#api-validation-example](#api-validation-example)
curlGitBook AssistantAskCopy
```
curl -H "Authorization: <redacted> https://api.github.com/user
```

Expected: JSON response with authenticated user.
GitBook Assistant

- 

Read-only operations only
GitBook Assistant
- 

TLS 1.2+ enforced
GitBook Assistant
- 

AES-256 encryption used for all secrets and tokens
GitBook Assistant
[PreviousGitHub Real-Time Scanning](/integrations/code-and-ci-cd/github/github-real-time-scanning)[NextGitLab](/integrations/code-and-ci-cd/gitlab)

Last updated 4 months ago

- [Validation After Onboarding](#validation-after-onboarding)
- [Common Issues](#common-issues)
- [API Validation Example](#api-validation-example)
