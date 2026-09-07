Buildkite Troubleshooting And Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/buildkite/buildkite-troubleshooting-and-validation.md).

This section provides guidance to validate and troubleshoot your Buildkite integration with Entro Security.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

Management → Accounts & Integrations → Buildkite → Troubleshooting and Validation
GitBook Assistant
## Validation Steps[#validation-steps](#validation-steps)
1
#### Open Buildkite integration[#open-buildkite-integration](#open-buildkite-integration)

In the Entro Dashboard, go to **Management → Accounts & Integrations → Buildkite**.
GitBook Assistant2
#### Confirm connection[#confirm-connection](#confirm-connection)

Confirm the connection status shows **Verified**.
GitBook Assistant3
#### Check synchronization timestamp[#check-synchronization-timestamp](#check-synchronization-timestamp)

Check that **Last Synchronization Timestamp** is recent.
GitBook Assistant4
#### Validate pipeline and build data[#validate-pipeline-and-build-data](#validate-pipeline-and-build-data)

Validate that pipeline and build data appear in **Findings → Inventory**.
GitBook Assistant5
#### Review connector logs[#review-connector-logs](#review-connector-logs)

Review connector logs under **Worker Group (Connector)** for successful sync entries.
GitBook Assistant
## Command-Line Verification (Optional)[#command-line-verification-optional](#command-line-verification-optional)

You can test token validity directly using the Buildkite API.
GitBook AssistantVerify token with Buildkite APIGitBook AssistantAskCopy
```
curl -H "Authorization: <redacted> https://api.buildkite.com/v2/user
```

Expected Output: A JSON object with user and organization metadata, confirming API access.
GitBook Assistant
## Common Issues and Resolutions[#common-issues-and-resolutions](#common-issues-and-resolutions)
IssuePossible CauseResolution

Token rejected
GitBook Assistant

Incorrect or expired token
GitBook Assistant

Generate a new token and re-enter in Entro
GitBook Assistant

“Permission denied”
GitBook Assistant

Insufficient read scopes
GitBook Assistant

Ensure token includes all required read scopes
GitBook Assistant

No data visible in Entro
GitBook Assistant

Network restrictions
GitBook Assistant

Verify outbound HTTPS access to app.entro.security
GitBook Assistant

Sync delay
GitBook Assistant

API throttling
GitBook Assistant

Allow scheduled retry or reduce concurrent requests
GitBook Assistant
## Advanced Diagnostics[#advanced-diagnostics](#advanced-diagnostics)
Click to expand advanced diagnostics[#click-to-expand-advanced-diagnostics](#click-to-expand-advanced-diagnostics)

- 

Check Entro Worker logs for Buildkite sync events and error codes
GitBook Assistant
- 

Validate token activity in Buildkite’s **API Access Token Settings**
GitBook Assistant
- 

Ensure **TLS certificates** are valid for outbound HTTPS requests
GitBook Assistant

## Security & Compliance Notes[#security-and-compliance-notes](#security-and-compliance-notes)
Click to expand security & compliance details[#click-to-expand-security-and-compliance-details](#click-to-expand-security-and-compliance-details)

- 

All Buildkite integrations operate under **read-only** access
GitBook Assistant
- 

Tokens and credentials are encrypted using **AES-256**
GitBook Assistant
- 

All communications occur over **TLS 1.2+**
GitBook Assistant
- 

Integration complies with **SOC 2 Type II**, **ISO 27001**, and **GDPR** frameworks
GitBook Assistant

Last updated 4 months ago

- [Navigation Path](#navigation-path)
- [Validation Steps](#validation-steps)
- [Command-Line Verification (Optional)](#command-line-verification-optional)
- [Common Issues and Resolutions](#common-issues-and-resolutions)
- [Advanced Diagnostics](#advanced-diagnostics)
- [Security & Compliance Notes](#security-and-compliance-notes)
