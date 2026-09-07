Link to Entro | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/azure/manual-policy-creation-overview/link-to-entro.md).

This section explains how to securely connect your **Azure App Registration** to **Entro Security**. This final step allows Entro to authenticate with Azure APIs and begin **Non-Human Identity (NHI)** scanning across your subscriptions.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

In the Entro Dashboard, navigate to: **Management → Accounts & Integrations → Add New Account (top right) → Microsoft Ecosystem**
GitBook Assistant
## Step 1 - Gather Required Parameters[#step-1-gather-required-parameters](#step-1-gather-required-parameters)

Collect the following values from your previous setup steps:
GitBook AssistantParameterSource

**Tenant ID**
GitBook Assistant

Azure Portal → Entra ID → Overview
GitBook Assistant

**Client ID**
GitBook Assistant

Azure Portal → App Registration → Overview
GitBook Assistant

**Client Secret**
GitBook Assistant

Azure Portal → Certificates & Secrets → Client Secret Value
GitBook Assistant

**Subscription ID**
GitBook Assistant

Azure Portal → Subscriptions → Overview
GitBook Assistant

Ensure the client secret is still valid - expired secrets will cause authentication failure.
GitBook Assistant
## Step 2 - Add Account in Entro[#step-2-add-account-in-entro](#step-2-add-account-in-entro)

Follow these steps in the Entro Dashboard:
GitBook Assistant1
#### Navigate to Microsoft Ecosystem[#navigate-to-microsoft-ecosystem](#navigate-to-microsoft-ecosystem)

Go to Management → Accounts & Integrations → Add New Account (top right) → Microsoft Ecosystem.
GitBook Assistant2
#### Select Manual Onboarding[#select-manual-onboarding](#select-manual-onboarding)

Choose the Manual Onboarding option.
GitBook Assistant3
#### Enter Parameters[#enter-parameters](#enter-parameters)

Enter the Tenant ID, Client ID, Client Secret, and Subscription ID collected in Step 1.
GitBook Assistant4
#### Validate Connection[#validate-connection](#validate-connection)

Click **Validate Connection**.
GitBook Assistant5
#### Add Account[#add-account](#add-account)

Once validation succeeds, click **Add Account**.
GitBook Assistant
### Connection Payload Example[#connection-payload-example](#connection-payload-example)

## Step 3 - Validate Connection[#step-3-validate-connection](#step-3-validate-connection)

After linking, Entro automatically tests access using the following APIs:
GitBook AssistantAPIPurpose

**Microsoft Graph API**
GitBook Assistant

Identity and directory enumeration
GitBook Assistant

**Azure Resource Manager (ARM)**
GitBook Assistant

Subscription and resource metadata
GitBook Assistant

**Key Vault API**
GitBook Assistant

Key Vault enumeration for secret scanning
GitBook Assistant

Expected response: `Validation Successful`
GitBook Assistant
## Step 4 - Initial Sync and Verification[#step-4-initial-sync-and-verification](#step-4-initial-sync-and-verification)

- 

Entro begins the initial metadata sync within **2–5 minutes**.
GitBook Assistant
- 

Go to **Accounts & Integrations → Microsoft Ecosystem → Overview** to monitor status.
GitBook Assistant
- 

Confirm that resources, service principals, and Key Vaults appear in the **NHI Inventory** within the Entro Dashboard.
GitBook Assistant

## Troubleshooting[#troubleshooting](#troubleshooting)
Common issues and resolutions[#common-issues-and-resolutions](#common-issues-and-resolutions)IssueResolution

**Invalid credentials**
GitBook Assistant

Verify client secret and tenant ID.
GitBook Assistant

**Insufficient permissions**
GitBook Assistant

Ensure Reader and Key Vault Reader roles are assigned.
GitBook Assistant

**Timeout or 403 error**
GitBook Assistant

Check firewall configuration and outbound egress rules.
GitBook Assistant
## Security & Compliance[#security-and-compliance](#security-and-compliance)
Security and compliance details[#security-and-compliance-details](#security-and-compliance-details)

- 

All communication between Entro and Azure occurs over **TLS 1.2+**.
GitBook Assistant
- 

Azure credentials are encrypted using **AES-256** and stored **transiently** during validation.
GitBook Assistant
- 

Entro performs **no write or delete operations** on Azure configurations or roles.
GitBook Assistant
- 

All activity is logged and auditable within Entro's internal telemetry pipeline.
GitBook Assistant
- 

Integration complies with **SOC 2 Type II**, **ISO 27001**, and **GDPR** standards.
GitBook Assistant

Last updated 4 months ago

- [Navigation Path](#navigation-path)
- [Step 1 - Gather Required Parameters](#step-1-gather-required-parameters)
- [Step 2 - Add Account in Entro](#step-2-add-account-in-entro)
- [Connection Payload Example](#connection-payload-example)
- [Step 3 - Validate Connection](#step-3-validate-connection)
- [Step 4 - Initial Sync and Verification](#step-4-initial-sync-and-verification)
- [Troubleshooting](#troubleshooting)
- [Security & Compliance](#security-and-compliance)
GitBook AssistantAskCopy
```
{
  "tenant_id": "<TENANT_ID>",
  "client_id": "<CLIENT_ID>",
  "client_secret": "<CLIENT_SECRET>",
  "subscription_id": "<SUBSCRIPTION_ID>"
}
```
