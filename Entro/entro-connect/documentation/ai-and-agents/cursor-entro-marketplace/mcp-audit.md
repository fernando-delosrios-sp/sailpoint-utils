Governance Audit Plugin | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/ai-and-agents/cursor-entro-marketplace/mcp-audit.md).
## Purpose[#purpose](#purpose)

The Entro Cursor Governance Audit plugin provides automatic audit logging for Model Context Protocol (MCP) tool calls executed within Cursor. It captures agent interactions with external tools and gives security teams a verifiable audit trail.
GitBook Assistant
## What this integration is[#what-this-integration-is](#what-this-integration-is)

**The Entro Governance Audit plugin** passively intercepts MCP tool calls and forwards audit metadata to Entro.
GitBook Assistant

No code execution is modified. No tool output is changed.
GitBook Assistant
## Key capabilities[#key-capabilities](#key-capabilities)

- 

Policy compliance: Enforce policies for agentic AI activity.
GitBook Assistant
- 

Automatic audit logging: Capture remote MCP tool calls.
GitBook Assistant
- 

Agentic visibility: Show how AI tools interact with external services.
GitBook Assistant
- 

Security and compliance: Support governance requirements for AI workflows.
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

In this example, Cursor triggers an MCP call to create a Jira ticket. The plugin detects the call and audits it.
GitBook Assistant

The audit log is sent to Entro. You can review it in **AI Agents** → **AI Agents Inventory**.
GitBook Assistant
## Troubleshooting and validation[#troubleshooting-and-validation](#troubleshooting-and-validation)
1

**Check the plugin is installed**
GitBook Assistant

Open Cursor settings and confirm the plugin is available.
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

Re-run install
GitBook Assistant

Auth error
GitBook Assistant

Token expired
GitBook Assistant

Regenerate token
GitBook Assistant
### Support[#support](#support)

Contact Entro Support through your Customer Success Manager or approved support channels.
GitBook Assistant
## Permissions reference[#permissions-reference](#permissions-reference)

### Summary[#summary](#summary)

The Cursor Governance Audit plugin uses the minimum access required to intercept and log MCP tool call metadata.
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

Cursor account email
GitBook Assistant
- 

Used identity — masked auth token, `"oauth"`, or `"local-process"`
GitBook Assistant
- 

User prompt
GitBook Assistant
- 

MCP server name
GitBook Assistant
- 

MCP server type
GitBook Assistant
- 

MCP server address for remote servers
GitBook Assistant
- 

MCP server command for local servers
GitBook Assistant
- 

MCP server environment variables for local servers
GitBook Assistant
- 

Tool call result
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
[PreviousCursor Plugin Installation](/integrations/ai-and-agents/cursor-entro-marketplace/marketplace-onboarding-user-scope)[NextSecret Scanner](/integrations/ai-and-agents/cursor-entro-marketplace/secret-scanner)

Last updated 2 months ago

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
          |        Audit Log Metadata         |
          +-----------------------------------+
                   (Auth: Entro Token)
```
