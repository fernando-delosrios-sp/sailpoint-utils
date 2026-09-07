Secret Scanner | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/ai-and-agents/cursor-entro-marketplace-1/secret-scanner.md).
## Purpose[#purpose](#purpose)

The SailPoint VS Code Secret Scanner plugin scans prompts and Model Context Protocol (MCP) tool calls executed from GitHub Copilot in Visual Studio Code. It detects exposed secrets before they are sent and can block the action when policy requires it.
GitBook Assistant
## What this integration is[#what-this-integration-is](#what-this-integration-is)

**The SailPoint Secret Scanner** scans prompts and MCP tool calls before sending them. If it detects an exposed secret, it logs the event and sends it to SailPoint.
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

Install the plugin from the SailPoint marketplace in VS Code for an individual user, or recommend it in a shared workspace. The plugin communicates outbound to the SailPoint Control Plane using an authenticated token.
GitBook Assistant
## Installation[#installation](#installation)

Use [**VS Code Plugin Installation**](/integrations/ai-and-agents/cursor-entro-marketplace-1/marketplace-onboarding-user-scope) for the full flow:
GitBook Assistant

- 

[User setup](/integrations/ai-and-agents/cursor-entro-marketplace-1/marketplace-onboarding-user-scope#user-setup)
GitBook Assistant
- 

[Workspace setup](/integrations/ai-and-agents/cursor-entro-marketplace-1/marketplace-onboarding-user-scope#workspace-setup)
GitBook Assistant

## High-level architecture[#high-level-architecture](#high-level-architecture)

## Troubleshooting and validation[#troubleshooting-and-validation](#troubleshooting-and-validation)
1

**Check the plugin is installed**
GitBook Assistant

Open the GitHub Copilot plugin list in VS Code and confirm `secret-scanner@sailpoint` or `secret-scanner-non-blocking@sailpoint` is installed for your user.
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

Plugin not installed
GitBook Assistant

Install the plugin
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

The VS Code Secret Scanner plugin uses the minimum access required to intercept and log exposed secrets in prompts and MCP tool calls.
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

VS Code executable path
GitBook Assistant
- 

Signed-in account email, or system username if unavailable
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
[PreviousGovernance Audit Plugin](/integrations/ai-and-agents/cursor-entro-marketplace-1/mcp-audit)[NextSailPoint WebGuard](/integrations/ai-and-agents/entro-webguard)

Last updated 1 month ago

- [Purpose](#purpose)
- [What this integration is](#what-this-integration-is)
- [Key capabilities](#key-capabilities)
- [Deployment model](#deployment-model)
- [Installation](#installation)
- [High-level architecture](#high-level-architecture)
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
|   VS Code + Copilot |           |   SailPoint Console    |
|  (Local Environment)|           |    (Control Plane)     |
+---------+-----------+           +-----------+------------+
          |                                   ^
          |        Exposed Secret Log         |
          +-----------------------------------+
                 (Auth: SailPoint (Entro) Token)
```
