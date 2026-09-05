Claude Plugin Installation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/ai-and-agents/claude-entro-marketplace/plugin-installation.md).

Follow these steps end to end: add the **SailPoint marketplace** first, then install the plugins you need—locally or for your whole organization.
GitBook Assistant
### Index[#index](#index)

- 

[Local setup](/integrations/ai-and-agents/claude-entro-marketplace/plugin-installation#local-setup)
GitBook Assistant

- 

[Add the SailPoint marketplace (local)](/integrations/ai-and-agents/claude-entro-marketplace/plugin-installation#add-the-sailpoint-marketplace-local)
GitBook Assistant
- 

[Install MCP Audit (local)](/integrations/ai-and-agents/claude-entro-marketplace/plugin-installation#install-mcp-audit-local)
GitBook Assistant
- 

[Install Secret Scanner (local)](/integrations/ai-and-agents/claude-entro-marketplace/plugin-installation#install-secret-scanner-local)
GitBook Assistant

- 

[Organization setup](/integrations/ai-and-agents/claude-entro-marketplace/plugin-installation#organization-setup)
GitBook Assistant

- 

[Add the SailPoint marketplace (organization)](/integrations/ai-and-agents/claude-entro-marketplace/plugin-installation#add-the-sailpoint-marketplace-organization)
GitBook Assistant
- 

[Distribute plugins (managed settings)](/integrations/ai-and-agents/claude-entro-marketplace/plugin-installation#distribute-plugins-managed-settings)
GitBook Assistant
- 

[Organization MCP Audit](/integrations/ai-and-agents/claude-entro-marketplace/plugin-installation#organization-mcp-audit)
GitBook Assistant
- 

[Organization Secret Scanner](/integrations/ai-and-agents/claude-entro-marketplace/plugin-installation#organization-secret-scanner)
GitBook Assistant

## Local setup[#local-setup](#local-setup)

### Add the SailPoint marketplace (local)[#add-the-sailpoint-marketplace-local](#add-the-sailpoint-marketplace-local)

Claude plugins are distributed via marketplaces. Add SailPoint’s marketplace to your local Claude configuration before installing any SailPoint plugin.
GitBook Assistant
#### Prerequisites[#prerequisites](#prerequisites)

- 

**Claude Code CLI** installed locally
GitBook Assistant
- 

**GitHub token and GitHub repository URL** for the marketplace, provided by SailPoint
GitBook Assistant

In your terminal, run the following. The repository URL and token are customer-specific—use the values Entro gave you.
GitBook Assistant
#### Browsing plugins[#browsing-plugins](#browsing-plugins)

After the marketplace is added, you can browse SailPoint’s plugins from the CLI.
GitBook Assistant
### Install MCP Audit (local)[#install-mcp-audit-local](#install-mcp-audit-local)
1

**Install**
GitBook Assistant

In your terminal, install the plugin from the SailPoint marketplace:
GitBook Assistant2

**Verify hooks**
GitBook Assistant

In Claude Code chat in your terminal, run `/hooks` to confirm the plugin configured hooks.
GitBook Assistant
### Install Secret Scanner (local)[#install-secret-scanner-local](#install-secret-scanner-local)
1

**Install**
GitBook Assistant

In your terminal, install the plugin from the SailPoint marketplace:
GitBook Assistant2

**Verify hooks**
GitBook Assistant

In Claude Code chat in your terminal, run `/hooks` to confirm the plugin configured hooks.
GitBook Assistant
## Organization setup[#organization-setup](#organization-setup)

### Add the SailPoint marketplace (organization)[#add-the-sailpoint-marketplace-organization](#add-the-sailpoint-marketplace-organization)

Org-wide installs also require the SailPoint marketplace to be registered in the Claude admin console.
GitBook Assistant
#### Prerequisites[#prerequisites-1](#prerequisites-1)

- 

**Claude Team or Enterprise** account
GitBook Assistant
- 

**GitHub token and GitHub repository URL** for the marketplace, provided by SailPoint
GitBook Assistant

In the Claude admin console, open **Claude Code** → **Managed settings**, and add the SailPoint marketplace using your repository URL and token.
GitBook Assistant

Add:
GitBook Assistant

Replace `<<YOUR_MARKETPLACE_REPOSITORY_URL>>` with the git URL SailPoint provided (including token in the URL if that is how your org configures it).
GitBook Assistant
### Distribute plugins (managed settings)[#distribute-plugins-managed-settings](#distribute-plugins-managed-settings)

In the same **Claude Code** → **Managed settings** JSON, add or merge `**enabledPlugins**` so required plugins install automatically for users on Claude Code in your organization.
GitBook Assistant

You normally maintain **one** managed-settings object that includes both `extraKnownMarketplaces` (from the previous step) and `enabledPlugins` (below).
GitBook Assistant

**Example (marketplace + both plugins)**
GitBook Assistant
### Distribution to Claude Desktop Code user[#organization-mcp-audit](#organization-mcp-audit)

In order to distribute the plugins to Claude Desktop Code, you will need to either upload as a zip or sync to a Github repo under your control after installing the Claude Github app.
GitBook Assistant

Claude Desktop Code, not to be confused with Claude Code, does not support hooks as well as Claude Code - and as such - behavior is less explicit and limited in support.
GitBook Assistant
### Organization MCP Audit[#organization-mcp-audit-1](#organization-mcp-audit-1)

Enable the MCP Audit plugin and set it as required. In managed settings, add the **agentic-audit** plugin as required.
GitBook Assistant

Add:
GitBook Assistant

After the plugin is required, it installs automatically for organization accounts using Claude Code. MCP tool calls are audited.
GitBook Assistant
### Organization Secret Scanner[#organization-secret-scanner](#organization-secret-scanner)

Enable the Secret Scanner plugin and set it as required. In managed settings, add **secret-scanner** or **secret-scanner-non-blocking** as required.
GitBook Assistant

Add:
GitBook Assistant

After the plugin is required, it installs automatically for organization accounts using Claude Code. Prompts and MCP calls are scanned for secrets.
GitBook Assistant[PreviousClaude SailPoint Marketplace](/integrations/ai-and-agents/claude-entro-marketplace)[NextGovernance Audit Plugin](/integrations/ai-and-agents/claude-entro-marketplace/mcp-audit)

Last updated 1 month ago

- [Index](#index)
- [Local setup](#local-setup)
- [Add the SailPoint marketplace (local)](#add-the-sailpoint-marketplace-local)
- [Install MCP Audit (local)](#install-mcp-audit-local)
- [Install Secret Scanner (local)](#install-secret-scanner-local)
- [Organization setup](#organization-setup)
- [Add the SailPoint marketplace (organization)](#add-the-sailpoint-marketplace-organization)
- [Distribute plugins (managed settings)](#distribute-plugins-managed-settings)
- [Distribution to Claude Desktop Code user](#organization-mcp-audit)
- [Organization MCP Audit](#organization-mcp-audit-1)
- [Organization Secret Scanner](#organization-secret-scanner)
Add SailPoint marketplaceGitBook AssistantAskCopy
```
claude plugin marketplace add \
https://<your_entro_marketplace_github_token>@<github_repository_url>
```
Install MCP Audit pluginGitBook AssistantAskCopy
```
claude plugin install agentic-audit@sailpoint
```
Install Secret Scanner pluginGitBook AssistantAskCopy
```
claude plugin install secret-scanner@sailpoint
```
GitBook AssistantAskCopy
```
{
  "extraKnownMarketplaces": {
    "sailpoint": {
      "source": {
        "source": "git",
        "url": "<<YOUR_MARKETPLACE_REPOSITORY_URL>>"
      }
    }
  }
}
```
GitBook AssistantAskCopy
```
{
  "enabledPlugins": {
    "agentic-audit@sailpoint": true,
    "secret-scanner@sailpoint": true
  },
  "extraKnownMarketplaces": {
    "sailpoint": {
      "source": {
        "source": "git",
        "url": "<<YOUR_MARKETPLACE_REPOSITORY_URL>>"
      }
    }
  }
}
```
GitBook AssistantAskCopy
```
{
  "enabledPlugins": {
    "agentic-audit@sailpoint": true
  }
}
```
GitBook AssistantAskCopy
```
{
  "enabledPlugins": {
    "secret-scanner@sailpoint": true
  }
}
```
