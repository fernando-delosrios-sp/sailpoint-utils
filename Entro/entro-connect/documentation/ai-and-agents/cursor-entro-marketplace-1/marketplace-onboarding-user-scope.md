VS Code Plugin Installation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/ai-and-agents/cursor-entro-marketplace-1/marketplace-onboarding-user-scope.md).

Follow these steps end to end. Configure the marketplace for local users first. Then install plugins or recommend them at workspace level.
GitBook Assistant
### Index[#index](#index)

- 

[User setup](/integrations/ai-and-agents/cursor-entro-marketplace-1/marketplace-onboarding-user-scope#user-setup)
GitBook Assistant

- 

[Add the SailPoint marketplace](/integrations/ai-and-agents/cursor-entro-marketplace-1/marketplace-onboarding-user-scope#add-the-sailpoint-marketplace-user)
GitBook Assistant
- 

[Install Governance Audit](/integrations/ai-and-agents/cursor-entro-marketplace-1/marketplace-onboarding-user-scope#install-governance-audit-user)
GitBook Assistant
- 

[Install Secret Scanner](/integrations/ai-and-agents/cursor-entro-marketplace-1/marketplace-onboarding-user-scope#install-secret-scanner-user)
GitBook Assistant

- 

[Workspace setup](/integrations/ai-and-agents/cursor-entro-marketplace-1/marketplace-onboarding-user-scope#workspace-setup)
GitBook Assistant

- 

[Add plugin recommendations](/integrations/ai-and-agents/cursor-entro-marketplace-1/marketplace-onboarding-user-scope#add-plugin-recommendations-workspace)
GitBook Assistant
- 

[Recommend Governance Audit](/integrations/ai-and-agents/cursor-entro-marketplace-1/marketplace-onboarding-user-scope#recommend-governance-audit-workspace)
GitBook Assistant
- 

[Recommend Secret Scanner](/integrations/ai-and-agents/cursor-entro-marketplace-1/marketplace-onboarding-user-scope#recommend-secret-scanner-workspace)
GitBook Assistant

### User setup[#user-setup](#user-setup)

#### Add the SailPoint marketplace (user)[#add-the-sailpoint-marketplace-user](#add-the-sailpoint-marketplace-user)

**Prerequisites**
GitBook Assistant

- 

**Visual Studio Code** installed locally
GitBook Assistant
- 

**GitHub Copilot** installed and signed in
GitBook Assistant
- 

**GitHub token and GitHub repository URL** provided by SailPoint
GitBook Assistant

Add the SailPoint marketplace to your local VS Code settings before installing any SailPoint plugin.
GitBook Assistant1

**Open the marketplace setting**
GitBook Assistant

In VS Code, open **Settings** and search for `chat.plugins.marketplaces`.
GitBook Assistant

If you prefer JSON, open **Command Palette** → **Preferences: Open User Settings (JSON)**.
GitBook Assistant2

**Add the SailPoint marketplace**
GitBook Assistant

Add a marketplace entry for the SailPoint repository.
GitBook Assistant

Use the repository URL SailPoint provided. If your access method includes a token in the URL, paste the full value exactly as provided.
GitBook Assistant3

**Save and reload VS Code**
GitBook Assistant

Save the settings change.
GitBook Assistant

Then run **Developer: Reload Window**.
GitBook Assistant
#### Install Governance Audit (user)[#install-governance-audit-user](#install-governance-audit-user)

Open the GitHub Copilot plugin install flow, select the SailPoint marketplace, and install:
GitBook Assistant

`agentic-audit@sailpoint`
GitBook Assistant

Reload VS Code if prompted.
GitBook Assistant
#### Install Secret Scanner (user)[#install-secret-scanner-user](#install-secret-scanner-user)

Open the GitHub Copilot plugin install flow, select the SailPoint marketplace, and install one of these plugins:
GitBook Assistant

- 

`secret-scanner@sailpoint`
GitBook Assistant
- 

`secret-scanner-non-blocking@sailpoint`
GitBook Assistant

Reload VS Code if prompted.
GitBook Assistant

Your local VS Code user can now discover and install SailPoint plugins.
GitBook Assistant
### Workspace setup[#workspace-setup](#workspace-setup)

#### Add plugin recommendations (workspace)[#add-plugin-recommendations-workspace](#add-plugin-recommendations-workspace)

Use workspace recommendations when you want a repository to suggest the correct SailPoint plugins to contributors.
GitBook Assistant

**Prerequisites**
GitBook Assistant

- 

A shared repository or workspace opened in **Visual Studio Code**
GitBook Assistant
- 

**GitHub Copilot** installed for workspace users
GitBook Assistant
- 

The SailPoint marketplace already configured for users who will install plugins
GitBook Assistant

Open the workspace recommendation file in your repository. Then add the plugin IDs you want users to install.
GitBook Assistant
#### Recommend Governance Audit (workspace)[#recommend-governance-audit-workspace](#recommend-governance-audit-workspace)

Add this plugin ID to the recommended plugin list:
GitBook Assistant

`agentic-audit@sailpoint`
GitBook Assistant

Commit the workspace change so the recommendation is shared with the team.
GitBook Assistant
#### Recommend Secret Scanner (workspace)[#recommend-secret-scanner-workspace](#recommend-secret-scanner-workspace)

Add one of these plugin IDs to the recommended plugin list:
GitBook Assistant

- 

`secret-scanner@sailpoint`
GitBook Assistant
- 

`secret-scanner-non-blocking@sailpoint`
GitBook Assistant

Commit the workspace change so the recommendation is shared with the team.
GitBook Assistant

Your workspace now recommends the SailPoint plugin set your team should use.
GitBook Assistant[PreviousVisual Studio Code SailPoint Marketplace](/integrations/ai-and-agents/cursor-entro-marketplace-1)[NextGovernance Audit Plugin](/integrations/ai-and-agents/cursor-entro-marketplace-1/mcp-audit)

Last updated 1 month ago

- [Index](#index)
- [User setup](#user-setup)
- [Workspace setup](#workspace-setup)
