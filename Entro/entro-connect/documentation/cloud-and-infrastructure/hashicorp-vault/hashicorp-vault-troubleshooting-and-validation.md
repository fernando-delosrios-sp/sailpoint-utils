HashiCorp Vault Troubleshooting And Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/hashicorp-vault/hashicorp-vault-troubleshooting-and-validation.md).

This section provides validation steps and troubleshooting procedures for the HashiCorp Vault integration.
GitBook Assistant
## Validation Steps[#validation-steps](#validation-steps)
1
#### Verify connection in the dashboard[#verify-connection-in-the-dashboard](#verify-connection-in-the-dashboard)

In the Entro Dashboard, navigate to Management → Accounts & Integrations → HashiCorp Vault and confirm the connection status displays **Verified**.
GitBook Assistant2
#### Check last synchronization[#check-last-synchronization](#check-last-synchronization)

Ensure that **Last Synchronization Timestamp** is recent.
GitBook Assistant3
#### Confirm discovered secrets[#confirm-discovered-secrets](#confirm-discovered-secrets)

Check for discovered secrets under **Vault Management → Vaulted Secrets**.
GitBook Assistant
## Common Issues and Resolutions[#common-issues-and-resolutions](#common-issues-and-resolutions)
IssuePossible CauseResolution

“Permission denied”
GitBook Assistant

Insufficient ACL permissions
GitBook Assistant

Verify ACL includes list, read, and update capabilities
GitBook Assistant

Token expired
GitBook Assistant

Token TTL reached
GitBook Assistant

Renew or recreate token with `renewable=1`
GitBook Assistant

Connection timeout
GitBook Assistant

Network restrictions
GitBook Assistant

Ensure Vault API is reachable via HTTPS (port 8200)
GitBook Assistant

Missing findings
GitBook Assistant

KV engine access missing
GitBook Assistant

Add KV2 metadata permissions per refined ACL
GitBook Assistant
## Advanced Diagnostics[#advanced-diagnostics](#advanced-diagnostics)

- 

Review **Entro Worker logs** for Vault sync events and response codes
GitBook Assistant
- 

Check **Vault audit logs** for token activity or permission denials
GitBook Assistant
- 

Ensure Vault token policies match Entro’s ACL configuration
GitBook Assistant
[PreviousHashiCorp Vault Onboarding](/integrations/cloud-and-infrastructure/hashicorp-vault/hashicorp-vault-onboarding)[NextHashiCorp Vault Permissions Reference](/integrations/cloud-and-infrastructure/hashicorp-vault/hashicorp-vault-permissions-reference)

Last updated 1 month ago

- [Validation Steps](#validation-steps)
- [Common Issues and Resolutions](#common-issues-and-resolutions)
- [Advanced Diagnostics](#advanced-diagnostics)
