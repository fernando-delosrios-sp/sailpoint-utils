n8n Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/ai-and-agents/n8n/n8n-onboarding.md).1
#### Generate an API Key in n8n [#generate-an-api-key-in-n8n](#generate-an-api-key-in-n8n)

- 

Log in to your n8n instance.
GitBook Assistant
- 

Navigate to **Settings → n8n API**. 
GitBook Assistant
- 

Click **Create an API Key**. 
GitBook Assistant
- 

Set a **Label **(e.g Entro Integration)
GitBook Assistant
- 

Set **Expiration** to **No Expiration** to ensure uninterrupted discovery.
GitBook Assistant
- 

Under **Scopes**, select only the following:
GitBook Assistant

- 

`user:list`
GitBook Assistant
- 

`workflow:list`
GitBook Assistant

- 

Click **Save** and copy the key - you will need it in the next step. 
GitBook Assistant
2
#### Identify your Base URL[#identify-your-base-url](#identify-your-base-url)

- 

**n8n Cloud**: `https://<instance>.app.n8n.cloud`
GitBook Assistant
- 

**Self-hosted**: `https://<your-domain>`
GitBook Assistant
3
#### Configure Integration in Entro[#configure-integration-in-entro](#configure-integration-in-entro)

- 

In the Entro Dashboard, navigate to **Management → Accounts & Integrations → Add New Account (top right) → n8n.**
GitBook Assistant
- 

Select your instance type - **n8n Cloud** or **n8n Self-Hosted**. 
GitBook Assistant
- 

Fill in the following fields:
GitBook Assistant
FieldDescription

Environment
GitBook Assistant

A unique identifier for this instance (e.g., `my-n8n-instance`)
GitBook Assistant

Display Name
GitBook Assistant

A human-readable name (e.g., `My n8n Account`)
GitBook Assistant

Instance URL
GitBook Assistant

Your instance URL (e.g., `https://<instance>.app.n8n.cloud`)
GitBook Assistant

API Key
GitBook Assistant

The key generated in Step 1
GitBook Assistant

Worker Group (Connector)
GitBook Assistant

Select the appropriate Entro connector
GitBook Assistant

- 

Click **Connect**.
GitBook Assistant
4
#### Verification[#verification](#verification)

Once connected, the integration status displays **Verified**. Entro will perform an initial discovery scan - navigate to **AI** **Inventory** and filter by **n8n** to review discovered AI agent workflows.
GitBook Assistant[Previousn8n](/integrations/ai-and-agents/n8n)[Nextn8n Permissions Reference](/integrations/ai-and-agents/n8n/n8n-permissions-reference)

Last updated 2 months ago
