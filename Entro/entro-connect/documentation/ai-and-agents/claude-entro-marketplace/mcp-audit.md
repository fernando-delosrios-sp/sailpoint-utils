Governance Audit Plugin | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/ai-and-agents/claude-entro-marketplace/mcp-audit.md).
## Purpose[#purpose](#purpose)

The SailPoint Claude Governance Audit plugin provides automatic audit logging for Model Context Protocol (MCP) tool calls executed within the Claude Code CLI. The integration ensures every interaction between the Claude agent and external tools is captured, enabling visibility into agentic workflows and a verifiable audit trail.
GitBook Assistant
## What this integration is[#what-this-integration-is](#what-this-integration-is)

**The Entro Governance Audit plugin** passively intercepts MCP tool calls and forwards audit metadata to Entro.
GitBook Assistant

No code execution is modified. No tool output is changed. Every call is analyzed for intent, policy compliance and intercepted if needed.
GitBook Assistant
## Key capabilities[#key-capabilities](#key-capabilities)

- 

Policy compliance: Enforce policies to govern, secure and protect your enterprise services from agentic AI misuse, destructive actions and potential leakage.
GitBook Assistant
- 

Automatic Audit Logging: Captures all remote MCP tool calls.
GitBook Assistant
- 

Agentic Visibility: Provides security teams with insight into AI-driven tool usage.
GitBook Assistant
- 

Security & Compliance: Supports audit and governance requirements for agentic AI workflows.
GitBook Assistant

## Deployment model[#deployment-model](#deployment-model)

The plugin is installed [**locally** via the Claude CLI](/integrations/ai-and-agents/claude-entro-marketplace/mcp-audit#onboarding-user-scope) or [**organization wide** through the Claude Organization Settings](/integrations/ai-and-agents/claude-entro-marketplace/mcp-audit#onboarding-organization), and communicates outbound to Entro Control Plane using an **authenticated token** embedded in the plugin package, the token only associates the claude instance with it's organization id.
GitBook Assistant
## Installation[#installation](#installation)

Use [**Claude Plugin Installation**](/integrations/ai-and-agents/claude-entro-marketplace/plugin-installation) for the full flow (add the Entro marketplace, then install this plugin): [**local**](/integrations/ai-and-agents/claude-entro-marketplace/plugin-installation#local-setup) or [**organization**](/integrations/ai-and-agents/claude-entro-marketplace/plugin-installation#organization-setup).
GitBook Assistant
## High-level architecture[#high-level-architecture](#high-level-architecture)

## Demo[#demo](#demo)

Let's see how the MCP Audit plugin helps us get visibility on our Agentic AI's actions. In this brief demo, we write a prompt that triggers an MCP call - get my upcoming events on my Google Calendar. The plugin detected the MCP call, and audited it.
GitBook Assistant

The plugin sent the audit log to the SailPoint (Entro) platform, and you can view it there. Log in into your SailPoint (Entro) account and navigate to "AI Agents Inventory" under "AI Agents". You can view the audit log with additional context:
GitBook Assistant
## Troubleshooting and validation[#troubleshooting-and-validation](#troubleshooting-and-validation)
1

**Run claude plugin list**
GitBook Assistant

Run the following command to list plugins:
GitBook Assistant

`claude plugin list`
GitBook Assistant

or
GitBook Assistant

`/plugin`
GitBook Assistant2

**Execute a test MCP tool call**
GitBook Assistant

Perform a test MCP tool call to validate functionality.
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

The Claude MCP Audit plugin operates with the minimum permissions required to intercept and log MCP tool call metadata.
GitBook Assistant
### Data collected[#data-collected](#data-collected)

- 

Tool name
GitBook Assistant
- 

Invocation timestamp
GitBook Assistant
- 

Tool parameters
GitBook Assistant
- 

Host name
GitBook Assistant
- 

System username
GitBook Assistant
- 

Claude account email
GitBook Assistant
- 

Used identity - Masked auth token (e.g., `github_pat_11B******tobz`), `"oauth"`, or `"local-process"` in the case of a local MCP server tool call
GitBook Assistant
- 

User prompt
GitBook Assistant
- 

MCP server name
GitBook Assistant
- 

MCP server type - remote or local
GitBook Assistant
- 

MCP server address - in the case of a remote server
GitBook Assistant
- 

MCP server command - in the case of a local server
GitBook Assistant
- 

MCP server env vars - Env vars configured for local MCP servers
GitBook Assistant
- 

Tool call result
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
[PreviousClaude Plugin Installation](/integrations/ai-and-agents/claude-entro-marketplace/plugin-installation)[NextSecret Scanner](/integrations/ai-and-agents/claude-entro-marketplace/secret-scanner)

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
          |        Audit Log Metadata         |
          +-----------------------------------+
                   (Auth: SailPoint (Entro) Token)
```
