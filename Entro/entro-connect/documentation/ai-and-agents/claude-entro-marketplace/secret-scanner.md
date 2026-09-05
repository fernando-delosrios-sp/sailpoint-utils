Secret Scanner | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/ai-and-agents/claude-entro-marketplace/secret-scanner.md).
## Purpose[#purpose](#purpose)

The SailPoint Claude Scanner plugin provides secret scanning functionality for prompts and Model Context Protocol (MCP) tool calls executed within the Claude Code CLI. The integration ensures capturing exposed secrets on those actions, and enables blocking said actions when a secret was detected.
GitBook Assistant
## What this integration is[#what-this-integration-is](#what-this-integration-is)

**The Entro Secret Scanner** scans prompts and MCP tool calls before sending them. If an exposed secret was detected, we log it and send the log to the Entro platform. **We have 2 versions of this plugin:**
GitBook Assistant

- 

One version blocks the submission of the prompt/tool execution in the event of an exposed secret.
GitBook Assistant
- 

The other one acts silently, and lets the action continue without interruption
GitBook Assistant

**Both log the event.**
GitBook Assistant
## Key capabilities[#key-capabilities](#key-capabilities)

- 

Secret Scanning: Scans prompts and tool calls for exposed secrets.
GitBook Assistant
- 

Exposure logging: Logs secret exposure events and sends them to Entro.
GitBook Assistant
- 

Leakage Blocking: Blocks the submission of the prompt, or the tool execution, in order to prevent leaking secrets.
GitBook Assistant

## Deployment model[#deployment-model](#deployment-model)

The plugin is installed locally via the Claude CLI or through the Claude Admin Console, and communicates outbound to Entro Control Plane using an authenticated token.
GitBook Assistant
## Installation[#installation](#installation)

Use [**Claude Plugin Installation**](/integrations/ai-and-agents/claude-entro-marketplace/plugin-installation) for the full flow (add the Entro marketplace, then install this plugin): [**local**](/integrations/ai-and-agents/claude-entro-marketplace/plugin-installation#local-setup) or [**organization**](/integrations/ai-and-agents/claude-entro-marketplace/plugin-installation#organization-setup).
GitBook Assistant
## High-level architecture[#high-level-architecture](#high-level-architecture)

## Demo[#demo](#demo)

Let's see how the Secret Scanner plugin helps us block secrets exposure and leakage. In this brief demo, we write a prompt with an exposed Github token. The plugin detected the exposure, blocked the submission of the prompt, and alerted the user. 
GitBook Assistant

The plugin sent the exposure event to the SailPoint (Entro) platform, and you can view it there. Log in into your SailPoint (Entro) account and navigate to "Exposed Inventory" under "Non-Human Identities". You can view the exposed secret:
GitBook Assistant
## Troubleshooting and validation[#troubleshooting-and-validation](#troubleshooting-and-validation)
1

**Run claude plugin list**
GitBook Assistant

Run the following command to list plugins:
GitBook Assistant

`claude plugin list`
GitBook Assistant2

**Write a prompt**
GitBook Assistant

Write a prompt with a dummy secret (not a real one!) to validate functionality.
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

Re-run init
GitBook Assistant

Auth error
GitBook Assistant

Token expired
GitBook Assistant

Regenerate token
GitBook Assistant
### Support[#support](#support)

Contact SailPoint Support via your Customer Success Manager or approved support channels.
GitBook Assistant
## Permissions reference[#permissions-reference](#permissions-reference)

### Summary[#summary](#summary)

The Claude Secret Scanner plugin operates with the minimum permissions required to intercept and log exposed secrets in prompts and MCP tool calls.
GitBook Assistant
### Data collected[#data-collected](#data-collected)

- 

Redacted exposed secret
GitBook Assistant
- 

Invocation timestamp
GitBook Assistant
- 

IP Address
GitBook Assistant
- 

Host name
GitBook Assistant
- 

Agent name (Claude)
GitBook Assistant
- 

Claude executable path
GitBook Assistant
- 

Claude account email, or system username if not available
GitBook Assistant

### Security controls[#security-controls](#security-controls)

- 

Token-based authentication (AES-256)
GitBook Assistant
- 

TLS 1.2+ encrypted transport
GitBook Assistant
- 

Stateless processing with no local secret storage
GitBook Assistant
[PreviousGovernance Audit Plugin](/integrations/ai-and-agents/claude-entro-marketplace/mcp-audit)[NextCursor SailPoint Marketplace](/integrations/ai-and-agents/cursor-entro-marketplace)

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
|  Claude Code CLI    |           |     Entro Console      |
|  (Local Environment)|           |    (Control Plane)     |
+---------+-----------+           +-----------+------------+
          |                                   ^
          |        Exposed Secret Log         |
          +-----------------------------------+
                   (Auth: SailPoint (Entro) Token)
```
