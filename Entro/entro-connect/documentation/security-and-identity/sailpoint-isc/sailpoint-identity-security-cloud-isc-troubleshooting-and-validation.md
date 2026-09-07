SailPoint Identity Security Cloud (ISC) Troubleshooting & Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/sailpoint-isc/sailpoint-identity-security-cloud-isc-troubleshooting-and-validation.md).
### Post-Connection Validation Checkpoints[#post-connection-validation-checkpoints](#post-connection-validation-checkpoints)

Confirm your active integration health and tracking data visibility using the following checks inside the Entro Console:
GitBook Assistant

1. 

Go to **Management** → **Accounts & Integrations** and select the SailPoint ISC summary item.
GitBook Assistant
1. 

Verify that the current status value shows **Verified**.
GitBook Assistant
1. 

Look at the integration card metadata to verify that the **Last Sync Timestamp** matches recent scheduling parameters and all the mandatory scopes are Granted.
GitBook Assistant
1. 

Check **Employees** inventory to see SailPoint human identities.
GitBook Assistant

### Common Errors and Resolutions[#common-errors-and-resolutions](#common-errors-and-resolutions)

#### `Error` Error During Integration Verification[#error-error-during-integration-verification](#error-error-during-integration-verification)

- 

**Root Cause:** The target API Client was provisioned with an unsupported OAuth 2.0 grant option mapping.
GitBook Assistant
- 

**Fix Action:** Rebuild the API Client configuration inside the SailPoint administration view. Ensure that only **Client Credentials** is selected as the active grant type.
GitBook Assistant

#### `403 Forbidden` Errors (After Access Token Minted)[#id-403-forbidden-errors-after-access-token-minted](#id-403-forbidden-errors-after-access-token-minted)

- 

**Root Cause:** The user account that provisioned the API Client does not possess adequate permission levels, or a necessary functional scope toggle was omitted.
GitBook Assistant
- 

**Fix Action:** Double-check that all 5 mandatory scope items are set to ON.
GitBook Assistant

#### `401 Unauthorized` on Pre-Existing Live Integrations[#id-401-unauthorized-on-pre-existing-live-integrations](#id-401-unauthorized-on-pre-existing-live-integrations)

- 

**Root Cause:** The cached operational access token has expired and cannot be refreshed, typically because the underlying secret key was rotated, modified, or deleted inside SailPoint.
GitBook Assistant
- 

**Fix Action:** Create a fresh Client ID and Client Secret pair from the SailPoint administrative panel, update the integration fields in Entro, and resubmit validation.
GitBook Assistant
[PreviousSailPoint Identity Security Cloud (ISC) Onboarding Guide](/integrations/security-and-identity/sailpoint-isc/sailpoint-identity-security-cloud-isc-onboarding-guide)[NextAggregating Entro NHIs & AI Agents in SailPoint ISC](/integrations/security-and-identity/sailpoint-isc/sailpoint-entro-identities-aggregation)

Last updated 2 months ago

- [Post-Connection Validation Checkpoints](#post-connection-validation-checkpoints)
- [Common Errors and Resolutions](#common-errors-and-resolutions)
