JFrogArtifactory Troubleshooting And Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/container-registries/jfrog-artifactory/jfrogartifactory-troubleshooting-and-validation.md).
## Validation Steps After Connection[#validation-steps-after-connection](#validation-steps-after-connection)
1
#### Validate integration status[#validate-integration-status](#validate-integration-status)

In Entro Dashboard, navigate to **Management → Accounts & Integrations → JFrog Artifactory**.
GitBook Assistant2
#### Confirm Verified state[#confirm-verified-state](#confirm-verified-state)

Confirm the integration status displays **Verified**.
GitBook Assistant3
#### Check last sync[#check-last-sync](#check-last-sync)

Check the **Last Sync Timestamp** to ensure recent activity.
GitBook Assistant4
#### Verify findings[#verify-findings](#verify-findings)

Open **Findings** to verify secrets discovered from JFrog repositories.
GitBook Assistant
## API Scope Validation (Optional)[#api-scope-validation-optional](#api-scope-validation-optional)

Use curl to confirm token permissions:
GitBook AssistantGitBook AssistantAskCopy
```
curl -X GET "https://<your-jfrog-url>/access/api/v1/tokens/me" \
     -H "Authorization: <redacted>
```

Expected response: validation of the token used
GitBook Assistant
## Common Issues[#common-issues](#common-issues)
IssueCauseResolution

401 Unauthorized
GitBook Assistant

Invalid or expired token
GitBook Assistant

Regenerate a new Access Token
GitBook Assistant

403 Forbidden
GitBook Assistant

Token lacks required scopes
GitBook Assistant

Ensure group includes `readers`
GitBook Assistant

Connection failed
GitBook Assistant

Incorrect URL or SSL issue
GitBook Assistant

Verify URL and TLS certificate
GitBook Assistant

No findings visible
GitBook Assistant

Worker not active
GitBook Assistant

Check **Worker Group (Connector)** status
GitBook Assistant

[PreviousJFrog Artifactory Onboarding](/integrations/container-registries/jfrog-artifactory/jfrog-artifactory-onboarding)[NextAtlassian Ecosystem](/integrations/collaboration-and-saas/atlassian-ecosystem)

Last updated 2 months ago

- [Validation Steps After Connection](#validation-steps-after-connection)
- [API Scope Validation (Optional)](#api-scope-validation-optional)
- [Common Issues](#common-issues)
