INSTALL | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/gemini-instructions/install.md).

This guide explains how to configure Gemini CLI with the Entro MCP Audit Server.
GitBook Assistant
## Prerequisites[#prerequisites](#prerequisites)
1
#### Node.js 18+[#node.js-18](#node.js-18)

Check your Node version:
GitBook AssistantGitBook AssistantAskCopy
```
node --version
```

Download: https://nodejs.org/
GitBook Assistant2
#### Gemini CLI[#gemini-cli](#gemini-cli)

Install globally:
GitBook AssistantGitBook AssistantAskCopy
```
npm install -g @google/gemini-cli
```
3
#### Your Entro Auth Token[#your-entro-auth-token](#your-entro-auth-token)

A 64-character hex string provided by your Entro contact.
GitBook Assistant

Example format: `a1b2c3d4e5f6...` (64 characters)
GitBook Assistant
## Installation[#installation](#installation)

### Mac / Linux[#mac-linux](#mac-linux)

Open Terminal and navigate to this folder, then run:
GitBook AssistantGitBook AssistantAskCopy
```
chmod +x setup.sh
./setup.sh
```

### Windows[#windows](#windows)

Open PowerShell and navigate to this folder, then run:
GitBook AssistantGitBook AssistantAskCopy
```
# Allow script execution (one-time, if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run the script
.\setup.ps1
```

If you get a script execution error, run with bypass:
GitBook Assistant
## What the Setup Script Does[#what-the-setup-script-does](#what-the-setup-script-does)
StepDescription

1
GitBook Assistant

✅ Verify Gemini CLI is installed
GitBook Assistant

2
GitBook Assistant

✅ Detect your system info (hostname, username, Gemini path)
GitBook Assistant

3
GitBook Assistant

✅ Prompt for your Entro auth token
GitBook Assistant

4
GitBook Assistant

✅ Validate token format (64-character hex)
GitBook Assistant

5
GitBook Assistant

✅ Backup existing config files (if any)
GitBook Assistant

6
GitBook Assistant

✅ Create/update `~/.gemini/settings.json`
GitBook Assistant

7
GitBook Assistant

✅ Create/update `~/.gemini/GEMINI.md` with audit instructions
GitBook Assistant
### Files Created/Modified[#files-created-modified](#files-created-modified)
FilePurpose

`~/.gemini/settings.json`
GitBook Assistant

MCP server configuration with your auth token
GitBook Assistant

`~/.gemini/GEMINI.md`
GitBook Assistant

Instructions for Gemini to audit MCP calls
GitBook Assistant
### Backups[#backups](#backups)

If existing files are found, they are backed up with a timestamp:
GitBook Assistant

- 

`settings.json.backup.20260120_143022`
GitBook Assistant
- 

`GEMINI.md.backup.20260120_143022`
GitBook Assistant

## Example Output[#example-output](#example-output)

## Verify Installation[#verify-installation](#verify-installation)
1
#### 1. Check settings.json[#id-1.-check-settings.json](#id-1.-check-settings.json)

Expected output:
GitBook Assistant2
#### 2. Check GEMINI.md[#id-2.-check-gemini.md](#id-2.-check-gemini.md)

Should show audit instructions with your hardcoded system info.
GitBook Assistant3
#### 3. Test Gemini[#id-3.-test-gemini](#id-3.-test-gemini)

Run:
GitBook Assistant

Then ask Gemini to make a remote MCP call (if you have remote MCP servers configured, like GitHub):
GitBook Assistant

Verify that:
GitBook Assistant

- 

`audit_request` is called before the tool
GitBook Assistant
- 

`audit_complete` is called after the tool
GitBook Assistant

Note: Only remote MCP servers (configured with `httpUrl`) are audited. Local MCP servers (configured with `command`, like `filesystem`) are NOT audited.
GitBook Assistant
## Troubleshooting[#troubleshooting](#troubleshooting)

### "Gemini CLI not found"[#gemini-cli-not-found](#gemini-cli-not-found)

Install Gemini CLI:
GitBook Assistant

If npm is not found, install Node.js first: https://nodejs.org/
GitBook Assistant
### "Invalid token format"[#invalid-token-format](#invalid-token-format)

Your token must be exactly 64 hexadecimal characters (0-9, a-f).
GitBook Assistant

Example valid token:
GitBook Assistant
### "Permission denied" (Mac/Linux)[#permission-denied-mac-linux](#permission-denied-mac-linux)

Make the script executable:
GitBook Assistant
### "Script execution disabled" (Windows)[#script-execution-disabled-windows](#script-execution-disabled-windows)

Allow script execution:
GitBook Assistant

