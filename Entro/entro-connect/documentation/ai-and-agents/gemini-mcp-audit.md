Gemini MCP Audit | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/ai-and-agents/gemini-mcp-audit.md).
## Purpose[#purpose](#purpose)

The Entro Gemini MCP Audit integration provides automatic audit logging for **remote Model Context Protocol (MCP) tool calls** executed within the Gemini CLI.
GitBook Assistant

This integration ensures that every interaction between the Gemini agent and external MCP tools is captured, providing visibility into agentic workflows and a verifiable audit trail for security, compliance, and governance teams.
GitBook Assistant
## What This Integration Is[#what-this-integration-is](#what-this-integration-is)

- 

**Gemini CLI** is a local developer command-line interface for running Gemini with tool access.
GitBook Assistant
- 

**MCP servers** expose tools that Gemini can invoke during agentic workflows.
GitBook Assistant
- 

**The Entro MCP Audit integration** enforces audit logging for remote MCP tool calls.
GitBook Assistant

No tool execution is modified. No tool output is altered.
GitBook Assistant
## Key Capabilities[#key-capabilities](#key-capabilities)

- 

Automatic Audit Logging
GitBook Assistant
- 

Agentic Visibility
GitBook Assistant
- 

Security & Compliance
GitBook Assistant

## Deployment Model[#deployment-model](#deployment-model)

Configured locally in the Gemini CLI and communicates outbound to the Entro Control Plane using an authenticated token.
GitBook Assistant
## High-Level Architecture[#high-level-architecture](#high-level-architecture)

Last updated 4 months ago

- [Purpose](#purpose)
- [What This Integration Is](#what-this-integration-is)
- [Key Capabilities](#key-capabilities)
- [Deployment Model](#deployment-model)
- [High-Level Architecture](#high-level-architecture)
GitBook AssistantAskCopy
```
Gemini CLI  --->  Entro MCP Audit Server  --->  Entro Console
```
