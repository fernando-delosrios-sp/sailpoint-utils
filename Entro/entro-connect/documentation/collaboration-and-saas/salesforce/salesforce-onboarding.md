Salesforce Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/salesforce/salesforce-onboarding.md).
## Part 1 - Create an External Client App[#part-1-create-an-external-client-app](#part-1-create-an-external-client-app)
1
#### Create new app[#create-new-app](#create-new-app)

- 

Login to your Salesforce instance as an admin
GitBook Assistant
- 

Navigate to **Advanced Setup** → **Apps** → **External Client App Manager**
GitBook Assistant
- 

On the top right corner, click on '**New External Client App'**
GitBook Assistant
2
#### Fill in Basic Information[#fill-in-basic-information](#fill-in-basic-information)

- 

**External Client App Name:** `entro`
GitBook Assistant
- 

**API Name:** `entro`
GitBook Assistant
- 

**Contact Email:** Enter a valid contact email
GitBook Assistant
- 

**Distribution State:** Select `Local`
GitBook Assistant
3
#### **Configure API (Enable OAuth Settings)**[#configure-api-enable-oauth-settings](#configure-api-enable-oauth-settings)

- 

Check the '**Enable OAuth**' option
GitBook Assistant
- 

Under **App Settings:**
GitBook Assistant

- 

**Callback URL:** Enter `https://app.entro.security` (This is a placeholder required by Salesforce but not used for this flow).
GitBook Assistant
- 

**Selected OAuth Scopes:** Add `**Manage user data via APIs (api)**`
GitBook Assistant

- 

Under **Flow Enablement**, check the `**Enable Client Credentials Flow**` option
GitBook Assistant
- 

Under **Security** uncheck all options.
GitBook Assistant
4
#### Review and create[#review-and-create](#review-and-create)

Click on **Create** to launch the app. &#xNAN;*Note:* Changes may take a few minutes to propagate in Salesforce.
GitBook Assistant
## Part 2 - Configure Policies[#part-2-configure-policies](#part-2-configure-policies)
1
#### Edit Policies[#edit-policies](#edit-policies)

- 

In the Policies tab, Click **Edit**.
GitBook Assistant
- 

**Under OAuth Policies:**
GitBook Assistant

- 

In **Plugin Policies** → **Permitted Users:** Select `All users can self-authorize`.
GitBook Assistant

- 

**Under Client Credentials Flow:**
GitBook Assistant

- 

In **Run As User:** Search for and select the user you would like to use for this integration.
GitBook Assistant

*Note:* You may use an existing user, or create a dedicated user with limited permissions for security hygiene.
GitBook Assistant2
#### Optional: Create dedicated user with required permissions[#optional-create-dedicated-user-with-required-permissions](#optional-create-dedicated-user-with-required-permissions)

When using a dedicated user, with custom profile, make sure to assign the following permissions:
GitBook Assistant

- 

**Navigate to Setup → Users → Profiles**
GitBook Assistant
- 

**Create a new profile, based on "Minimum Access - Salesforce"**
GitBook Assistant

- 

**After creation, edit default permissions:**
GitBook Assistant

- 

**Under 'Administrative Permissions', make sure to check:**
GitBook Assistant

- 

API Enabled
GitBook Assistant
- 

Modify Metadata Through Metadata API Functions
GitBook Assistant

- 

**Under 'Standard Object Permissions', make sure to check:**
GitBook Assistant

- 

**Cases:** Read, View All Fields
GitBook Assistant

- 

**Create a new user and assign this custom profile to it**
GitBook Assistant

- 

Make sure to check the 'Service Cloud User' under role for this user.
GitBook Assistant

Note: Verify the 'Service Cloud User' is set to **Active** under **Setup → Company Information**
GitBook Assistant3
#### Click **Save**[#click-save](#click-save)

## Part 3 - Retrieve Credentials[#part-3-retrieve-credentials](#part-3-retrieve-credentials)

- 

On the same app page, navigate to the **Settings** tab.
GitBook Assistant
- 

Under **OAuth Settings**, click on '**Consumer Key and Secret'** section.
GitBook Assistant
- 

You will be required to authenticate to Salesforce.
GitBook Assistant
- 

Copy the **Consumer Key** and **Consumer Secret** to be used for this integration.
GitBook Assistant

## Part 4 - Connect Salesforce to Entro[#part-4-connect-salesforce-to-entro](#part-4-connect-salesforce-to-entro)

- 

In the Entro platform, navigate to: **Management → Accounts & Integrations → Add New Account (top right) → Salesforce**
GitBook Assistant
- 

Fill in the following fields:
GitBook Assistant

- 

Name - A name for the integration to be used within Entro (e.g., `Salesforce-CRM`).
GitBook Assistant
- 

**Salesforce URL -** Your specific domain URL (e.g., `https://<mycompany>.my.salesforce.com`).
GitBook Assistant
- 

**Consumer Key** - generated in previous step
GitBook Assistant
- 

**Consumer Secret** - generated in previous step
GitBook Assistant

1. 

Click **Connect**
GitBook Assistant

### Validation[#validation](#validation)

After connecting, Entro automatically:
GitBook Assistant

- 

Validates the provided credentials.
GitBook Assistant
- 

Confirms read access to Table and Attachment APIs
GitBook Assistant
- 

Begins secret scanning of service cases.
GitBook Assistant

When successful, the integration status will display **Verified** in the Entro Console.
GitBook Assistant[PreviousSalesforce](/integrations/collaboration-and-saas/salesforce)[NextSalesforce Troubleshooting And Validation](/integrations/collaboration-and-saas/salesforce/salesforce-troubleshooting-and-validation)

Last updated 4 months ago

- [Part 1 - Create an External Client App](#part-1-create-an-external-client-app)
- [Part 2 - Configure Policies](#part-2-configure-policies)
- [Part 3 - Retrieve Credentials](#part-3-retrieve-credentials)
- [Part 4 - Connect Salesforce to Entro](#part-4-connect-salesforce-to-entro)
- [Validation](#validation)
