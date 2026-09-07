Gemini MCP Audit Troubleshooting And Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/ai-and-agents/gemini-mcp-audit/gemini-mcp-audit-troubleshooting-and-validation.md).
## Validation Checklist[#validation-checklist](#validation-checklist)
1
#### Run gemini --version[#run-gemini-version](#run-gemini-version)

Run the following command to verify the CLI is installed and the version:
GitBook AssistantGitBook AssistantAskCopy
```
gemini --version
```
2
#### Check ~/.gemini/settings.json[#check-.gemini-settings.json](#check-.gemini-settings.json)

Inspect the settings file located at:
GitBook Assistant

- 

`~/.gemini/settings.json`
GitBook Assistant
3
#### Start Gemini CLI[#start-gemini-cli](#start-gemini-cli)

Start the Gemini CLI and ensure it launches without errors.
GitBook Assistant4
#### Execute a remote MCP tool call[#execute-a-remote-mcp-tool-call](#execute-a-remote-mcp-tool-call)

Perform a remote MCP tool call using the CLI to validate connectivity and functionality.
GitBook Assistant5
#### Verify logs in Entro Console[#verify-logs-in-entro-console](#verify-logs-in-entro-console)

Confirm that audit and operation logs for the MCP calls appear in the Entro Console.
GitBook Assistant
## Common Issues[#common-issues](#common-issues)
IssueCauseResolution

CLI not found
GitBook Assistant

Not installed
GitBook Assistant

Install Gemini CLI
GitBook Assistant

Invalid token
GitBook Assistant

Wrong format
GitBook Assistant

Regenerate token
GitBook Assistant

No logs
GitBook Assistant

Missing token
GitBook Assistant

Re-run setup
GitBook Assistant

Instructions missing
GitBook Assistant

GEMINI.md absent
GitBook Assistant

Re-run setup
GitBook Assistant
## Support[#support](#support)

Contact Entro Customer Success or support channels.
GitBook Assistant

Last updated 4 months ago

- [Validation Checklist](#validation-checklist)
- [Common Issues](#common-issues)
- [Support](#support)
