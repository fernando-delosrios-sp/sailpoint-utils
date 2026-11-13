# Microsoft Azure & Entra ID Technical Reference

Technical reference for configuring **SailPoint Fabric** (Microsoft Entra ID connector), **Entra CIEM**, and **Entro** integrations via `Connect-SailPointAzure` and `Azure.ps1`.

---

## 1. Overview & Architecture

SailPoint Connect provisions and audits Microsoft Entra ID integrations using modern **Microsoft Graph APIs** (replacing deprecated Azure AD Graph workflows).

- **Authentication Model:** Confidential client application registration with Client ID and Client Secret (or certificate).
- **Scope Model:** Granular Microsoft Graph application permissions with tenant-wide admin consent.
- **Directory Roles:** Automated assignment of directory roles such as `User Administrator` for account lifecycle and password operations.

---

## 2. Prerequisites

- PowerShell 7+ (`pwsh`)
- Microsoft Graph PowerShell modules (`Microsoft.Graph.Authentication`, `Microsoft.Graph.Applications`, `Microsoft.Graph.Identity.DirectoryManagement`)
- An Entra sign-in holding:
  - **Application Administrator** (or Cloud Application Administrator)
  - **Privileged Role Administrator** (to grant admin consent and assign directory roles)
  - Or **Global Administrator**

---

## 3. Permissions Breakdown

### Required Permissions (Always Granted)

When running in `Granular` mode (default), the following application permissions are granted:

| Microsoft Graph Permission | Purpose |
| :--- | :--- |
| `User.Invite.All` | Create and invite B2B guest users |
| `User.Read.All` | Account aggregation, delta queries, and group memberships |
| `User.ReadWrite.All` | Create, update, enable, disable, and delete users; license assignment |
| `User.EnableDisableAccount.All` | Disable accounts during deprovisioning |
| `User-PasswordProfile.ReadWrite.All`| Reset and change user passwords |
| `Organization.Read.All` | Read tenant subscription SKUs and license packs |
| `Group.Read.All` | Aggregate security and Microsoft 365 groups |
| `Group.ReadWrite.All` | Create, update, and manage group memberships |
| `RoleManagement.Read.Directory` | Aggregate directory roles and assignments |
| `RoleManagement.ReadWrite.Directory`| Assign and remove directory roles |
| `Application.Read.All` | Read enterprise applications and service principals |
| `AppRoleAssignment.ReadWrite.All` | Assign users to enterprise application roles |
| `DelegatedPermissionGrant.Read.All` | Aggregate OAuth consented permissions |

### Optional Feature Packs (`-Feature`)

| Feature Pack | Permissions Granted / Configured | Purpose |
| :--- | :--- | :--- |
| `AccessPackages` | `EntitlementManagement.Read.All`, `EntitlementManagement.ReadWrite.All` | Entra ID Entitlement Management catalog governance |
| `MfaManagement` | `UserAuthenticationMethod.Read.All`, `UserAuthenticationMethod.ReadWrite.All` | Govern FIDO2, Authenticator, and phone auth methods |
| `Ciem` | `PrivilegedAccess.Read.AzureADGroup`, `PrivilegedAssignmentSchedule.Read.AzureADGroup`, `PrivilegedEligibilitySchedule.Read.AzureADGroup` | CIEM analysis for PIM-managed groups |
| `NhiDiscovery` | `AuditLog.Read.All`, `Device.Read.All` | Non-human identity and device posture discovery |
| `CopilotDiscovery` | `AiEnterpriseInteraction.Read.All`, `Reports.Read.All`, `ExternalConnection.Read.All`, `AppCatalog.Read.All` | Discovers Azure AI Foundry and Copilot Studio agents |
| `Agent365` | Delegated: `CopilotPackages.Read.All`, `CopilotPackages.ReadWrite.All`, `User.Read`, `offline_access` | Microsoft Agent 365 catalog governance and refresh token |
| `DefenderHunting` | `Machine.Read.All`, `AdvancedQuery.Read.All`, `ThreatHunting.Read.All` | Microsoft Defender XDR integration |

---

## 4. AI Agent Governance: Azure AI Foundry & Copilot Studio

SailPoint Agentic Fabric discovers non-human and AI identities across the Microsoft ecosystem. Each plane requires distinct access:

### Azure AI Foundry
Foundry agents run on Azure Resource Manager (ARM):
1. **Azure Subscriptions:** The app registration requires the **Reader** and **Cognitive Services Data Contributor (Preview)** roles on every subscription containing an AI Foundry hub.
2. **Delegated API:** Requires `user_impersonation` on the Azure Service Management API.

### Microsoft Copilot Studio (Dataverse)
Copilot Studio agents reside inside Microsoft Dataverse:
1. **Application User:** The app registration must be added as an Application User inside each Power Platform environment.
2. **Security Role:** Requires a custom security role granting **Organization (`Global`) depth** Read on `bot` and `botcomponent` tables.
   > [!WARNING]
   > Do **not** use the built-in `Bot Viewer` role. It grants `Basic` depth only, which restricts reads to bots owned by the caller. Since the app registration owns no bots, it will return zero bots without error.
3. **Automated Setup:** Running with `-Feature CopilotDiscovery` prompts the wizard to discover Power Platform environments and provision the `SailPoint BotReader` role automatically.

### Microsoft Agent 365 Refresh Token
The Agent 365 catalog endpoint (`/beta/copilot/admin/catalog/packages`) only accepts **delegated user tokens**.
- Running with `-Feature Agent365` opens an interactive browser flow to sign in an **AI Administrator** or **Global Administrator** and capture an offline refresh token.
- Paste this token into **Machine Identity Governance Settings → Refresh Token** in the ISC source.

---

## 5. Parameterized CLI Examples

```powershell
# Headless run: Create or update app with Granular permissions and MFA management
Connect-SailPointAzure `
  -TenantId 'contoso.onmicrosoft.com' `
  -ApplicationName 'SailPoint ISC Entra ID' `
  -Feature AccessPackages,MfaManagement `
  -DirectoryRole UserAdministrator `
  -Action Run

# Generate offline review script for change ticket
Connect-SailPointAzure `
  -TenantId 'contoso.onmicrosoft.com' `
  -ApplicationName 'SailPoint ISC Entra ID' `
  -Feature CopilotDiscovery `
  -Action BuildScript
```

---

## 6. Troubleshooting

| Symptom | Cause and Fix |
| :--- | :--- |
| `Microsoft Agent 365 aggregation requires a refresh token` | Agent 365 is enabled but no refresh token was supplied. Re-run with `-Feature Agent365` and paste the token into Machine Identity Governance Settings. |
| Copilot Studio aggregates 0 agents | The assigned Dataverse role has `Basic` depth instead of `Global`. Re-run with `Connect-SailPointAzure -Feature CopilotDiscovery` to create the `SailPoint BotReader` role with `Global` read depth. |
| Foundry agents never appear | App registration lacks ARM RBAC. Grant `Reader` and `Cognitive Services Data Contributor (Preview)` on the subscriptions. |
| `400 Bad Request` during delta aggregation | Delta aggregation is enabled alongside a User Filter or Service Principal Filter. Graph delta endpoints reject `$filter`. Remove the filter or disable delta aggregation. |
| `AADSTS7000215: Invalid client secret` | Client secret has not replicated yet across Entra regions. Wait 60 seconds and retry. |
