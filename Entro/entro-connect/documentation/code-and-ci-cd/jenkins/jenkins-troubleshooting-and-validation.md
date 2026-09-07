Jenkins Troubleshooting And Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/jenkins/jenkins-troubleshooting-and-validation.md).

This section provides procedures to validate your Jenkins integration and resolve common issues.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

Management → Accounts & Integrations → Jenkins → Troubleshooting and Validation
GitBook Assistant
## Validation Steps[#validation-steps](#validation-steps)
1
#### In the Entro Dashboard[#in-the-entro-dashboard](#in-the-entro-dashboard)

Navigate to Management → Accounts & Integrations → Jenkins.
GitBook Assistant2
#### Confirm connection status[#confirm-connection-status](#confirm-connection-status)

Confirm that the connection status displays **Verified**.
GitBook Assistant3
#### Check last synchronization[#check-last-synchronization](#check-last-synchronization)

Check that the **Last Verified Timestamp** is recent.
GitBook Assistant4
#### Verify findings[#verify-findings](#verify-findings)

Verify that Jenkins metadata and findings appear under **Findings → Inventory**. dort by "Detection time" to view recent results.
GitBook Assistant
## API Scope Validation (Optional)[#api-scope-validation-optional](#api-scope-validation-optional)

Use curl to confirm token permissions:
GitBook AssistantCheck repositories with tokenGitBook AssistantAskCopy
```
curl -u <USER_ID>:<API_TOKEN> <JENKINS_URL>/api/json
```

Expected response: JSON list of repositories. If unauthorized, check group scope.
GitBook Assistant
## Common Issues[#common-issues](#common-issues)
IssueCauseResolution

401 Unauthorized
GitBook Assistant

Invalid or expired token
GitBook Assistant

Generate a new token and update integration
GitBook Assistant

403 Forbidden
GitBook Assistant

Token lacks required permissions
GitBook Assistant

Grant **Overall/Read** and **Job/Read** to the service user
GitBook Assistant

Connection timeout
GitBook Assistant

Network restrictions or invalid URL
GitBook Assistant

Verify the Jenkins URL and ensure HTTPS access
GitBook Assistant

No findings visible
GitBook Assistant

Worker not active
GitBook Assistant

Check **Worker Group (Connector)** status
GitBook Assistant
## [#undefined](#undefined)
[PreviousJenkins Onboarding](/integrations/code-and-ci-cd/jenkins/jenkins-onboarding)[NextBuildkite](/integrations/code-and-ci-cd/buildkite)

Last updated 2 months ago

- [Navigation Path](#navigation-path)
- [Validation Steps](#validation-steps)
- [API Scope Validation (Optional)](#api-scope-validation-optional)
- [Common Issues](#common-issues)
- [#undefined](#undefined)
