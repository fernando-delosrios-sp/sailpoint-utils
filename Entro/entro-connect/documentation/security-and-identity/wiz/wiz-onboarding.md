Wiz Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/wiz/wiz-onboarding.md).

Follow these steps to integrate **Wiz** with **Entro Security** and enable unified NHI and data visibility through DSPM insights.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

**Management → Accounts & Integrations → Add New Account (top right) → Wiz**
GitBook Assistant
## Step 1 - Create a Wiz Service Account[#step-1-create-a-wiz-service-account](#step-1-create-a-wiz-service-account)

In Wiz, create a **Service Account** with the following permissions:
GitBook AssistantPermissionDescription

**read:data_findings**
GitBook Assistant

Allows Entro to retrieve sensitive data classification results
GitBook Assistant

**create:reports**
GitBook Assistant

Enables Entro to generate DSPM findings reports
GitBook Assistant

**read:reports**
GitBook Assistant

Grants Entro access to retrieve generated DSPM reports
GitBook Assistant

Entro only retrieves **DATA_SCAN** report types for DSPM. No other Wiz data types are accessed or stored.
GitBook Assistant1
#### Retrieve Client ID and Client Secret[#retrieve-client-id-and-client-secret](#retrieve-client-id-and-client-secret)

1. 

Navigate to **Wiz → Service Accounts**.
GitBook Assistant
1. 

Copy the **Client ID** and **Client Secret** for the account created above.
GitBook Assistant
1. 

Store them securely - these will be used to connect to Entro.
GitBook Assistant
2
#### Connect Wiz to Entro Security[#connect-wiz-to-entro-security](#connect-wiz-to-entro-security)

1. 

In the Entro Dashboard, open **Management → Accounts & Integrations → Add New Account → Wiz**
GitBook Assistant
1. 

Fill in the required fields:
GitBook Assistant
FieldDescription

**Nickname**
GitBook Assistant

Enter a descriptive name (e.g., `my-wiz-project`)
GitBook Assistant

**Wiz Service Account Client ID**
GitBook Assistant

Paste the Client ID copied from Wiz
GitBook Assistant

**Wiz Service Account Client Secret**
GitBook Assistant

Paste the Client Secret copied from Wiz
GitBook Assistant

1. 

Click **Create Account**.
GitBook Assistant
1. 

Entro will automatically validate the credentials and confirm connection status as **Verified**.
GitBook Assistant

## Validation and Scanning[#validation-and-scanning](#validation-and-scanning)

Once connected:
GitBook Assistant

- 

Entro authenticates via the Wiz API using the provided credentials
GitBook Assistant
- 

DSPM data findings are retrieved from Wiz and correlated with associated NHIs
GitBook Assistant
- 

New insights will appear in **NHI Inventory → NHIs with DSPM Tags**. The **Permissions and Lineage** map will be enriched with `Data Access severity`, with the **Wiz** start icon. 
GitBook Assistant
[PreviousWiz](/integrations/security-and-identity/wiz)[NextWiz Troubleshooting And Validation](/integrations/security-and-identity/wiz/wiz-troubleshooting-and-validation)

Last updated 2 months ago

- [Navigation Path](#navigation-path)
- [Step 1 - Create a Wiz Service Account](#step-1-create-a-wiz-service-account)
- [Validation and Scanning](#validation-and-scanning)
