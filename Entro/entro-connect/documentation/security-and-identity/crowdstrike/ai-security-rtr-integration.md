AI Security RTR Integration | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/crowdstrike/ai-security-rtr-integration.md).
## Overview[#overview](#overview)

The Entro CrowdStrike Real-Time Response (RTR) integration allows Entro to **securely inspect configuration files on endpoints** in order to discover and protect credentials and MCP-related configurations stored on developer machines.
GitBook Assistant

When the integration runs, Entro:
GitBook Assistant

1. 

Opens a temporary **CrowdStrike RTR session**
GitBook Assistant
1. 

Locates directories where MCP and developer tools store configuration files
GitBook Assistant
1. 

Reads relevant configuration files
GitBook Assistant

All commands are executed using **CrowdStrike’s RTR capability via the Falcon agent already installed on the endpoint**.
GitBook Assistant

Importantly, the integration is executed **from the Entro Connector**, which can be deployed within the customer's environment and controlled by the customer.
GitBook Assistant

No persistent scripts, agents, or binaries are installed on endpoints.
GitBook Assistant
## Where Execution Happens[#where-execution-happens](#where-execution-happens)

All RTR commands originate from the **Entro Connector**, which is deployed and managed by the customer.
GitBook AssistantGitBook AssistantAskCopy
```
Customer Environment
│
├─ Entro Connector
│    └─ Calls CrowdStrike RTR API
│
├─ CrowdStrike Falcon Cloud
│    └─ Executes commands through Falcon Agent
│
└─ Endpoint
     └─ Read-only commands executed
        └─ LS, CAT commands only  
```

This architecture ensures that:
GitBook Assistant

- 

Customers **fully control where the integration runs**
GitBook Assistant
- 

All communication is performed using **CrowdStrike’s native RTR API**
GitBook Assistant
- 

No direct inbound connectivity to endpoints is required
GitBook Assistant

## What Commands Run on Endpoints[#what-commands-run-on-endpoints](#what-commands-run-on-endpoints)

The integration performs three types of operations:
GitBook Assistant

1. 

**Open an RTR session**
GitBook Assistant
1. 

**Enumerate directories to locate MCP configuration files**
GitBook Assistant
1. 

**Read configuration file contents**
GitBook Assistant

All commands are **read-only**.
GitBook Assistant
## 1. RTR Session Initialization[#id-1.-rtr-session-initialization](#id-1.-rtr-session-initialization)

Before executing commands, Entro creates a temporary RTR session with the endpoint.
GitBook Assistant
#### Session Payload[#session-payload](#session-payload)

Purpose:
GitBook Assistant

- 

Establish temporary RTR access
GitBook Assistant
- 

Ensure commands only run on **online endpoints**
GitBook Assistant

## 2. Directory Enumeration[#id-2.-directory-enumeration](#id-2.-directory-enumeration)

Entro inspects known directories where MCP tools and developer environments typically store configuration files.
GitBook Assistant
#### macOS / Linux[#macos-linux](#macos-linux)

The Falcon agent executes:
GitBook Assistant

and
GitBook Assistant

Purpose:
GitBook Assistant

- 

Enumerate configuration directories
GitBook Assistant
- 

Identify MCP configuration files or related developer tool configs
GitBook Assistant

#### Windows[#windows](#windows)

The Falcon agent executes:
GitBook Assistant

and
GitBook Assistant

Purpose:
GitBook Assistant

- 

Discover configuration directories used by developer tools
GitBook Assistant

## 3. Configuration File Retrieval[#id-3.-configuration-file-retrieval](#id-3.-configuration-file-retrieval)

After identifying potential configuration files, Entro retrieves the file contents.
GitBook Assistant
#### macOS / Linux[#macos-linux-1](#macos-linux-1)

Example command executed:
GitBook Assistant

Additional example:
GitBook Assistant
#### Windows[#windows-1](#windows-1)

Example command executed:
GitBook Assistant

Additional example:
GitBook Assistant

Purpose:
GitBook Assistant

- 

Retrieve configuration content to identify credentials, tokens, or MCP server definitions.
GitBook Assistant

## Configuration Files That May Be Retrieved[#configuration-files-that-may-be-retrieved](#configuration-files-that-may-be-retrieved)

Entro looks for commonly used MCP and developer configuration files:
GitBook Assistant

These files may contain:
GitBook Assistant

- 

MCP server configurations
GitBook Assistant
- 

OAuth tokens
GitBook Assistant
- 

API credentials
GitBook Assistant
- 

Agent definitions
GitBook Assistant
- 

Developer environment settings
GitBook Assistant

