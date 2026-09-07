API Keys | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/settings/api-keys.md).

The **API Keys** page allows you to generate and manage access tokens for integrating with the Entro platform. API keys provide secure programmatic access to your organization’s data and functionalities through the Entro API.
GitBook Assistant
### **Creating an API Key**[#creating-an-api-key](#creating-an-api-key)

Navigate to **Settings → API Keys** to manage existing tokens or create new ones.
GitBook Assistant

To create a new key, click **“Generate new token.”** A modal window will appear, guiding you through the creation process.
GitBook Assistant
#### **Step 1: Select Access Type**[#step-1-select-access-type](#step-1-select-access-type)

Choose between:
GitBook Assistant

1. 

**Full Access API Key** Grants complete access to all Entro platform data and features, including the Entro Scanner. Recommended for trusted internal automation or integration services.
GitBook Assistant
1. 

**Scanner-Only API Key** Provides restricted access, limited to the Entro Scanner functionality. Ideal for scanning operations that don’t require modification of data or configurations.
GitBook Assistant

> 

⚠️ Handle API keys with care and limit their distribution. Full Access keys should only be granted to authorized systems or users.
GitBook Assistant
#### **Step 2: Define Token Details**[#step-2-define-token-details](#step-2-define-token-details)

- 

**Token Name:** Enter a clear, descriptive name to identify the purpose of the token (e.g., *CI Pipeline*, *Security Scanner*).
GitBook Assistant
- 

**Expiration:** Choose an expiration period from the dropdown menu (default is **90 days**). The expiration date will be displayed below automatically (e.g., *This token will expire on Sat, Jan 10, 2026*).
GitBook Assistant

Once configured, click **Generate New Token.**
GitBook Assistant
> 

⚠️ Tokens should have limited lifetimes. Regularly rotate and revoke keys to maintain strong security hygiene.
GitBook Assistant

[PreviousAlerts](/administration/settings/alerts)[NextBeta Features](/administration/settings/beta-features)

Last updated 10 months ago
