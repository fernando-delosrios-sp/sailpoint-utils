Cursor Plugin Installation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/ai-and-agents/cursor-entro-marketplace/marketplace-onboarding-user-scope.md).

Follow these steps end to end. Use the local flow for individual installs. Use the organization flow for managed rollout.
GitBook Assistant
### Index[#index](#index)

- 

[Local setup](/integrations/ai-and-agents/cursor-entro-marketplace/marketplace-onboarding-user-scope#local-setup)
GitBook Assistant

- 

[Get the SailPoint plugin source](/integrations/ai-and-agents/cursor-entro-marketplace/marketplace-onboarding-user-scope#get-the-sailpoint-plugin-source-local)
GitBook Assistant
- 

[Install Governance Audit](/integrations/ai-and-agents/cursor-entro-marketplace/marketplace-onboarding-user-scope#install-governance-audit-local)
GitBook Assistant
- 

[Install Secret Scanner](/integrations/ai-and-agents/cursor-entro-marketplace/marketplace-onboarding-user-scope#install-secret-scanner-local)
GitBook Assistant

- 

[Organization setup](/integrations/ai-and-agents/cursor-entro-marketplace/marketplace-onboarding-user-scope#organization-setup)
GitBook Assistant

- 

[Add the SailPoint marketplace](/integrations/ai-and-agents/cursor-entro-marketplace/marketplace-onboarding-user-scope#add-the-sailpoint-marketplace-organization)
GitBook Assistant
- 

[Require Governance Audit](/integrations/ai-and-agents/cursor-entro-marketplace/marketplace-onboarding-user-scope#require-governance-audit-organization)
GitBook Assistant
- 

[Require Secret Scanner](/integrations/ai-and-agents/cursor-entro-marketplace/marketplace-onboarding-user-scope#require-secret-scanner-organization)
GitBook Assistant

### Local setup[#local-setup](#local-setup)

#### Get the SailPoint plugin source (local)[#get-the-sailpoint-plugin-source-local](#get-the-sailpoint-plugin-source-local)

Use this flow when you install plugins for a single Cursor user.
GitBook Assistant

**Prerequisites**
GitBook Assistant

- 

**Cursor** installed locally
GitBook Assistant
- 

**GitHub token and GitHub repository URL** provided by SailPoint
GitBook Assistant

Cursor local installs use the plugin folders from your private SailPoint marketplace repository.
GitBook Assistant

1. 

Clone or download your private marketplace repository.
GitBook Assistant
1. 

Copy plugin folders into `~/.cursor/plugins/local/`.
GitBook Assistant
1. 

Keep `.cursor-plugin/plugin.json` at the plugin root.
GitBook Assistant
1. 

Restart Cursor or run **Developer: Reload Window**.
GitBook Assistant

This flow works on any Cursor plan. Team marketplace management requires Cursor Team or Enterprise.
GitBook Assistant
#### Install Governance Audit (local)[#install-governance-audit-local](#install-governance-audit-local)

Copy the `agentic-audit` plugin directory from the marketplace repository into:
GitBook Assistant

Then reload Cursor.
GitBook Assistant
#### Install Secret Scanner (local)[#install-secret-scanner-local](#install-secret-scanner-local)

Copy one of these plugin directories from the marketplace repository into:
GitBook Assistant

- 

`secret-scanner`
GitBook Assistant
- 

`secret-scanner-non-blocking`
GitBook Assistant

Then reload Cursor.
GitBook Assistant
### Organization setup[#organization-setup](#organization-setup)

#### Add the SailPoint marketplace (organization)[#add-the-sailpoint-marketplace-organization](#add-the-sailpoint-marketplace-organization)

Use this flow when you manage plugins for a Cursor organization.
GitBook Assistant

**Prerequisites**
GitBook Assistant

- 

**Cursor Team or Enterprise**
GitBook Assistant
- 

**GitHub repository URL** provided by SailPoint
GitBook Assistant

In the Cursor admin dashboard, add the SailPoint marketplace using the customer-specific repository URL SailPoint provided.
GitBook Assistant
#### Require Governance Audit (organization)[#require-governance-audit-organization](#require-governance-audit-organization)

In the Cursor admin dashboard, enable **Governance Audit** and mark it as required.
GitBook Assistant

After that, the plugin installs automatically for users in your organization. MCP tool calls are audited.
GitBook Assistant
#### Require Secret Scanner (organization)[#require-secret-scanner-organization](#require-secret-scanner-organization)

In the Cursor admin dashboard, enable **Secret Scanner** or **Secret Scanner Non-Blocking** and mark it as required.
GitBook Assistant

After that, prompts and MCP tool calls are scanned for secrets for users in your organization.
GitBook Assistant[PreviousCursor SailPoint Marketplace](/integrations/ai-and-agents/cursor-entro-marketplace)[NextGovernance Audit Plugin](/integrations/ai-and-agents/cursor-entro-marketplace/mcp-audit)

Last updated 1 month ago

- [Index](#index)
- [Local setup](#local-setup)
- [Organization setup](#organization-setup)
GitBook AssistantAskCopy
```
~/.cursor/plugins/local/
```
GitBook AssistantAskCopy
```
~/.cursor/plugins/local/
```