## End-to-End Flow[#end-to-end-flow](#end-to-end-flow)

The following diagram shows the full interaction between Entro, CrowdStrike, and the endpoint.
GitBook Assistant
## Security Characteristics[#security-characteristics](#security-characteristics)

The integration was designed with strict security controls.
GitBook Assistant
#### Customer-Controlled Execution[#customer-controlled-execution](#customer-controlled-execution)

All commands originate from the **Entro Connector**, which is:
GitBook Assistant

- 

Could be deployed **within the customer environment**
GitBook Assistant
- 

Fully **controlled by the customer**
GitBook Assistant
- 

Able to be **restricted or disabled by the customer**
GitBook Assistant

No external system directly accesses endpoints.
GitBook Assistant
#### Read-Only Operations[#read-only-operations](#read-only-operations)

Commands executed on endpoints are limited to:
GitBook Assistant

- 

Directory listing (`ls`)
GitBook Assistant
- 

File reading (`cat`)
GitBook Assistant

No files are modified.
GitBook Assistant
#### No Persistence[#no-persistence](#no-persistence)

The integration does **not install scripts, agents, or binaries** on endpoints.
GitBook Assistant
#### Temporary Sessions[#temporary-sessions](#temporary-sessions)

CrowdStrike RTR sessions are **temporary and closed after execution**.
GitBook Assistant
#### IP Allowlisting[#ip-allowlisting](#ip-allowlisting)

CrowdStrike supports **IP allowlisting for API clients**, meaning authentication and API requests will only succeed when originating from an approved source IP.
GitBook Assistant
#### Native CrowdStrike Execution[#native-crowdstrike-execution](#native-crowdstrike-execution)

All commands are executed via the **CrowdStrike Falcon agent**, ensuring they respect:
GitBook Assistant

- 

Falcon policies
GitBook Assistant
- 

Endpoint security controls
GitBook Assistant
- 

Customer-managed CrowdStrike configurations
GitBook Assistant

## Why This Inspection Is Needed[#why-this-inspection-is-needed](#why-this-inspection-is-needed)

Modern developer tools and MCP environments frequently store credentials locally in configuration files.
GitBook Assistant

The Entro integration helps organizations:
GitBook Assistant

- 

Discover Shadow AI connections between AI Clients and enterprise services
GitBook Assistant

- 

Detect exposed API keys in AI Configuration files
GitBook Assistant
- 

Identify OAuth connections
GitBook Assistant
- 

Discover MCP server definitions
GitBook Assistant

- 

Reduce credential sprawl across developer machines
GitBook Assistant
[PreviousFalcon RTR Secrets Scanner](/integrations/security-and-identity/crowdstrike/falcon-rtr-secrets-scanner)[NextOkta](/integrations/security-and-identity/okta)

Last updated 4 months ago

- [Overview](#overview)
- [Where Execution Happens](#where-execution-happens)
- [What Commands Run on Endpoints](#what-commands-run-on-endpoints)
- [1. RTR Session Initialization](#id-1.-rtr-session-initialization)
- [2. Directory Enumeration](#id-2.-directory-enumeration)
- [3. Configuration File Retrieval](#id-3.-configuration-file-retrieval)
- [Configuration Files That May Be Retrieved](#configuration-files-that-may-be-retrieved)
- [End-to-End Flow](#end-to-end-flow)
- [Security Characteristics](#security-characteristics)
- [Why This Inspection Is Needed](#why-this-inspection-is-needed)
GitBook AssistantAskCopy
```
{
  "device_id": "<endpoint_device_id>",
  "origin": "entro-mcp-scan",
  "queue_offline": false
}
```
GitBook AssistantAskCopy
```
run ls -l -t ~/.config
```
GitBook AssistantAskCopy
```
run ls -l -t ~/.config/claude
```
GitBook AssistantAskCopy
```
ls C:\Users\<user>\AppData\Roaming
```
GitBook AssistantAskCopy
```
ls C:\Users\<user>\AppData\Roaming\Claude
```
GitBook AssistantAskCopy
```
run cat ~/.config/claude/claude_desktop_config.json
```
GitBook AssistantAskCopy
```
run cat ~/.config/mcp/config.json
```
GitBook AssistantAskCopy
```
cat C:\Users\<user>\AppData\Roaming\Claude\claude_desktop_config.json
```
GitBook AssistantAskCopy
```
cat C:\Users\<user>\AppData\Roaming\mcp\config.json
```
GitBook AssistantAskCopy
```
mcp.json
mcp_config.json
config.json
settings.json
claude_desktop_config.json
default.json
mcp-oauth-tokens.json
cli-agents
```
