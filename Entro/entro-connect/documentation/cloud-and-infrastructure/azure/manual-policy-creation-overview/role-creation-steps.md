Role Creation Steps | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/azure/manual-policy-creation-overview/role-creation-steps.md).

This page explains how to create and assign the **EntroSecurityRole**, which grants Entro Security the required **read-only access** to Azure resources for discovery, metadata analysis, and Non-Human Identity (NHI) monitoring.
GitBook Assistant

This role follows strict least-privilege principles - it allows only read operations and selected metadata retrievals. No write or delete actions are used or required.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

In the Entro Dashboard, navigate to: **Management → Accounts & Integrations → Add New Account (top right) → Microsoft Ecosystem**
GitBook Assistant1
#### Create the Custom Role Definition[#create-the-custom-role-definition](#create-the-custom-role-definition)

You can create the Entro Security role using the **Azure Portal** or **Azure CLI**.
GitBook Assistant

**Option A: Create via Azure Portal**
GitBook Assistant

1. 

Go to the [Azure Portal](https://portal.azure.com/).
GitBook Assistant
1. 

Navigate to **Subscriptions → [Your Subscription] → Access control (IAM)**.
GitBook Assistant
1. 

Click **+ Add → Add custom role**.
GitBook Assistant
1. 

Choose **Start from scratch** and name the role **EntroSecurityRole**.
GitBook Assistant
1. 

In the **Permissions** tab, click **Add permissions**, then search for and include only **Read** operations.
GitBook Assistant
1. 

Under **Assignable scopes**, select the subscriptions to which the role will apply.
GitBook Assistant
1. 

Review and **Create** the role.
GitBook Assistant
2
#### Create via Azure CLI[#create-via-azure-cli](#create-via-azure-cli)

1. 

Create a JSON file named `EntroSecurityRole.json` with the following content:
GitBook Assistant
EntroSecurityRole.jsonGitBook AssistantAskCopy
```
{
  "Name": "EntroSecurityRole",
  "IsCustom": true,
  "Description": "Provides Entro Security read-only visibility into Azure resources, Key Vaults, and configuration stores.",
  "Actions": [
    "*/read",
    "Microsoft.Authorization/*/read",
    "Microsoft.Insights/alertRules/*",
    "Microsoft.Resources/deployments/*/read",
    "Microsoft.Resources/subscriptions/resourceGroups/read",
    "Microsoft.Support/*",
    "Microsoft.KeyVault/checkNameAvailability/read",
    "Microsoft.KeyVault/deletedVaults/read",
    "Microsoft.KeyVault/locations/*/read",
    "Microsoft.KeyVault/vaults/*/read",
    "Microsoft.KeyVault/operations/read",
    "Microsoft.Web/sites/config/list/Action"
  ],
  "NotActions": [
    "Microsoft.OperationalInsights/workspaces/sharedKeys/read"
  ],
  "DataActions": [
    "Microsoft.KeyVault/vaults/*/read",
    "Microsoft.KeyVault/vaults/secrets/readMetadata/action",
    "Microsoft.AppConfiguration/configurationStores/keyValues/read",
    "Microsoft.AppConfiguration/configurationStores/snapshots/read"
  ],
  "NotDataActions": [
    "Microsoft.KeyVault/vaults/secrets/getSecret/action"
  ],
  "AssignableScopes": [
    "/subscriptions/<your_subscription_id>"
  ]
}
```

1. 

Run the following command in PowerShell or Azure CLI to create the role:
GitBook Assistant
Create roleGitBook AssistantAskCopy
```
az role definition create --role-definition EntroSecurityRole.json
```

1. 

Confirm creation with:
GitBook Assistant
List roleGitBook AssistantAskCopy
```
az role definition list --name "EntroSecurityRole"
```

Expected output includes the role name, ID, and assignable scopes.
GitBook Assistant3
#### Assign the Role to the Entro App Registration[#assign-the-role-to-the-entro-app-registration](#assign-the-role-to-the-entro-app-registration)

You can assign the newly created **EntroSecurityRole** using either the Azure Portal or CLI.
GitBook Assistant

**Option A: Azure Portal**
GitBook Assistant

1. 

In the Azure Portal, go to **Azure Active Directory → App registrations**.
GitBook Assistant
1. 

Select the **EntroSecurityIntegration** app created earlier.
GitBook Assistant
1. 

Click **Managed application in local directory**.
GitBook Assistant
1. 

Under **Users and groups**, click **Add assignment**.
GitBook Assistant
1. 

Choose the **EntroSecurityRole** you just created.
GitBook Assistant
1. 

Click **Save** to complete the assignment.
GitBook Assistant

**Option B: Azure CLI**
GitBook Assistant

Run the following command in PowerShell or Azure CLI to create the role assignment:
GitBook Assistant

1. 

Go to [https://portal.azure.com](https://portal.azure.com).
GitBook Assistant
1. 

Click the **Cloud Shell (>_)** icon at the top-right of the portal header.
GitBook Assistant
1. 

Choose **Bash** (not PowerShell).
GitBook Assistant
Assign role (CLI)GitBook AssistantAskCopy
```
az role assignment create --assignee <app_client_id> --role "EntroSecurityRole" --subscription <subscription_id>
```

Replace `<app_client_id>` and `<subscription_id>` with your actual values.
GitBook Assistant4
#### Validate Role Assignment[#validate-role-assignment](#validate-role-assignment)

To confirm that the role was successfully applied, run:
GitBook AssistantValidate assignmentGitBook AssistantAskCopy
```
az role assignment list --assignee <app_client_id> --output table
```

Expected output:
GitBook AssistantExpected outputGitBook AssistantAskCopy
```
Role name: EntroSecurityRole
Scope: /subscriptions/<your_subscription_id>
```

If the role does not appear, re-run the command or verify the assignment under **Access control (IAM)** in the Azure Portal.
GitBook Assistant

Security Notes
GitBook Assistant

- 

The Entro role enforces **read-only** operations and blocks write or delete actions.
GitBook Assistant
- 

Entro uses these permissions exclusively to scan for exposed secrets and metadata.
GitBook Assistant
- 

Tokens and credentials are encrypted using **AES-256** and transmitted over **TLS 1.2+**.
GitBook Assistant
- 

The role can be revoked anytime without affecting other Azure resources.
GitBook Assistant
- 

This configuration aligns with **SOC 2 Type II**, **ISO 27001**, and **GDPR** standards.
GitBook Assistant

Last updated 4 months ago
