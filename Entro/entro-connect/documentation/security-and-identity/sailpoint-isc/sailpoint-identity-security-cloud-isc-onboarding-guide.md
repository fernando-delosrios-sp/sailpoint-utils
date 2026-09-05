SailPoint Identity Security Cloud (ISC) Onboarding Guide | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/sailpoint-isc/sailpoint-identity-security-cloud-isc-onboarding-guide.md).

Follow this step-by-step procedure to link your SailPoint Identity Security Cloud (formerly IdentityNow) tenant with the Entro platform.
GitBook Assistant
### Prerequisites[#prerequisites](#prerequisites)

- 

Administrative access to your target SailPoint Identity Security Cloud tenant.
GitBook Assistant
- 

Explicit permissions to create new API Clients (`Admin → Global → Security Settings → API Management`).
GitBook Assistant
- 

A valid SailPoint Tenant URL (e.g. `https://acme.api.identitynow.com`).
GitBook Assistant
- 

Network reachability enabling outbound HTTPS access over port 443 from your Worker Group host to the Entro API and SailPoint tenant API endpoints.
GitBook Assistant

### Step-by-Step Configuration[#step-by-step-configuration](#step-by-step-configuration)

#### Step 1: Log in to SailPoint ISC[#step-1-log-in-to-sailpoint-isc](#step-1-log-in-to-sailpoint-isc)

Log in to your SailPoint enterprise tenant admin console as an administrator (possessing the `ORG_ADMIN` user level or equivalent rules allowing API Client setup).
GitBook Assistant
#### Step 2: Navigate to API Management[#step-2-navigate-to-api-management](#step-2-navigate-to-api-management)

From the admin panel interface, open the navigation menu and go to **Admin** → **Global** → **Security Settings** → **API Management**. Click the **Create API Client** button to initiate the client configuration window.
GitBook Assistant
#### Step 3: Populate the New API Client Form[#step-3-populate-the-new-api-client-form](#step-3-populate-the-new-api-client-form)

Provide the following precise details inside the configuration wizard:
GitBook Assistant

- 

**Description:** Input a distinct identifier to track this specific token connection (e.g. `Entro Integration`).
GitBook Assistant
- 

**Grant Types:** Check the box for **Client Credentials** only. Leave *Refresh Token* and *Authorization Code* unchecked.
GitBook Assistant

- 

Note: Selecting alternative grant options breaks the background automated service task sync, resulting in validation errors.
GitBook Assistant

- 

**Scopes:** Use the scope search tool to find and explicitly toggle **ON** the following five items. Ensure all other unlisted scopes remain toggled **OFF**:
GitBook Assistant

`sp:scopes:default`
GitBook Assistant

Baseline token authorization requirement; essential for Search API use
GitBook Assistant

`sp:search:read`
GitBook Assistant

Enables executing Search API queries to retrieve identities, accounts, and entitlements for inventory aggregation
GitBook Assistant

`idn:role-unchecked:read`
GitBook Assistant

Enables reading SailPoint Roles and structural identity-to-role assignments
GitBook Assistant

`idn:accounts:read`
GitBook Assistant

Enables reading linked source target accounts to support identity correlation engines
GitBook Assistant

`idn:sources:read`
GitBook Assistant

Enables reading source engine metadata references
GitBook Assistant

`idn:identity-profile:read`
GitBook Assistant

Enables scanning identity profile structural properties
GitBook Assistant
> 
#### Least Privilege Warning[#least-privilege-warning](#least-privilege-warning)

Do not enable `sp:scopes:all`. This grants broad access levels tied directly to the API Client owner's global user rights, violating least privilege engineering practices. The five specific scopes listed above are sufficient.
GitBook Assistant
#### Step 4: Provision Client and Copy Token Secrets[#step-4-provision-client-and-copy-token-secrets](#step-4-provision-client-and-copy-token-secrets)

Click the **Create** button at the base of the settings page. The interface will display a one-time generated **Client ID** and **Client Secret**.
GitBook Assistant

- 

Copy the Client Secret string immediately. It is concealed permanently once the window closes. If lost, you must delete the client item and start over.
GitBook Assistant
- 

Retain the **Client ID**, **Client Secret**, and **Tenant URL** inside a secure vault for insertion during the next section.
GitBook Assistant

#### Step 5: Activate Integration in Entro Console[#step-5-activate-integration-in-entro-console](#step-5-activate-integration-in-entro-console)

1. 

Log in to your Entro environment.
GitBook Assistant
1. 

Navigate precisely to: **Management** → **Accounts & Integrations** → **Add New Account (top right)** → **SailPoint ISC**.
GitBook Assistant
1. 

Fill out the displayed configuration fields:
GitBook Assistant

- 

**Environment Nickname:** Enter a tracking name for this specific connection target (e.g. `Acme-Prod-ISC`).
GitBook Assistant
- 

**Tenant URL:** Provide the base endpoint path collected in Step 4 (e.g. `https://acme.api.identitynow.com`).
GitBook Assistant

- 

Note: Need to add the `api` before the `identitynow.com` in the tenant URL.
GitBook Assistant

- 

**Client ID:** Paste the client ID string from Step 4.
GitBook Assistant
- 

**Client Secret:** Paste the client secret string token from Step 4.
GitBook Assistant
- 

**Worker Group (Connector):** Pick the designated active worker configuration group assigned to handle these platform discovery scans.
GitBook Assistant

1. 

Click the **Connect** button to save the configuration profile.
GitBook Assistant

#### Step 6: Monitor Automated Verification Status[#step-6-monitor-automated-verification-status](#step-6-monitor-automated-verification-status)

Entro automatically initiates background validation tests by requesting an access token and executing a read verify query. This task usually completes in under one minute:
GitBook Assistant

- 

**Verified:** The platform connection is established; automated inventory mapping tasks will initiate on the next scheduled run interval.
GitBook Assistant
- 

**Error:** The authentication process failed. Review the provided verification failure message details to target structural configuration mistakes.
GitBook Assistant
[PreviousSailPoint Identity Security Cloud (formerly IdentityNow)](/integrations/security-and-identity/sailpoint-isc)[NextSailPoint Identity Security Cloud (ISC) Troubleshooting & Validation](/integrations/security-and-identity/sailpoint-isc/sailpoint-identity-security-cloud-isc-troubleshooting-and-validation)

Last updated 2 months ago

- [Prerequisites](#prerequisites)
- [Step-by-Step Configuration](#step-by-step-configuration)
