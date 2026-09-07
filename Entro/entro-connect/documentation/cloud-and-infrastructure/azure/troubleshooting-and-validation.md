Troubleshooting And Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/azure/troubleshooting-and-validation.md).

This section provides validation and troubleshooting steps for the Microsoft Azure integration with Entro Security. Use these procedures to verify configuration accuracy, connectivity, and permission scope.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

In the Entro Dashboard, navigate to: Management → Accounts & Integrations → **Target Service** filter → Select ***Azure***
GitBook Assistant
## Validate Connection Status[#validate-connection-status](#validate-connection-status)
1
#### Check integration status[#check-integration-status](#check-integration-status)

- 

In the Entro Dashboard, go to Management → Accounts & Integrations → Azure.
GitBook Assistant
- 

Confirm that the Connector Status displays **Active**.
GitBook Assistant
- 

Confirm that the Integration Status displays **Verified.**
GitBook Assistant
2
#### If status shows Failed / Error / Missing Permissions[#if-status-shows-failed-error-missing-permissions](#if-status-shows-failed-error-missing-permissions)

Open the integration details and check for error message. 
GitBook Assistant

- 

**401 Unauthorized** — Token expired or invalid.
GitBook Assistant
- 

**403 Forbidden** — Insufficient role permissions.
GitBook Assistant
- 

**404 Not Found** — Resource scope mismatch or deleted app registration.
GitBook Assistant

## Azure CLI Validation[#azure-cli-validation](#azure-cli-validation)

Use the following Azure CLI commands to validate API access and role configuration:
GitBook AssistantAzure CLIGitBook AssistantAskCopy
```
az ad sp show --id <client_id>
az role assignment list --assignee <client_id> --all --output table
az ad app permission list --id <client_id> --output table
```

Expected results:
GitBook Assistant

- 

Service principal is valid and active.
GitBook Assistant
- 

Only `Reader` and `Key Vault Reader` roles appear.
GitBook Assistant
- 

No write or owner permissions are assigned.
GitBook Assistant

## Common Errors[#common-errors](#common-errors)
ErrorCauseResolution

**401 Unauthorized**
GitBook Assistant

Token expired or invalid secret
GitBook Assistant

Generate a new client secret in Azure App Registration and update it in Entro, make sure the right fields are inserted.
GitBook Assistant

**403 Forbidden**
GitBook Assistant

Insufficient privileges
GitBook Assistant

Connector **Timeout or Connection Error**
GitBook Assistant

Network or API issue
GitBook Assistant

Confirm outbound HTTPS access to `https://api.entro.security`
GitBook Assistant

After applying corrections, re-run connection validation from the Entro Dashboard.
GitBook Assistant
## [#undefined](#undefined)

## Revoke or Rotate Credentials[#revoke-or-rotate-credentials](#revoke-or-rotate-credentials)
1
#### Delete old secret[#delete-old-secret](#delete-old-secret)

- 

In the Azure Portal → App Registrations → Certificates & Secrets, delete the old Client Secret.
GitBook Assistant
2
#### Generate and update[#generate-and-update](#generate-and-update)

- 

Generate a new client secret, then update credentials in Entro.
GitBook Assistant
- 

Updating credentials is also available via API
GitBook Assistant
- 

Rotation is recommended every 6 months for compliance and security hygiene
GitBook Assistant

[PreviousAzure Continuous Onboarding](/integrations/cloud-and-infrastructure/azure/azure-continuous-onboarding)[NextPermissions Reference](/integrations/cloud-and-infrastructure/azure/permissions-reference)

Last updated 2 months ago

- [Navigation Path](#navigation-path)
- [Validate Connection Status](#validate-connection-status)
- [Azure CLI Validation](#azure-cli-validation)
- [Common Errors](#common-errors)
- [#undefined](#undefined)
- [Revoke or Rotate Credentials](#revoke-or-rotate-credentials)
