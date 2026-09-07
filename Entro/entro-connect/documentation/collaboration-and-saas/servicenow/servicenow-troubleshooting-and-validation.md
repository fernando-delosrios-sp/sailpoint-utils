ServiceNow Troubleshooting and Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/servicenow/servicenow-troubleshooting-and-validation.md).

This page describes how to validate and troubleshoot your ServiceNow integration after setup in Entro Security. These steps confirm that the connection is active, data visibility is established, and API scopes are correctly configured.
GitBook Assistant
## Validation Steps[#validation-steps](#validation-steps)
1
#### Verify Connection Status[#verify-connection-status](#verify-connection-status)

- 

In the Entro Dashboard, navigate to: **Management → Accounts & Integrations**
GitBook Assistant
- 

Locate your **ServiceNow** account.
GitBook Assistant
- 

Confirm that the **Status** column displays **Verified**.
GitBook Assistant
- 

Click the account entry to open details and view the **Last Sync Time**.
GitBook Assistant
2
#### Confirm Data Visibility[#confirm-data-visibility](#confirm-data-visibility)

- 

Navigate to the **Findings** section in Entro.
GitBook Assistant
- 

Filter results by the **ServiceNow integration nickname**.
GitBook Assistant
- 

Confirm that ticket, knowledge article, and configuration data are visible.
GitBook Assistant
3
#### Validate API Key Scope[#validate-api-key-scope](#validate-api-key-scope)

Use the **ServiceNow API Explorer** or a **cURL command** to confirm API access:
GitBook AssistantcURLGitBook AssistantAskCopy
```
curl -X GET 'https://<yourDomain>.service-now.com/api/now/table/incident' \
  -H 'x-sn-apikey: <YOUR_TOKEN>' \
  -H 'Accept: application/json'
```

Expected outcome:
GitBook Assistant

- 

Response status: **200 OK**
GitBook Assistant
- 

No "unauthorized" or "forbidden" errors
GitBook Assistant
- 

Returned JSON includes table data (limited by read-only role)
GitBook Assistant

If validation fails, confirm that:
GitBook Assistant

- 

The **Integration User** is active
GitBook Assistant
- 

The correct **Auth Scope (entro-auth-scope)** is assigned to both APIs
GitBook Assistant
- 

The **Access Token** has not expired or been revoked
GitBook Assistant

## Common Issues and Resolutions[#common-issues-and-resolutions](#common-issues-and-resolutions)
**Users/Integrations unable to login with Basic Auth**[#users-integrations-unable-to-login-with-basic-auth](#users-integrations-unable-to-login-with-basic-auth)

1. 

Create BasicAuth Authentication Profile:
GitBook Assistant

1. 

Go to **All → System Web Services → API Access Policies → Inbound Authentication Profiles**
GitBook Assistant
1. 

Select **New**
GitBook Assistant
1. 

Select **Create standard http authentication profiles**
GitBook Assistant
1. 

Give the new profile a name (like BasicAuth) and make sure that `Basic Auth` is selected as the Type
GitBook Assistant
1. 

Click **Submit**
GitBook Assistant

1. 

Add the new profile to all the REST API Access Policies:
GitBook Assistant

1. 

Go to **Navigate to All → System Web Services → REST API Access Policies**
GitBook Assistant
1. 

Click the **Table API policy**
GitBook Assistant
1. 

In the Inbound authentication profiles at the bottom, add the new BasicAuth auth profile to the list (in addition to the Entro auth profile)
GitBook Assistant
1. 

Do the same for the **Attachments API policy**
GitBook Assistant

**Connection status not verified**[#connection-status-not-verified](#connection-status-not-verified)

**Resolution:** Recreate the API Access Token and reconnect the integration.
GitBook Assistant**API response returns 401 or 403**[#api-response-returns-401-or-403](#api-response-returns-401-or-403)

**Resolution:** Ensure the token scope and roles (`itil`, `snc_read_only`, `personalize_dictionary`, `knowledge`) are correctly assigned.
GitBook Assistant**No findings or data appear in Entro**[#no-findings-or-data-appear-in-entro](#no-findings-or-data-appear-in-entro)

**Resolution:** Validate that the integration's API scopes are active and the Worker Group is online.
GitBook Assistant
## Resetting or Reconnecting the Integration[#resetting-or-reconnecting-the-integration](#resetting-or-reconnecting-the-integration)

To re-establish connectivity:
GitBook Assistant

- 

In Entro, open the existing ServiceNow account.
GitBook Assistant
- 

Regenerate the **API Access Token** in ServiceNow.
GitBook Assistant
- 

Update the token in the Entro integration form.
GitBook Assistant
- 

The integration will revalidate automatically and restart scanning.
GitBook Assistant

## Support[#support](#support)

If validation continues to fail after completing the above steps, review the Common Issues section or contact **Entro Support** through your dedicated Slack or Teams channel, or at **support@entro.security**.
GitBook Assistant[PreviousServiceNow Onboarding](/integrations/collaboration-and-saas/servicenow/servicenow-onboarding)[NextServiceNow Permissions Reference](/integrations/collaboration-and-saas/servicenow/servicenow-permissions-reference)

Last updated 2 months ago

- [Validation Steps](#validation-steps)
- [Common Issues and Resolutions](#common-issues-and-resolutions)
- [Resetting or Reconnecting the Integration](#resetting-or-reconnecting-the-integration)
- [Support](#support)
