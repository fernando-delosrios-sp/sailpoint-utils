Audit logs setup | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/azure/manual-policy-creation-overview/audit-logs-setup.md).

This section details the process for enabling and forwarding Entra Sign-In logs and Azure diagnostic logs to Entro Security. These logs are essential for monitoring Secrets/NHIs usage, creation, and detecting any unusual activity.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)
1
#### Step 1 - Create Log Analytics Workspace[#step-1-create-log-analytics-workspace](#step-1-create-log-analytics-workspace)

- 

Navigate to **Log Analytics Workspaces**, and then click **+ Create** 
GitBook Assistant
- 

Choose the appropriate Subscription, Resource group, Name, and Region, then click “Review + Create”, and then “Create” again to complete the process.
GitBook Assistant
2
#### Step 2 - Forward Service Principal Sign-in Logs[#step-2-forward-service-principal-sign-in-logs](#step-2-forward-service-principal-sign-in-logs)

- 

Navigate to Sign-in Logs
GitBook Assistant
- 

Click Save to apply.
GitBook Assistant
3
#### Step 3 - Connect Logs to Entro[#step-3-connect-logs-to-entro](#step-3-connect-logs-to-entro)

- 

In the Entro Dashboard, navigate to: Settings → Audit Integrations → Azure Activity Logs
GitBook Assistant
- 

Select your workspace or storage destination.
GitBook Assistant
- 

Authenticate with your Azure App Registration (created during onboarding).
GitBook Assistant
- 

Click Validate Connection.
GitBook Assistant
- 

Once validation succeeds, enable Continuous Sync to start ingestion.
GitBook Assistant
4
#### Step - Verify Data Flow[#step-verify-data-flow](#step-verify-data-flow)

Run the following command in Azure CLI to confirm diagnostic forwarding:
GitBook AssistantVerify diagnostic forwardingGitBook AssistantAskCopy
```
az monitor diagnostic-settings list --resource <resource-id> --output table
```

Expected result: includes EntroAuditForwarder or equivalent diagnostic stream name.
GitBook Assistant
## Recommended Log Types[#recommended-log-types](#recommended-log-types)

Entro analyzes the following logs to map credential events and identity changes:
GitBook AssistantLog TypePurpose

**AuditEvent**
GitBook Assistant

Tracks admin activity and configuration changes
GitBook Assistant

**SignInLogs**
GitBook Assistant

Detects authentication attempts and anomalies
GitBook Assistant

**Administrative**
GitBook Assistant

Captures resource and role modifications
GitBook Assistant

**KeyVaultAuditEvent**
GitBook Assistant

Monitors vault access patterns and secret enumerations
GitBook Assistant

**ManagedIdentitySignInLogs**
GitBook Assistant

Detects usage of service principals and NHIs
GitBook Assistant

Entro analyzes the log types listed above to map credential events and identity changes.
GitBook Assistant
## Security & Compliance[#security-and-compliance](#security-and-compliance)

- 

Logs are transmitted securely using HTTPS/TLS 1.2+.
GitBook Assistant
- 

Entro ingests only metadata and event context, never full payloads.
GitBook Assistant
- 

All collected logs are normalized and stored according to SOC 2 Type II, ISO 27001, and GDPR standards.
GitBook Assistant
- 

Entro's default data retention for audit events is 30 days.
GitBook Assistant
- 

Extended retention can be configured via Entro Support upon request.
GitBook Assistant

Last updated 4 months ago

- [Navigation Path](#navigation-path)
- [Recommended Log Types](#recommended-log-types)
- [Security & Compliance](#security-and-compliance)
