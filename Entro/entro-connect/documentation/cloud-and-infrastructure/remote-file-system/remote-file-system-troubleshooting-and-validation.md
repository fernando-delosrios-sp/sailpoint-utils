Remote File System Troubleshooting And Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/remote-file-system/remote-file-system-troubleshooting-and-validation.md).
## Validation After Onboarding[#validation-after-onboarding](#validation-after-onboarding)
1
#### In the Entro Dashboard[#in-the-entro-dashboard](#in-the-entro-dashboard)

Navigate to **Management → Accounts & Integrations → Remote File System**
GitBook Assistant2
#### Confirm Integration Status[#confirm-integration-status](#confirm-integration-status)

Confirm that the integration status shows **Verified**.
GitBook Assistant3
#### Verify Last Sync[#verify-last-sync](#verify-last-sync)

Open the connection details to verify the **Last Sync Timestamp**.
GitBook Assistant4
#### Check Scan Results[#check-scan-results](#check-scan-results)

Check that results appear in **Secrets Inventory** for scanned shares.
GitBook Assistant
## Common Issues[#common-issues](#common-issues)
IssueCauseResolution

**Access Denied**
GitBook Assistant

Service account lacks read access
GitBook Assistant

Ensure the account has read permissions
GitBook Assistant

**Connection Timeout**
GitBook Assistant

Incorrect IP, port, or network restriction
GitBook Assistant

Verify port and network connectivity
GitBook Assistant

**Invalid Credentials**
GitBook Assistant

Wrong username or password
GitBook Assistant

Re‑enter the correct domain and credentials
GitBook Assistant

**Worker Group Offline**
GitBook Assistant

Connector not active
GitBook Assistant

Restart connector or contact support
GitBook Assistant

Security Notes
GitBook Assistant

- 

All SMB+SFTP operations are **read‑only**.
GitBook Assistant
- 

Data is encrypted using **AES‑256**.
GitBook Assistant
- 

Communication secured via **TLS 1.2+**.
GitBook Assistant
- 

Credentials stored securely in Entro.
GitBook Assistant
[PreviousWinRM Onboarding](/integrations/cloud-and-infrastructure/remote-file-system/winrm-onboarding)[NextBitBucket](/integrations/code-and-ci-cd/bitbucket)

Last updated 4 months ago

- [Validation After Onboarding](#validation-after-onboarding)
- [Common Issues](#common-issues)
