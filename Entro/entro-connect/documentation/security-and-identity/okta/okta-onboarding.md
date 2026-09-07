Okta Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/okta/okta-onboarding.md).1
#### Open the Okta Onboarding Form in Entro[#open-the-okta-onboarding-form-in-entro](#open-the-okta-onboarding-form-in-entro)

- 

In the Entro Dashboard, navigate to **Management → Accounts & Integrations → Add New Account (top right) → Okta**.
GitBook Assistant
- 

Scroll to the bottom of the form and copy the **Public Key** — you will need it in Step 4.
GitBook Assistant
- 

Keep this tab open throughout the process.
GitBook Assistant
2
#### Log in to Okta and Access the Admin Console[#log-in-to-okta-and-access-the-admin-console](#log-in-to-okta-and-access-the-admin-console)

- 

Log in to your Okta account.
GitBook Assistant
- 

Note your Okta domain (e.g. `https://<domainName>.okta.com`) - you will need it later.
GitBook Assistant
- 

Navigate to the Okta Admin Console.
GitBook Assistant
3
#### Create a New API Service App[#create-a-new-api-service-app](#create-a-new-api-service-app)

- 

Navigate to **Applications → Applications → Create App Integration**.
GitBook Assistant

- 

Select **API Services** and click **Next**.
GitBook Assistant

- 

Enter a name for the app (e.g. `Entro Security Integration`) and click **Save**.
GitBook Assistant
4
#### Configure Client Credentials[#configure-client-credentials](#configure-client-credentials)

- 

Click on the new Application you created to get to the **General** tab.
GitBook Assistant

- 

Click **Edit** under **Client Credentials**.
GitBook Assistant

- 

Set **Client Authentication** to **Public key / Private key**, and click **Edit **under **Public keys** below.
GitBook Assistant
- 

Click **Add key **when it appears (after **Edit**).
GitBook Assistant

- 

Switch back to the **Entro onboarding form** and copy the **Public Key.**
GitBook Assistant

- 

Paste the key into Okta and click **Done**, then **Save**.
GitBook Assistant
- 

Copy the **Client ID** shown on the app's General tab - you will need it in the final step.
GitBook Assistant
5
#### Adjust App Settings[#adjust-app-settings](#adjust-app-settings)

- 

Still on the **General** tab of the App, click **Edit** under **General Settings**.
GitBook Assistant
- 

Uncheck **"Require Demonstrating Proof of Possession (DPoP) header in token requests"**.
GitBook Assistant
- 

Click **Save**.
GitBook Assistant
6
#### Grant Required API Scopes[#grant-required-api-scopes](#grant-required-api-scopes)

- 

Go to the **Okta API Scopes** tab.
GitBook Assistant

- 

Find and grant the following scopes:
GitBook Assistant
ScopePurpose

`okta.apps.read`
GitBook Assistant

Read application metadata
GitBook Assistant

`okta.appGrants.read`
GitBook Assistant

Read API grant permissions per app
GitBook Assistant

`okta.roles.read`
GitBook Assistant

List role assignments
GitBook Assistant

`okta.users.read`
GitBook Assistant

Access user and profile data
GitBook Assistant

`okta.logs.read`
GitBook Assistant

Retrieve Okta audit logs
GitBook Assistant

`okta.apiTokens.read`
GitBook Assistant

Access API token metadata
GitBook Assistant7
#### Assign Admin Role[#assign-admin-role](#assign-admin-role)

- 

Go to the **Admin Roles** tab and click **Edit Assignment**.
GitBook Assistant

- 

Select **Super Administrator** and click **Save Changes**.
GitBook Assistant

Super Administrator is required for full NHI visibility, including API grant permissions per Okta app. If your organization cannot grant Super Administrator, refer to [Okta Custom Entro Role](/integrations/security-and-identity/okta/okta-custom-entro-role) for a least-privilege alternative - note that this will result in partial visibility.
GitBook Assistant8
#### Configure Integration in Entro[#configure-integration-in-entro](#configure-integration-in-entro)

- 

Return to the Entro onboarding form and fill in the following fields:
GitBook Assistant
FieldValue

**Environment**
GitBook Assistant

A unique identifier for this connection (e.g. `Okta-myorg`)
GitBook Assistant

**Display Name**
GitBook Assistant

A human-readable name (e.g. `My Account`)
GitBook Assistant

**Okta Domain**
GitBook Assistant

Your Okta domain (e.g. `https://mydomain.okta.com`)
GitBook Assistant

**Client Id**
GitBook Assistant

The Client ID copied in Step 4
GitBook Assistant

**Worker Group (Connector)**
GitBook Assistant

Select the appropriate Entro connector
GitBook Assistant

- 

Click **Create Account**.
GitBook Assistant
9
### Verification[#verification](#verification)

Once connected, the integration status displays **Verified**. Navigate to **NHI Inventory** and filter by **Okta** to review discovered applications, credentials, and user data.
GitBook Assistant[PreviousOkta](/integrations/security-and-identity/okta)[NextOkta Custom Entro Role](/integrations/security-and-identity/okta/okta-custom-entro-role)

Last updated 2 months ago
