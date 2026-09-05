OCI Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/oci/oci-onboarding.md).

This section describes how to connect **Oracle Cloud Infrastructure** to **Entro Security** using an IAM user and read-only access policies.
GitBook Assistant
### Navigation Path[#navigation-path](#navigation-path)

**Management → Accounts & Integrations → Add New Account (top right) → Oracle Cloud Infrastructure**
GitBook Assistant
### Prerequisites[#prerequisites](#prerequisites)

Before starting, ensure you have:
GitBook Assistant

- 

An OCI account with permissions to create IAM Users, Groups, and Policies.
GitBook Assistant
- 

The OCI home region name (e.g., `us-ashburn-1`).
GitBook Assistant
1
#### Create IAM User and Group[#create-iam-user-and-group](#create-iam-user-and-group)

1. 

**Create User:** In the OCI Console, navigate to **Identity & Security → Domains → User Management**. Create a user named `entro-reader`.
GitBook Assistant

1. 

First Name: `entro`
GitBook Assistant
1. 

Last Name: `reader`
GitBook Assistant
1. 

Uncheck the **Use the email address as the username**
GitBook Assistant
1. 

Username: `entro-reader` 
GitBook Assistant
1. 

Click on Create
GitBook Assistant

1. 

**Create Group:** Navigate to **Identity & Security → Domains → User Management**. Create a group named `entro-readers` and add the `entro-reader` user to it.
GitBook Assistant
2
#### Configure IAM Policies[#configure-iam-policies](#configure-iam-policies)

Navigate to **Identity & Security → Policies** and create a new policy.
GitBook Assistant

1. 

Give name and description to the policy.
GitBook Assistant
1. 

Click on **Show manual editor** and paste the below statements.
GitBook Assistant
GitBook AssistantAskCopy
```
Allow group entro-readers to inspect compartments in tenancy
Allow group entro-readers to inspect users in tenancy
Allow group entro-readers to inspect keys in tenancy
Allow group entro-readers to inspect vaults in tenancy
Allow group entro-readers to read secret-family in tenancy
```

- 

Note to enter the group name, created in step 2, at the right place in the statements.
GitBook Assistant
3
#### Generate API Signing Key[#generate-api-signing-key](#generate-api-signing-key)

1. 

Go to the **User Management** page and click on `entro-reader` user.
GitBook Assistant
1. 

Under **API Keys → Add API Key**.
GitBook Assistant
1. 

Choose **Generate API Key Pair**.
GitBook Assistant
1. 

**Download Private Key:** Save the `.pem` file securely. This is the only time it is available for download.
GitBook Assistant
1. 

Click **Add**. Copy the configuration preview values (Tenancy OCID, User OCID, Fingerprint, and Region).
GitBook Assistant
4
#### Connect to Entro[#connect-to-entro](#connect-to-entro)

1. 

Navigate: **Management → Accounts & Integrations → Add New Account (top right) → Oracle Cloud Infrastructure**.
GitBook Assistant
1. 

Fill in the following fields:
GitBook Assistant

- 

**Environment Nickname:** A descriptive name (e.g., `OCI-PROD`).
GitBook Assistant
- 

**Tenancy OCID:** Your OCI Tenancy identifier.
GitBook Assistant
- 

**User OCID:** The OCID of the `entro-reader` user.
GitBook Assistant
- 

**Domain OCID (Optional):** The domain OCID where the user and group created on. Can be retrieved from the **Domains** inventory (**Identity & Security → Domains**).
GitBook Assistant
- 

**Region:** Your OCI home region.
GitBook Assistant
- 

**API Key Fingerprint:** The API Key fingerprint from step 3.
GitBook Assistant
- 

**Private Key (PEM):** Paste the full content of the downloaded `.pem` file or upload the file.
GitBook Assistant
- 

**Worker Group (Connector):** Select the appropriate Worker Group handling Vault scans.
GitBook Assistant

1. 

Click **Create Account**.
GitBook Assistant
[PreviousOracle Cloud Infrastructure (OCI)](/integrations/cloud-and-infrastructure/oci)[NextOCI Troubleshooting And Validation](/integrations/cloud-and-infrastructure/oci/oci-troubleshooting-and-validation)

Last updated 2 months ago

- [Navigation Path](#navigation-path)
- [Prerequisites](#prerequisites)
