Microsoft Teams | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/microsoft-teams.md).

Entro Security integrates with Microsoft Teams to detect exposed secrets, monitor sensitive message content, and enable secure alerting and messaging capabilities through the Entro Bot integration. This integration leverages Microsoft Graph API to provide continuous, read-only insights into Teams channels, chats, and app configurations - without modifying any content or metadata, along with an optional Write access to send messages via MS Teams.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

Management → Accounts & Integrations → Add New Account (top right) → Microsoft Ecosystem (Secrets Scanning)
GitBook Assistant

Management → Accounts & Integrations → Add New Account (top right) → Microsoft Teams (Messaging Risks)
GitBook Assistant
## Integration Capabilities[#integration-capabilities](#integration-capabilities)
FeatureStatus

Continuous detection of exposed secrets in Teams messages
GitBook Assistant

✅
GitBook Assistant

Read-only scanning across channels and group chats
GitBook Assistant

✅
GitBook Assistant

Manual or automated Message-based alerting via the Entro Bot
GitBook Assistant

✅
GitBook Assistant

Microsoft Teams NHI Management
GitBook Assistant

❌
GitBook Assistant
## Architecture Diagram[#architecture-diagram](#architecture-diagram)
GitBook AssistantAskCopy
```
Entro Security Cloud
   ↕ (HTTPS / TLS 1.2+)
Microsoft Graph API
   ↕ (Read-Only, Optional Write)
Microsoft Teams (Messages, Channels, Apps)
```

## Security & Compliance[#security-and-compliance](#security-and-compliance)

- 

Read-only access only
GitBook Assistant
- 

AES-256 encryption at rest
GitBook Assistant
- 

TLS 1.2+ for all communications
GitBook Assistant
- 

SOC 2 Type II, ISO 27001, GDPR compliant
GitBook Assistant
- 

Token-based access can be revoked at any time
GitBook Assistant
[PreviousGoogle Workspace GDrive Permissions Reference](/integrations/collaboration-and-saas/google-workspace-google-drive/google-workspace-gdrive-permissions-reference)[NextMicrosoft Teams Onboarding](/integrations/collaboration-and-saas/microsoft-teams/microsoft-teams-onboarding)

Last updated 2 months ago

- [Navigation Path](#navigation-path)
- [Integration Capabilities](#integration-capabilities)
- [Architecture Diagram](#architecture-diagram)
- [Security & Compliance](#security-and-compliance)
