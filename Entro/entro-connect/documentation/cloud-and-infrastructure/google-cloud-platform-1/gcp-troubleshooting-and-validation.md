GCP Troubleshooting And Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-troubleshooting-and-validation.md).1
#### Validation Steps After Connection[#validation-steps-after-connection](#validation-steps-after-connection)

1. 

In Entro Dashboard, navigate to **Management → Accounts & Integrations → GCP**.
GitBook Assistant
1. 

Confirm the status shows **Verified**.
GitBook Assistant
1. 

Review **Last Sync Timestamp** for recent activity.
GitBook Assistant
1. 

Inspect **Findings** for discovered secrets or misconfigurations.
GitBook Assistant

## API Validation Example[#api-validation-example](#api-validation-example)
Validate accessible GCP projectsGitBook AssistantAskCopy
```
curl -H "Authorization: <redacted> auth print-access-token)" https://cloudresourcemanager.googleapis.com/v1/projects
```

Expected: JSON list of accessible projects.
GitBook Assistant
## Common Issues[#common-issues](#common-issues)
IssueCauseResolution

403 Forbidden
GitBook Assistant

Missing IAM roles
GitBook Assistant

Ensure required roles are granted
GitBook Assistant

401 Unauthorized
GitBook Assistant

Expired Service Account key
GitBook Assistant

Regenerate key
GitBook Assistant

Connection failed
GitBook Assistant

Firewall or connector offline
GitBook Assistant

Check Worker Group (Connector)
GitBook Assistant

Missing logs
GitBook Assistant

APIs not enabled
GitBook Assistant

Enable logging.googleapis.com
GitBook Assistant[PreviousGCP Workload Identity Federation (Automated)](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-terraform-onboarding-automated/gcp-workload-identity-federation-automated)[NextGCP Permissions Reference](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-permissions-reference)

Last updated 2 months ago

- [API Validation Example](#api-validation-example)
- [Common Issues](#common-issues)
