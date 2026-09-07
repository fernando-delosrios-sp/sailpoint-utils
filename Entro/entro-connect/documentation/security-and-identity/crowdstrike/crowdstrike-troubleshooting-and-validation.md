CrowdStrike Troubleshooting And Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/crowdstrike/crowdstrike-troubleshooting-and-validation.md).
### Common Issues & Resolutions[#common-issues-and-resolutions](#common-issues-and-resolutions)
IssueCauseResolution

`401 Unauthorized`
GitBook Assistant

Invalid or expired credentials
GitBook Assistant

Regenerate Client ID and Secret in CrowdStrike console
GitBook Assistant

`403 Forbidden`
GitBook Assistant

Insufficient permissions
GitBook Assistant

Confirm all required scopes are granted
GitBook Assistant

`Timeout`
GitBook Assistant

Network or firewall restriction
GitBook Assistant

Ensure outbound HTTPS (443) is open to CrowdStrike API
GitBook Assistant

`Invalid JSON Response`
GitBook Assistant

API throttling or temporary failure
GitBook Assistant

Retry after a few minutes; review CrowdStrike API limits
GitBook AssistantAdvanced Diagnostics (click to expand)[#advanced-diagnostics-click-to-expand](#advanced-diagnostics-click-to-expand)

Run the following curl test to verify access:
GitBook Assistantcurl - verify accessGitBook AssistantAskCopy
```
curl -X GET "https://api.crowdstrike.com/devices/queries/devices/v1"  -H "Authorization: <redacted>
```

Expected response includes a list of device IDs.
GitBook Assistant[PreviousCrowdStrike Onboarding](/integrations/security-and-identity/crowdstrike/crowdstrike-onboarding)[NextCrowdStrike Permissions Reference](/integrations/security-and-identity/crowdstrike/crowdstrike-permissions-reference)

Last updated 2 months ago