Or run with bypass:
GitBook Assistant
### Gemini not loading GEMINI.md instructions[#gemini-not-loading-gemini.md-instructions](#gemini-not-loading-gemini.md-instructions)

1. 

Verify the file exists:
GitBook Assistant

1. 

Verify `settings.json` has the context configuration:
GitBook Assistant

1. 

Restart Gemini CLI
GitBook Assistant

## Uninstall[#uninstall](#uninstall)

### Mac / Linux[#mac-linux-1](#mac-linux-1)

### Windows (PowerShell)[#windows-powershell](#windows-powershell)

## Support[#support](#support)

For issues or questions, contact your Entro representative.
GitBook Assistant

Last updated 4 months ago

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Mac / Linux](#mac-linux)
- [Windows](#windows)
- [What the Setup Script Does](#what-the-setup-script-does)
- [Files Created/Modified](#files-created-modified)
- [Backups](#backups)
- [Example Output](#example-output)
- [Verify Installation](#verify-installation)
- [Troubleshooting](#troubleshooting)
- ["Gemini CLI not found"](#gemini-cli-not-found)
- ["Invalid token format"](#invalid-token-format)
- ["Permission denied" (Mac/Linux)](#permission-denied-mac-linux)
- ["Script execution disabled" (Windows)](#script-execution-disabled-windows)
- [Gemini not loading GEMINI.md instructions](#gemini-not-loading-gemini.md-instructions)
- [Uninstall](#uninstall)
- [Mac / Linux](#mac-linux-1)
- [Windows (PowerShell)](#windows-powershell)
- [Support](#support)
GitBook AssistantAskCopy
```
powershell -ExecutionPolicy Bypass -File setup.ps1
```
GitBook AssistantAskCopy
```
╔══════════════════════════════════════════════════════════════════════╗
║          Entro MCP Audit Server - Gemini Setup                       ║
╚══════════════════════════════════════════════════════════════════════╝

Checking for Gemini CLI...
✓ Gemini CLI found at: /opt/homebrew/bin/gemini

Detecting system information...
✓ Hostname: johns-macbook-pro
✓ Username: john
✓ Gemini Path: /opt/homebrew/bin/gemini

Enter your Entro MCP authentication token:
(This is the 64-character token provided by your organization)

Auth Token: ********************************
✓ Token format validated

Creating new settings.json...
✓ Settings configured successfully

Updating Gemini instructions...
✓ GEMINI.md updated at: /Users/john/.gemini/GEMINI.md

╔══════════════════════════════════════════════════════════════════════╗
║                    Setup Complete!                                    ║
╚══════════════════════════════════════════════════════════════════════╝

Configuration:
  Settings file:    /Users/john/.gemini/settings.json
  Instructions:     /Users/john/.gemini/GEMINI.md
  MCP Server:       https://mcp.entro.security/mcp

Detected System Info (hardcoded in instructions):
  Gemini Path:      /opt/homebrew/bin/gemini
  Hostname:         johns-macbook-pro
  Username:         john

Next steps:
  1. Run 'gemini' in any project directory
  2. MCP tool calls will be automatically audited
```
GitBook AssistantAskCopy
```
cat ~/.gemini/settings.json
```
GitBook AssistantAskCopy
```
{
  "mcpServers": {
    "entro": {
      "httpUrl": "https://mcp.entro.security/mcp",
      "headers": {
        "Authorization": "Bearer your-token-here..."
      },
      "trust": true
    }
  },
  "context": {
    "fileName": ["GEMINI.md"]
  }
}
```
GitBook AssistantAskCopy
```
head -20 ~/.gemini/GEMINI.md
```
GitBook AssistantAskCopy
```
gemini
```
GitBook AssistantAskCopy
```
> List my GitHub issues
```
GitBook AssistantAskCopy
```
npm install -g @google/gemini-cli
```
GitBook AssistantAskCopy
```
a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2
```
GitBook AssistantAskCopy
```
chmod +x setup.sh
```
GitBook AssistantAskCopy
```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
GitBook AssistantAskCopy
```
powershell -ExecutionPolicy Bypass -File setup.ps1
```
GitBook AssistantAskCopy
```
ls -la ~/.gemini/GEMINI.md
```
GitBook AssistantAskCopy
```
"context": {
  "fileName": ["GEMINI.md"]
}
```
GitBook AssistantAskCopy
```
rm ~/.gemini/settings.json
rm ~/.gemini/GEMINI.md
```
GitBook AssistantAskCopy
```
Remove-Item "$env:USERPROFILE\.gemini\settings.json"
Remove-Item "$env:USERPROFILE\.gemini\GEMINI.md"
```
