CrowdStrike Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/crowdstrike/crowdstrike-onboarding.md).

Follow these steps to connect your CrowdStrike environment with Entro.
GitBook Assistant

**Prerequisites**
GitBook Assistant

- 

CrowdStrike administrator access
GitBook Assistant
- 

Access to **Support and Resources → **[**API Clients and Keys**](https://falcon.us-2.crowdstrike.com/api-clients-and-keys/clients)
GitBook Assistant
- 

Generate **Client ID** and **Client Secret**
GitBook Assistant

### Step‑by‑Step Configuration[#step-by-step-configuration](#step-by-step-configuration)
1
#### Log in to CrowdStrike Falcon Console[#log-in-to-crowdstrike-falcon-console](#log-in-to-crowdstrike-falcon-console)

Log in as an administrator.
GitBook Assistant2
#### Open API Clients and Keys[#open-api-clients-and-keys](#open-api-clients-and-keys)

Navigate to **Support and Resources → **[**API Clients and Keys**](https://falcon.us-2.crowdstrike.com/api-clients-and-keys/clients).
GitBook Assistant3
#### Create API Client[#create-api-client](#create-api-client)

Click **Create API Client** in the top‑right corner.
GitBook Assistant4
#### Name the Client[#name-the-client](#name-the-client)

Under **Client Name**, enter `Entro Security Integration`.
GitBook Assistant5
#### Assign Scopes[#assign-scopes](#assign-scopes)

Assign the following scopes:
GitBook Assistant

- 

Hosts – Read `(All features)`
GitBook Assistant
- 

Real Time Response – Read `(AI Agents)`
GitBook Assistant
- 

NGSIEM - Read & Write `(AI Agents)`
GitBook Assistant
- 

Identity Protection GraphQL – Write `(Active Directory NHIs)`
GitBook Assistant
- 

Identity Protection Entities – Read `(Active Directory NHIs)`
GitBook Assistant
- 

Identity Protection Detections – Read `(Active Directory NHIs)`
GitBook Assistant
- 

Identity Protection Timeline – Read`(Active Directory NHIs)`
GitBook Assistant
6
#### Create and copy credentials[#create-and-copy-credentials](#create-and-copy-credentials)

Click **Create** and copy both **Client ID** and **Client Secret** values.
GitBook Assistant7
#### Add CrowdStrike account in Entro[#add-crowdstrike-account-in-entro](#add-crowdstrike-account-in-entro)

In Entro, go to **Management → Accounts & Integrations → Add New Account → CrowdStrike**.
GitBook Assistant8
#### Enter credentials in Entro[#enter-credentials-in-entro](#enter-credentials-in-entro)

Paste the credentials into the onboarding form fields:
GitBook Assistant

- 

**Nickname**: Name of this integration instance
GitBook Assistant
- 

**Client ID**: From previous step
GitBook Assistant
- 

**Client Secret**: From previous step
GitBook Assistant
- 

**Worker Group (Connector)**: Select appropriate group
GitBook Assistant
9
#### Connect and verify[#connect-and-verify](#connect-and-verify)

Click **Connect**. The status should display **Verified** once validated.
GitBook Assistant[PreviousCrowdStrike](/integrations/security-and-identity/crowdstrike)[NextCrowdStrike Troubleshooting And Validation](/integrations/security-and-identity/crowdstrike/crowdstrike-troubleshooting-and-validation)

Last updated 2 months ago
