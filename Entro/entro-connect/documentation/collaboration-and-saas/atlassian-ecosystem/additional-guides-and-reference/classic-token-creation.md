Classic Token Creation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/classic-token-creation.md).

This guide explains how to generate API tokens for your **Atlassian environment**. Entro Security uses these tokens to authenticate securely with Jira and Confluence - allowing **read-only access** for scanning issues, pages, and repositories for exposed secrets.
GitBook Assistant
## Choosing the Right Method[#choosing-the-right-method](#choosing-the-right-method)

Use the table below to determine which token generation method applies to your environment.
GitBook AssistantEnvironmentWhere to Create TokenApplies ToNotes

**Atlassian Cloud**
GitBook Assistant

[id.atlassian.com → Security → API Tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
GitBook Assistant

Jira Cloud, Confluence Cloud, Bitbucket Cloud
GitBook Assistant

Tokens are managed via your Atlassian Account portal.
GitBook Assistant

**Atlassian Server / Data Center**
GitBook Assistant

Product UI → *Profile → Personal Access Tokens*
GitBook Assistant

Jira Server, Confluence Server
GitBook Assistant

Tokens are created locally within each application.
GitBook Assistant
## Atlassian Cloud[#atlassian-cloud](#atlassian-cloud)

For **Jira Cloud and** **Confluence Cloud**, all API tokens are created and managed centrally at [id.atlassian.com](https://id.atlassian.com/manage-profile/security/api-tokens).
GitBook Assistant1
#### Log In to Your Atlassian Account[#log-in-to-your-atlassian-account](#log-in-to-your-atlassian-account)

- 

Navigate to [id.atlassian.com/manage-profile/security/api-tokens](https://id.atlassian.com/manage-profile/security/api-tokens).
GitBook Assistant
- 

Sign in with the Atlassian account used by Entro’s integration user.
GitBook Assistant
2
#### Create a New API Token[#create-a-new-api-token](#create-a-new-api-token)

- 

Click **Create API token**.
GitBook Assistant
- 

Enter a label such as **EntroSecurity_Integration**.
GitBook Assistant
- 

Click **Create**.
GitBook Assistant
- 

Copy the generated token - you will not be able to view it again later.
GitBook Assistant
3
#### Store the Token Securely[#store-the-token-securely](#store-the-token-securely)

- 

Paste the token into Entro Security’s **Integration Settings** when connecting Atlassian Cloud.
GitBook Assistant
- 

Optionally, store it in a secrets manager (e.g., Akeyless Vault/1Password) for rotation tracking.
GitBook Assistant
- 

You may revoke tokens at any time via the Atlassian Security dashboard.
GitBook Assistant

Best Practice: Create a dedicated integration user (see [Dedicated Atlassian User](/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/dedicated-atlassian-user-creation)) and use its credentials to minimize exposure.
GitBook Assistant
## Atlassian Server / Data Center[#atlassian-server-data-center](#atlassian-server-data-center)

For on-prem or self-hosted environments (e.g. **Jira Server**, **Confluence Server**), tokens are created within each product’s native settings.
GitBook Assistant1
#### Log In as the Integration User[#log-in-as-the-integration-user](#log-in-as-the-integration-user)

- 

Open your Jira or Confluence Server web console.
GitBook Assistant
- 

Log in with the **dedicated Entro integration account**.
GitBook Assistant
- 

Navigate to the user’s **Profile**.
GitBook Assistant
2
#### Create a Personal Access Token (PAT)[#create-a-personal-access-token-pat](#create-a-personal-access-token-pat)

- 

From your profile page, select **Personal Access Tokens**.
GitBook Assistant
- 

Click **Create Token**.
GitBook Assistant
- 

Name it **EntroSecurity_Scanner**.
GitBook Assistant
- 

Set an expiry period (recommended: at least 7 days).
GitBook Assistant
- 

Click **Create**.
GitBook Assistant
- 

Copy and securely store the generated token.
GitBook Assistant
3
#### Configure the Token in Entro Security[#configure-the-token-in-entro-security](#configure-the-token-in-entro-security)

In your **Entro Security dashboard**:
GitBook Assistant

- 

Navigate to **Management → Accounts & Integrations → Add New Account**.
GitBook Assistant
- 

Select **Atalassian.**
GitBook Assistant
- 

Enter your **base URL** and paste the **Personal Access Token**.
GitBook Assistant
- 

Test the connection and click **Save**.
GitBook Assistant

## Permissions Required[#permissions-required](#permissions-required)
ProductRequired PermissionsDescription

**Jira**
GitBook Assistant

`Browse Projects`, `View Issues`, `View Attachments`, `Add Comments` *(optional for auto-remediation)*
GitBook Assistant

Allows Entro to scan and annotate Jira content.
GitBook Assistant

**Confluence**
GitBook Assistant

`View Pages`, `View Attachments`, `View Comments`
GitBook Assistant

Enables page and comment scanning.
GitBook Assistant
## Security & Best Practices[#security-and-best-practices](#security-and-best-practices)

- 

Always use **read-only** tokens for integration.
GitBook Assistant
- 

Rotate API tokens periodically (recommended every 90 days).
GitBook Assistant
- 

Avoid using personal user tokens; create a **dedicated service account** instead.
GitBook Assistant
- 

If a token is revoked, Entro will automatically retry authentication and notify administrators.
GitBook Assistant
[PreviousDedicated Atlassian User Creation](/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/dedicated-atlassian-user-creation)[NextAPI Endpoints in Use](/integrations/collaboration-and-saas/atlassian-ecosystem/additional-guides-and-reference/api-endpoints-in-use)

Last updated 4 months ago

- [Choosing the Right Method](#choosing-the-right-method)
- [Atlassian Cloud](#atlassian-cloud)
- [Atlassian Server / Data Center](#atlassian-server-data-center)
- [Permissions Required](#permissions-required)
- [Security & Best Practices](#security-and-best-practices)
