Okta Troubleshooting & Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/okta/okta-troubleshooting-and-validation.md).
## Validation Steps After Connection[#validation-steps-after-connection](#validation-steps-after-connection)
1
#### Confirm Connection Status[#confirm-connection-status](#confirm-connection-status)

Navigate to **Management → Accounts & Integrations** and confirm the Okta integration status displays **Verified**.
GitBook Assistant2
#### Check Last Sync[#check-last-sync](#check-last-sync)

Review the **Last Verified Timestamp** to confirm recent activity.
GitBook Assistant3
#### Review NHI Inventory[#review-nhi-inventory](#review-nhi-inventory)

Navigate to **NHI Inventory** and filter by **Okta**. Confirm that applications, client credentials, and role assignments are visible.
GitBook Assistant
## Common Issues[#common-issues](#common-issues)
IssueCauseResolution

401 Unauthorized
GitBook Assistant

Invalid Client ID or public key mismatch
GitBook Assistant

Re-copy the public key from Entro and re-paste it into the Okta app
GitBook Assistant

403 Forbidden
GitBook Assistant

Missing API scopes or insufficient admin role
GitBook Assistant

Verify all six scopes are granted and Super Administrator is assigned
GitBook Assistant

Missing API grant data
GitBook Assistant

Read-Only or custom role assigned instead of Super Admin
GitBook Assistant

Switch to Super Administrator for full NHI visibility
GitBook Assistant

Missing audit logs
GitBook Assistant

Report Administrator role not assigned
GitBook Assistant

Assign Report Administrator alongside the custom or Super Admin role
GitBook Assistant

Connection timeout
GitBook Assistant

Firewall blocking outbound traffic
GitBook Assistant

Verify connector health and allow outbound HTTPS (port 443) to Okta
GitBook Assistant

Partial user data
GitBook Assistant

Incorrect resource set scope
GitBook Assistant

Ensure the Entro Resource Set includes All Users and All Applications
GitBook Assistant
## FAQ[#faq](#faq)
Do I need Super Administrator permissions?[#do-i-need-super-administrator-permissions](#do-i-need-super-administrator-permissions)

To list API grant permissions per Okta app - which is required for full NHI visibility - a **Super Administrator** role is required. This is the only built-in Okta role with access to this data. Refer to [Okta's documentation](https://help.okta.com/en-us/content/topics/security/administrators-admin-comparison.htm) for a full comparison of built-in admin roles.
GitBook AssistantWhat visibility is lost when using a Read-Only Administrator?[#what-visibility-is-lost-when-using-a-read-only-administrator](#what-visibility-is-lost-when-using-a-read-only-administrator)

Entro will not have visibility into API grant permissions per Okta app. This means NHI coverage for Okta applications will be incomplete.
GitBook AssistantCan I use a custom role instead of Super Administrator?[#can-i-use-a-custom-role-instead-of-super-administrator](#can-i-use-a-custom-role-instead-of-super-administrator)

Yes - refer to Okta Custom Entro Role for the full setup. When using a custom role, you must also assign the **Report Administrator** built-in role to enable audit log collection.
GitBook AssistantDoes Entro perform any write actions in Okta?[#does-entro-perform-any-write-actions-in-okta](#does-entro-perform-any-write-actions-in-okta)

No. All Entro operations in Okta are strictly read-only. Entro never modifies, creates, or deletes any data in your Okta organization.
GitBook Assistant[PreviousOkta Permissions Reference](/integrations/security-and-identity/okta/okta-permissions-reference)[NextSnowflake](/integrations/security-and-identity/snowflake)

Last updated 2 months ago

- [Validation Steps After Connection](#validation-steps-after-connection)
- [Common Issues](#common-issues)
- [FAQ](#faq)
