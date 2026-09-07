Troubleshooting & Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/ai-and-agents/microsoft-copilot-studio/troubleshooting-and-validation.md).
## Post-Connection Validation Steps[#post-connection-validation-steps](#post-connection-validation-steps)

### 1. Verification in Entro Console[#id-1.-verification-in-entro-console](#id-1.-verification-in-entro-console)

- 

Navigate to **Management** → **Accounts & Integrations** → **Microsoft Copilot Studio**.
GitBook Assistant
- 

Ensure the active integration card displays a status of **Verified**.
GitBook Assistant
- 

Confirm the **Last Sync** timestamp updates correctly following ingestion cycles.
GitBook Assistant

### 2. Data Visibility Inspections[#id-2.-data-visibility-inspections](#id-2.-data-visibility-inspections)

- 

Navigate to the **Inventory** and **Detections** screens.
GitBook Assistant
- 

Verify that targeted Power Platform environments, application users, and scanned asset metadata match actual numbers.
GitBook Assistant
- 

Search for a known connection reference or agent identity to confirm contextual attributes are correctly populated.
GitBook Assistant

## Common Issues and Resolutions[#common-issues-and-resolutions](#common-issues-and-resolutions)

### "Forbidden" or "Unauthorized" Errors for Specific Environments[#forbidden-or-unauthorized-errors-for-specific-environments](#forbidden-or-unauthorized-errors-for-specific-environments)

- 

**Cause:** The targeted environment uses an environment-level Security Group restriction, and the Global Admin account running the script is not a designated member.
GitBook Assistant
- 

**Fix:** Open the Power Platform Admin Center (PPAC), select the affected environment, drill into **Details** -> **Security group**. Temporarily add your administrator account or adjust the block policy. Re-run the script using the `-OnlyEnvironment` parameter.
GitBook Assistant

### "Managed Environment" Policy Denials[#managed-environment-policy-denials](#managed-environment-policy-denials)

- 

**Cause:** Strict tenant policies applied to Managed Environments prevent automated creation or manipulation of Application Users via API.
GitBook Assistant
- 

**Fix:** Access the environment controls in PPAC, temporarily relax the restrictions surrounding programmatic user provisioning, execute the script, and re-enable the policy once the application user is safely populated.
GitBook Assistant

### Connection Test Failure in Entro UI[#connection-test-failure-in-entro-ui](#connection-test-failure-in-entro-ui)

- 

**Cause:** Invalid credential strings or incomplete Entra app replication.
GitBook Assistant
- 

**Fix:**
GitBook Assistant

1. 

Ensure you copied the actual **Value** of the Client Secret, not the Secret ID.
GitBook Assistant
1. 

Confirm the secret string has not passed its expiration window.
GitBook Assistant
1. 

Validate that Admin Consent was successfully applied to all checked rows inside the Entra ID portal.
GitBook Assistant
1. 

Ensure the provisioning script completed successfully for at least one database environment.
GitBook Assistant

### Script Fails to Install MSAL.PS[#script-fails-to-install-msal.ps](#script-fails-to-install-msal.ps)

- 

**Cause:** Network security infrastructure or local host configurations block communication with the public PowerShell Gallery registry.
GitBook Assistant
- 

**Fix:** Explicitly bypass or run the manual installation step beforehand:
GitBook Assistant

If restrictions persist, update internal firewall allow-lists to permit communication with `https://www.powershellgallery.com`.
GitBook Assistant

- [Post-Connection Validation Steps](#post-connection-validation-steps)
- [1. Verification in Entro Console](#id-1.-verification-in-entro-console)
- [2. Data Visibility Inspections](#id-2.-data-visibility-inspections)
- [Common Issues and Resolutions](#common-issues-and-resolutions)
- ["Forbidden" or "Unauthorized" Errors for Specific Environments](#forbidden-or-unauthorized-errors-for-specific-environments)
- ["Managed Environment" Policy Denials](#managed-environment-policy-denials)
- [Connection Test Failure in Entro UI](#connection-test-failure-in-entro-ui)
- [Script Fails to Install MSAL.PS](#script-fails-to-install-msal.ps)
GitBook AssistantAskCopy
```
Install-Module MSAL.PS -Scope CurrentUser -Force -AcceptLicense
```
