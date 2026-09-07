Slack | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/slack.md).

Entro Security integrates with Slack to protect your organization from exposed secrets and secret-targeted attacks. Entro scans both **public and private channels**, providing real-time alerts with actionable context and mitigation steps.
GitBook Assistant
## Supported scope[#supported-scope](#supported-scope)

- 

Continuous scanning of Slack public and private channels.
GitBook Assistant
- 

Real-time alerts with full context and mitigation guidance.
GitBook Assistant
- 

Secure connection using Slack Socket Mode (no public webhook URLs).
GitBook Assistant
- 

Optional Enterprise Grid mode with Discovery API integration.
GitBook Assistant
- 

Ability to redact exposed secrets near real time using [slack prevention](https://docs.entro.security/administration/)
GitBook Assistant

## Integration Options[#integration-options](#integration-options)
MethodRecommended For

**Slack Private App**
GitBook Assistant

Standard Slack Workspaces
GitBook Assistant

**Slack Enterprise Grid App**
GitBook Assistant

Enterprise+ Grid Organizations
GitBook Assistant
## Architecture[#architecture](#architecture)
GitBook AssistantAskCopy
```
Entro Cloud (Scanner)
   ↕ (TLS 1.2+)
Worker Group (Connector)
   ↕ (Socket Mode)
Slack Workspace (Channels, DMs, Users)
```

## Data Access & Security[#data-access-and-security](#data-access-and-security)

- 

All operations are **read-only**.
GitBook Assistant
- 

Data encrypted with **AES‑256**.
GitBook Assistant
- 

Transport secured with **TLS 1.2+**.
GitBook Assistant
- 

SOC 2 Type II and ISO 27001 compliant.
GitBook Assistant
[PreviousServiceNow Permissions Reference](/integrations/collaboration-and-saas/servicenow/servicenow-permissions-reference)[NextSlack Private App Onboarding](/integrations/collaboration-and-saas/slack/slack-onboarding)

Last updated 2 months ago

- [Supported scope](#supported-scope)
- [Integration Options](#integration-options)
- [Architecture](#architecture)
- [Data Access & Security](#data-access-and-security)
