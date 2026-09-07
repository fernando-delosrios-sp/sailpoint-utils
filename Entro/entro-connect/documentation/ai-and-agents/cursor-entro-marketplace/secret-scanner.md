Secret Scanner | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/ai-and-agents/cursor-entro-marketplace/secret-scanner.md).
## Purpose[#purpose](#purpose)

The Entro Cursor Secret Scanner plugin scans prompts and Model Context Protocol (MCP) tool calls executed within Cursor. It detects exposed secrets before they are sent and can block the action when policy requires it.
GitBook Assistant
## What this integration is[#what-this-integration-is](#what-this-integration-is)

**The Entro Secret Scanner** scans prompts and MCP tool calls before sending them. If it detects an exposed secret, it logs the event and sends it to Entro.
GitBook Assistant

**Two plugin variants are available:**
GitBook Assistant

- 

`secret-scanner` blocks the action when a secret is detected.
GitBook Assistant
- 

`secret-scanner-non-blocking` logs the event and allows the action.
GitBook Assistant

Both variants log the event.
GitBook Assistant
## Key capabilities[#key-capabilities](#key-capabilities)

- 

Secret scanning: Scan prompts and tool calls for exposed secrets.
GitBook Assistant
- 

Exposure logging: Send exposure events to SailPoint.
GitBook Assistant
- 

Leakage blocking: Prevent prompt submission or tool execution when required.
GitBook Assistant

## Deployment model[#deployment-model](#deployment-model)

The plugin is installed locally in Cursor or required from the Cursor admin dashboard. It communicates outbound to the Entro Control Plane using an authenticated token.
GitBook Assistant
## Installation[#installation](#installation)

Use [**Cursor Plugin Installation**](/integrations/ai-and-agents/cursor-entro-marketplace/marketplace-onboarding-user-scope) for the full flow:
GitBook Assistant

- 

[Local setup](/integrations/ai-and-agents/cursor-entro-marketplace/marketplace-onboarding-user-scope#local-setup)
GitBook Assistant
- 

[Organization setup](/integrations/ai-and-agents/cursor-entro-marketplace/marketplace-onboarding-user-scope#organization-setup)
GitBook Assistant

## High-level architecture[#high-level-architecture](#high-level-architecture)

## Demo[#demo](#demo)

In this example, Cursor detects an exposed GitHub token in a prompt, blocks the submission, and alerts the user.
GitBook Assistant

The exposure event is sent to Entro. You can review it in **Non-Human Identities** → **Exposed Inventory**.
GitBook Assistant
## Troubleshooting and validation[#troubleshooting-and-validation](#troubleshooting-and-validation)
1

**Check the plugin is installed**
GitBook Assistant

Open Cursor settings and confirm `secret-scanner@sailpoint` or `secret-scanner-non-blocking@sailpoint` is available.
GitBook Assistant2

**Write a test prompt**
GitBook Assistant

Write a prompt with a dummy secret to validate functionality.
GitBook Assistant
### Common issues[#common-issues](#common-issues)
IssueCauseResolution

Marketplace add fails
GitBook Assistant

Invalid GitHub token
GitBook Assistant

Verify token
GitBook Assistant

Plugin not found
GitBook Assistant

Marketplace missing
GitBook Assistant

Re-add marketplace
GitBook Assistant

No logs
GitBook Assistant

Missing token
GitBook Assistant

Re-run install
GitBook Assistant

Auth error
GitBook Assistant

Token expired
GitBook Assistant

Regenerate token
GitBook Assistant
### Support[#support](#support)

Contact SailPoint Support through your Customer Success Manager or approved support channels.
GitBook Assistant
## Permissions reference[#permissions-reference](#permissions-reference)

### Summary[#summary](#summary)

The Cursor Secret Scanner plugin uses the minimum access required to intercept and log exposed secrets in prompts and MCP tool calls.
GitBook Assistant
### Data collected[#data-collected](#data-collected)

- 

Redacted exposed secret
GitBook Assistant
- 

Invocation timestamp
GitBook Assistant
- 

IP address
GitBook Assistant
- 

Host name
GitBook Assistant
- 

Agent name
GitBook Assistant
- 

Cursor executable path
GitBook Assistant
- 

Cursor account email, or system username if unavailable
GitBook Assistant

### Security controls[#security-controls](#security-controls)

- 

Token-based authentication
GitBook Assistant
- 

TLS 1.2+ encrypted transport
GitBook Assistant
- 

Stateless processing with no local secret storage
GitBook Assistant
[PreviousGovernance Audit Plugin](/integrations/ai-and-agents/cursor-entro-marketplace/mcp-audit)[NextVisual Studio Code SailPoint Marketplace](/integrations/ai-and-agents/cursor-entro-marketplace-1)

Last updated 1 month ago

- [Purpose](#purpose)
- [What this integration is](#what-this-integration-is)
- [Key capabilities](#key-capabilities)
- [Deployment model](#deployment-model)
- [Installation](#installation)
- [High-level architecture](#high-level-architecture)
- [Demo](#demo)
- [Troubleshooting and validation](#troubleshooting-and-validation)
- [Common issues](#common-issues)
- [Support](#support)
- [Permissions reference](#permissions-reference)
- [Summary](#summary)
- [Data collected](#data-collected)
- [Security controls](#security-controls)
GitBook AssistantAskCopy
```
+---------------------+           +------------------------+
|       Cursor        |           |     Entro Console      |
|  (Local Environment)|           |    (Control Plane)     |
+---------+-----------+           +-----------+------------+
          |                                   ^
          |        Exposed Secret Log         |
          +-----------------------------------+
                   (Auth: SailPoint (Entro) Token)
```
