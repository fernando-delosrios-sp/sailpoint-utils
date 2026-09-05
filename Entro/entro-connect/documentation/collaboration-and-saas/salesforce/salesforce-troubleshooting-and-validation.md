Salesforce Troubleshooting And Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/salesforce/salesforce-troubleshooting-and-validation.md).
## Validation After Connection[#validation-after-connection](#validation-after-connection)
1
#### In the Entro Dashboard[#in-the-entro-dashboard](#in-the-entro-dashboard)

Navigate to **Management → Accounts & Integrations → Salesforce**
GitBook Assistant2
#### Confirm connection status[#confirm-connection-status](#confirm-connection-status)

Confirm that the integration status displays **Verified,** with a recent validation timestamp.
GitBook Assistant3
#### Validate discovery[#validate-discovery](#validate-discovery)

Verify that findings related to Salesforce (e.g., secrets in service cases) are populating in the **'Secrets Inventory'** tab.
GitBook Assistant
## API Scope Validation (Optional)[#api-scope-validation-optional](#api-scope-validation-optional)

You can validate the credentials and flow using a `curl` command from your terminal:
GitBook AssistantGitBook AssistantAskCopy
```
 curl -X POST https://<DOMAIN>.my.salesforce.com/services/oauth2/token \
  -d "grant_type=client_credentials" \
  -d "client_id=<CLIENT_ID>" \
  -d "client_secret=<CLIENT_SECRET>"

```

Expected Output: A JSON response containing an `access_token`.
GitBook Assistant
### Common Issues[#common-issues](#common-issues)

**Issue**
GitBook Assistant

**Probable Cause**
GitBook Assistant

**Resolution**
GitBook Assistant

`error: invalid_client_id`
GitBook Assistant

Wrong Consumer Key or Secret.
GitBook Assistant

Double-check values copied from the Salesforce App Manager details page.
GitBook Assistant

`error: invalid_grant`
GitBook Assistant

*(no client credentials user enabled)*
GitBook Assistant

The "Run As" user is not configured for the flow.
GitBook Assistant

Go to Manage → Edit Policies. Under Client Credentials Flow, ensure a valid Run As User is selected and saved.
GitBook Assistant

`error: invalid_grant`
GitBook Assistant

*(authentication failure)*
GitBook Assistant

Policies are incorrect.
GitBook Assistant

Ensure Permitted Users is set to "All users can self-authorize" in the App Policies.
GitBook Assistant

`error: inactive_user`
GitBook Assistant

The "Run As" user is deactivated.
GitBook Assistant

Reactivate the user or select a different active user in the App Policies.
GitBook Assistant

No Findings/Data
GitBook Assistant

Insufficient permissions for the "Run As" user.
GitBook Assistant

Log in as the "Run As" user and verify they can view Cases, Comments, and Emails manually.
GitBook Assistant[PreviousSalesforce Onboarding](/integrations/collaboration-and-saas/salesforce/salesforce-onboarding)[NextSalesforce Permissions Reference](/integrations/collaboration-and-saas/salesforce/salesforce-permissions-reference)

Last updated 4 months ago

- [Validation After Connection](#validation-after-connection)
- [API Scope Validation (Optional)](#api-scope-validation-optional)
- [Common Issues](#common-issues)
