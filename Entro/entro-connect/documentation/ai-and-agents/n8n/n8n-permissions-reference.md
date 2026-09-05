n8n Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/ai-and-agents/n8n/n8n-permissions-reference.md).
## Required Scopes[#required-scopes](#required-scopes)

The API key must be created with the following scopes:
GitBook AssistantScopePurpose

`user:list`
GitBook Assistant

Map workflow ownership to n8n user identities
GitBook Assistant

`workflow:list`
GitBook Assistant

Enumerate all workflows for AI agent discovery
GitBook Assistant
## Permissions Justification[#permissions-justification](#permissions-justification)

- 

`user:list`** **is required to resolve which n8n user owns each workflow, enabling accurate identity attribution in Entro's AI Agents Inventory.
GitBook Assistant
- 

`workflow:list` is required to retrieve workflow definitions and inspect node types for LLM usage.
GitBook Assistant
- 

No `credential:*` scopes are requested - Entro does not access or retrieve credential values stored in n8n.
GitBook Assistant

## Access Summary[#access-summary](#access-summary)

- 

Authentication uses an **API Key** (`X-N8N-API-KEY` header)
GitBook Assistant
- 

All requests performed via the **n8n REST API**
GitBook Assistant
- 

All operations are read-only - no changes are made to workflows or credentials
GitBook Assistant
- 

API keys are stored encrypted in Entro's Worker Group environment (**AES-256**)
GitBook Assistant
- 

All communication over **HTTPS / TLS 1.3**
GitBook Assistant
[Previousn8n Onboarding](/integrations/ai-and-agents/n8n/n8n-onboarding)[Nextn8n Troubleshooting And Validation](/integrations/ai-and-agents/n8n/n8n-troubleshooting-and-validation)

Last updated 2 months ago

- [Required Scopes](#required-scopes)
- [Permissions Justification](#permissions-justification)
- [Access Summary](#access-summary)
