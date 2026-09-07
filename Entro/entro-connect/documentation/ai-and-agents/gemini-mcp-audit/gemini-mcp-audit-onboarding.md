Gemini MCP Audit Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/ai-and-agents/gemini-mcp-audit/gemini-mcp-audit-onboarding.md).
## Prerequisites[#prerequisites](#prerequisites)

- 

Gemini CLI installed
GitBook Assistant
- 

Node.js 18+
GitBook Assistant
- 

Entro authentication token (64-character hex)
GitBook Assistant
- 

Download the Installation zip below.
GitBook Assistant
[gemini-instructions.zip](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2FQA83cI2Q1sn3I8ErAkSw%2Fgemini-instructions.zip?alt=media&token=4ba4c2d0-e586-4da2-a6c4-af7f1aa0b02b)archive · 18KBDownload[Open](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2FQA83cI2Q1sn3I8ErAkSw%2Fgemini-instructions.zip?alt=media&token=4ba4c2d0-e586-4da2-a6c4-af7f1aa0b02b)1
#### Run Setup Script[#run-setup-script](#run-setup-script)

macOS / Linux - Open terminal at the extracted zip folder location
GitBook AssistantGitBook AssistantAskCopy
```
chmod +x setup.sh
./setup.sh
```

Windows - open Powershell at the extracted zip folder location
GitBook AssistantGitBook AssistantAskCopy
```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\setup.ps1
```
2
#### Provide Entro Token[#provide-entro-token](#provide-entro-token)

Enter your token when prompted. Provided by Entro Security
GitBook Assistant3
#### Configuration Completion[#configuration-completion](#configuration-completion)

- 

Creates or updates `~/.gemini/settings.json`
GitBook Assistant
- 

Configures Entro MCP endpoint
GitBook Assistant
- 

Loads `GEMINI.md`
GitBook Assistant

Last updated 4 months ago
