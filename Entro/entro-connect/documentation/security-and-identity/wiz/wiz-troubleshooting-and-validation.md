Wiz Troubleshooting And Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/wiz/wiz-troubleshooting-and-validation.md).

This section provides guidance to validate and troubleshoot your Wiz integration with Entro Security.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

Management → Accounts & Integrations → Target Service filter → Wiz
GitBook Assistant
## Validation Steps[#validation-steps](#validation-steps)
1
#### Access the Wiz integration page[#access-the-wiz-integration-page](#access-the-wiz-integration-page)

In the Entro Dashboard, navigate to **Management → Accounts & Integrations → Wiz**.
GitBook Assistant2
#### Confirm connection status[#confirm-connection-status](#confirm-connection-status)

Confirm that connection status shows **Verified**.
GitBook Assistant3
#### Validate data ingestion[#validate-data-ingestion](#validate-data-ingestion)

Validate that DSPM findings and correlated NHIs appear in the **Findings** and **Inventory** tabs.
GitBook Assistant
## Command-Line Verification (Optional)[#command-line-verification-optional](#command-line-verification-optional)

You can manually validate Wiz API connectivity using the following command:
GitBook Assistantcurl — validate Wiz API connectivityGitBook AssistantAskCopy
```
curl -X POST https://api.us.app.wiz.io/graphql   -H "Content-Type: application/json"   -H "Authorization: <redacted>   -d '{"query": "{projects {id name}}"}'
```

Expected Output: A JSON object listing Wiz projects accessible with your Service Account credentials.
GitBook Assistant
## Common Issues and Resolutions[#common-issues-and-resolutions](#common-issues-and-resolutions)
IssuePossible CauseResolution

Authentication failed
GitBook Assistant

Invalid Client ID or Secret
GitBook Assistant

Regenerate credentials in Wiz and update Entro configuration
GitBook Assistant

Permissions error
GitBook Assistant

Missing required scopes
GitBook Assistant

Ensure Service Account has **read:data_findings**, **create:reports**, **read:reports**
GitBook Assistant

No DSPM data found
GitBook Assistant

Report not generated or expired
GitBook Assistant

Regenerate reports within Wiz
GitBook Assistant

Connection timeout
GitBook Assistant

Network or API endpoint restrictions
GitBook Assistant

Verify connectivity to Wiz API endpoint
GitBook Assistant[PreviousWiz Onboarding](/integrations/security-and-identity/wiz/wiz-onboarding)[NextWiz Permissions Reference](/integrations/security-and-identity/wiz/wiz-permissions-reference)

Last updated 2 months ago

- [Navigation Path](#navigation-path)
- [Validation Steps](#validation-steps)
- [Command-Line Verification (Optional)](#command-line-verification-optional)
- [Common Issues and Resolutions](#common-issues-and-resolutions)
