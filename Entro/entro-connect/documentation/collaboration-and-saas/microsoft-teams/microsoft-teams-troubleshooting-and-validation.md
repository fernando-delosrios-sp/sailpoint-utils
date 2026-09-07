Microsoft Teams Troubleshooting And Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/microsoft-teams/microsoft-teams-troubleshooting-and-validation.md).

Use the following steps to validate and troubleshoot your Microsoft Teams integration with Entro.
GitBook Assistant
## Validation Steps[#validation-steps](#validation-steps)
1
#### Navigate to the Microsoft Teams integration[#navigate-to-the-microsoft-teams-integration](#navigate-to-the-microsoft-teams-integration)

Go to Management → Accounts & Integrations → Microsoft Teams in the Entro Dashboard.
GitBook Assistant2
#### Confirm connection status[#confirm-connection-status](#confirm-connection-status)

Ensure the connection status displays Verified.
GitBook Assistant3
#### Validate Azure permissions[#validate-azure-permissions](#validate-azure-permissions)

Check that Teams permissions in Azure show green checks under Admin Consent.
GitBook Assistant4
#### Confirm Entro Bot presence[#confirm-entro-bot-presence](#confirm-entro-bot-presence)

Verify the Entro Bot appears under Teams Admin Center → Manage Apps → Entro Security.
GitBook Assistant5
#### Verify alerts and messages[#verify-alerts-and-messages](#verify-alerts-and-messages)

Ensure alerts and messages are visible in the designated Teams channels.
GitBook Assistant
## Common Issues & Resolutions[#common-issues-and-resolutions](#common-issues-and-resolutions)
IssuePossible CauseResolution

Token validation fails
GitBook Assistant

Missing or expired Client Secret
GitBook Assistant

Regenerate secret in Azure and update Entro configuration
GitBook Assistant

Bot not appearing in Teams
GitBook Assistant

App not uploaded or incorrect manifest
GitBook Assistant

Re-upload the Entro Bot and ensure App ID matches onboarding form
GitBook Assistant

Missing permissions
GitBook Assistant

Consent not granted
GitBook Assistant

Return to API Permissions → Grant admin consent
GitBook Assistant

Messages not received
GitBook Assistant

Bot not assigned to global policy
GitBook Assistant

Add Entro Security under *Setup Policies → Global (Org-wide default)*
GitBook Assistant
## Security & Compliance[#security-and-compliance](#security-and-compliance)

- 

Read-only access validation
GitBook Assistant
- 

TLS 1.2+ enforced
GitBook Assistant
- 

Tokens encrypted at rest (AES-256)
GitBook Assistant
- 

Fully compliant with SOC 2 Type II, ISO 27001, and GDPR
GitBook Assistant

Last updated 4 months ago

- [Validation Steps](#validation-steps)
- [Common Issues & Resolutions](#common-issues-and-resolutions)
- [Security & Compliance](#security-and-compliance)
