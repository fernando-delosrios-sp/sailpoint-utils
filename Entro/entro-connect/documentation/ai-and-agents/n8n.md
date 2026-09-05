n8n | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/ai-and-agents/n8n.md).

The **n8n Integration** enables Entro Security to continuously discover and monitor AI agents and the secrets they use across your automation workflows. This integration specifically identifies workflows incorporating Large Language Model (LLM) nodes and surfaces them in the AI Agents Inventory.
GitBook Assistant
## Architecture[#architecture](#architecture)

Entro utilizes a **Collector Layer** to gather data from the n8n API. For n8n Cloud, communication is established via HTTPS with TLS 1.3 encryption.
GitBook AssistantGitBook AssistantAskCopy
```
+-----------------------+           +-----------------------+
|    Entro Security     |           |     n8n Instance      |
|    (Control Plane)    | <-------> |   (Cloud/Enterprise)  |
+-----------------------+   HTTPS   +-----------------------+
                          (TLS 1.3)
```

## Integration Highlights[#integration-highlights](#integration-highlights)

- 

Discover AI agent workflows using LLM nodes - LangChain, OpenAI, Anthropic, Gemini and more
GitBook Assistant
- 

Identify and monitor secrets and credentials referenced within workflow nodes
GitBook Assistant
- 

Map workflow ownership to n8n user identities
GitBook Assistant

## Prerequisites[#prerequisites](#prerequisites)

- 

An active **n8n Cloud** or **Enterprise** / **self-hosted** instance
GitBook Assistant
- 

Admin access to generate an API key in n8n
GitBook Assistant

## Security & Compliance[#security-and-compliance](#security-and-compliance)

- 

Communication secured via **HTTPS / TLS 1.3**
GitBook Assistant
- 

API credentials are **AES-256 encrypted** at rest within Entro
GitBook Assistant
- 

Integration operates with **read-only permissions** - no changes are made to your workflows
GitBook Assistant
[PreviousIntegrations Index](/integrations)[Nextn8n Onboarding](/integrations/ai-and-agents/n8n/n8n-onboarding)

Last updated 2 months ago

- [Architecture](#architecture)
- [Integration Highlights](#integration-highlights)
- [Prerequisites](#prerequisites)
- [Security & Compliance](#security-and-compliance)
