Use Cases | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/product-demo/readme.md).

**Entro top use cases to demonstrate it's capabilities**
GitBook Assistant
### **Non Human Identity**[#non-human-identity](#non-human-identity)
[**NHIDR Behavioral Anomaly**](https://eval.entro.security/admin/risks?status=OPEN&riskGuid=RSK-13778)** **Detection** ***exploited token used by many actors, deviating from history usage baseline*[#nhidr-behavioral-anomaly-detection-exploited-token-used-by-many-actors-deviating-from-history-usage](#nhidr-behavioral-anomaly-detection-exploited-token-used-by-many-actors-deviating-from-history-usage)

**Where to find it:** [Risk](https://eval.entro.security/admin/risks?status=OPEN&riskGuid=RSK-13778) **What happened: **Multiple new workloads used an AWS token to perform a new and risky action, from suspicious new devices.
GitBook Assistant

**What am I seeing**
GitBook Assistant

- 

**Finding:** “Token potential compromise”
GitBook Assistant
- 

**Asset type:** AWS Role
GitBook Assistant
- 

**Key ID:** `AROAZ2H7SIGKPVUSWASOJ`
GitBook Assistant
- 

**Matched identity:** `AWSReservedSSO_AdministratorAccess_2e7be467941fa707` / IAM user `Awsreservedsso administratoraccess 2e7be467941fa707`
GitBook Assistant
- 

**Activity:** 1 first-seen sensitive action detected
GitBook Assistant
- 

**Status: **Enabled
GitBook Assistant
- 

**Expires:** Never
GitBook Assistant
- 

**Category:** Abnormal Behavior
GitBook Assistant
- 

**Token usage baseline:** `signin.ConsoleLogin iam.CreateAccessKey cloudformation.CreateStack health.DescribeEventAggregates ec2.DescribeRegions secretsmanager.DescribeSecret cloudformation.DescribeStackEvents cloudformation.DescribeStacks uxc.GetAccountColor freetier.GetAccountPlanState ce.GetCostAndUsage ce.GetCostForecast notifications.GetFeatureOptInStatus secretsmanager.GetResourcePolicy iam.GetRole iam.GetSAMLProvider secretsmanager.GetSecretValue signin.GetSigninToken cloudformation.GetTemplateSummary kms.ListAliases servicecatalog-appregistry.ListApplications cost-optimization-hub.ListEnrollmentStatuses notifications.ListManagedNotificationEvents notifications.ListNotificationHubs cost-optimization-hub.ListRecommendationSummaries iam.ListRoles secretsmanager.ListSecrets cloudformation.ListStacks sns.ListTopics cloudtrail.LookupEvents iam.UpdateAccessKey`
GitBook Assistant
- 

**New action detected:** `PutRolePolicy` `CreateRole`
GitBook Assistant
- 

**AI classification reason:** AWS Role has executed sensitive actions that fall outside its established behavioral baseline, while also being used from a new device that wasn't observed during baseline learning
GitBook Assistant

**Why it's risky**
GitBook Assistant

- 

**This role performed a first-seen sensitive action outside its normal baseline.** The role is now triggering `PutRolePolicy` `CreateRole`, which is a meaningful behavior change.
GitBook Assistant
- 

**The identity name strongly suggests an elevated, priviledged account.** Typically AWSReservedSSO_Administrator roles are break glass accounts. 
GitBook Assistant

**Remediation options**
GitBook Assistant

- 

**Treat this as an incident unless you can quickly prove the activity is legitimate.** Contact the identity owner of `Awsreservedsso administratoraccess 2e7be467941fa707 `immediately to confirm whether the CloudFormation-triggered role creation and policy attachment operations were authorized and expected. Request written confirmation of the business justification, including which CloudFormation stack triggered these IAM modifications and whether this represents a legitimate Infrastructure-as-Code deployment.
GitBook Assistant
- 

**Review CloudTrail for the full blast radius.** Investigate all activity from `195.178.110.38`, especially S3 access, STS usage, IAM calls, and any role assumptions before and after the `ListBuckets` event.
GitBook Assistant
- 

**Find and remove the source of exposure.** Implement enhanced monitoring for the `Awsreservedsso administratoraccess` identity by enabling additional CloudTrail logging for IAM write operations and enabling real-time alerts for any future `CreateRole`, `PutRolePolicy`, `AttachRolePolicy`, or other privilege-escalation-related actions. Update the behavioral baseline to exclude these anomalous actions and require approval workflows for sensitive IAM operations from service principals.
GitBook Assistant

**Screenshot**
GitBook Assistant

** **** **
[**NHI Used from unapproved geo-ip for the first time**](https://eval.entro.security/admin/risks?status=OPEN&name=Activity+from+Untrusted+Location&riskGuid=RSK-13605)** **Detection *usage from Non-Baselined Country*[#nhi-used-from-unapproved-geo-ip-for-the-first-time-detection-usage-from-non-baselined-country](#nhi-used-from-unapproved-geo-ip-for-the-first-time-detection-usage-from-non-baselined-country)

**Where to find it:** [Risk](https://eval.entro.security/admin/risks?status=OPEN&name=Activity+from+Untrusted+Location&riskGuid=RSK-13605) **What happened: ***GCP Service Account Key accessed for the first time from a non-approved location "UAE", deviating from the established baseline.*
GitBook Assistant

**What am I seeing**
GitBook Assistant

- 

**Finding:** “Activity from an untrusted location”
GitBook Assistant
- 

**Asset type:** AWS IAM User
GitBook Assistant
- 

**Token ID:** `AKIAZQVWDB4KTIXYC236`
GitBook Assistant
- 

**Matched identity:** `Doron Assness` / IAM user `Doron.assness@entro.security`
GitBook Assistant
- 

**Status:** Enabled
GitBook Assistant
- 

**Activity:** In use from **Czechia** (`193.9.112.230`)
GitBook Assistant
- 

**Expires:** Never
GitBook Assistant
- 

**Category:** Abnormal Behavior
GitBook Assistant
- 

**Observed function:** `GetCallerIdentity`
GitBook Assistant
- 

**User agent:** `Boto3/1.42.59 md/Botocore#1.42.59 ua/2.1 os/macos#25.3.0 md/arch#arm64 lang/python#3.14.3 md/pyimpl#CPython m/n,Z,b,D cfg/retry-mode#legacy Botocore/1.42.59`
GitBook Assistant

**Why it's risky**
GitBook Assistant

- 

**This IAM account is being used from a country that is outside its learned baseline.** Entro is flagging that the source country is not part of the normal usage pattern and requires explicit approval to be considered trusted.
GitBook Assistant
- 

**Service account credentials are non-human, programmatic credentials that can be abused quietly.** Unlike interactive user access, a token like this can be reused from scripts, automation, or external infrastructure without normal user friction.
GitBook Assistant
- 

**The activity is tied to a GenAI content-generation function.** If this use is unauthorized, it could expose prompts, responses, or application data flowing through the connector.
GitBook Assistant
- 

**The source appears to be internet-based and unusual enough to trigger location trust controls.** That raises the likelihood of credential misuse, unauthorized automation, or traffic being routed through an unapproved VPN/proxy location.
GitBook Assistant

**Remediation options**
GitBook Assistant

- 

**Validate whether **`193.9.112.230`** / Czechia is an approved egress point, vendor IP, or corporate VPN location.** If this behavior is expected, review and approve the country in the baseline tab. **If it is not expected, investigate immediately.** Review audit logs around the triggering event time, confirm which workload used the service account, and inspect all recent `GenerateContent` calls from this identity.
GitBook Assistant
- 

**Rotate or revoke the token if misuse is suspected.** Also check where the credential is stored and move the workload to short-lived identity mechanisms where possible instead of long-lived static tokens.
GitBook Assistant

**Screenshot**
GitBook Assistant[**Stale Identity Tokens**](https://eval.entro.security/admin/risks?status=OPEN&tab=misconfiguration&input=idle%20token) Posture Risk *List report*[#stale-identity-tokens-posture-risk-list-report](#stale-identity-tokens-posture-risk-list-report)

**Where to find it: **[Risk](https://eval.entro.security/admin/risks?status=OPEN&tab=misconfiguration&input=idle%20token) (`Idle token` risks) / [Inventory](https://eval.entro.security/admin/nhi-tokens-inventory?customFilter=&externalFilters=eyJJRExFIjp0cnVlfQ%253D%253D) (`Idle` *quick-filter selected*)
GitBook Assistant

**What am I seeing**
GitBook Assistant

- 

Risks or inventory assets of Idle NHI Tokens
GitBook Assistant

**Why it's risky**
GitBook Assistant

- 

**A dormant credential can still be used even when nobody is actively managing it.** Stale identities are easy to forget, but they remain valid until they are disabled or deleted.
GitBook Assistant
- 

**Long-lived token/identities are attractive targets.**
GitBook Assistant
- 

**Idle keys usually indicate poor credential hygiene.** They often belong to abandoned workflows or old users, which means they are less likely to be monitored, rotated, or removed.
GitBook Assistant
- 

**If this NHI has broad permissions, the impact can be significant.**
GitBook Assistant

**Remediation options**
GitBook Assistant

- 

If these keys are no longer needed, disable them immediately.
GitBook Assistant
- 

Create a **Stale Identities** campaign to fully remediate and track progress of stale identity revocation.
GitBook Assistant
- 

Export all Idle token for internal sharing
GitBook Assistant

#### Screenshot[#screenshot](#screenshot)
[**Inventory and Lifecycle Management**](https://eval.entro.security/admin/nhi-tokens-inventory?customFilter=&externalFilters=eyJFWFBMT0lURUQiOmZhbHNlfQ%253D%253D&filters=WyJvcmlnaW5BY2Nlc3NNZXRob2QiXQ%253D%253D&encodedRequestJson=eyJzdGFydFJvdyI6MCwiZW5kUm93IjoxMDAsInJvd0dyb3VwQ29scyI6W10sInZhbHVlQ29scyI6W10sInBpdm90Q29scyI6W10sInBpdm90TW9kZSI6ZmFsc2UsImdyb3VwS2V5cyI6W10sImZpbHRlck1vZGVsIjp7Im9yaWdpbkFjY2Vzc01ldGhvZCI6eyJ2YWx1ZXMiOlsiQVdTX0lBTV9BQ0NFU1NfS0VZIiwiR0NQX1NFUlZJQ0VfQUNDT1VOVCIsIk9LVEFfQVBQTElDQVRJT04iLCJHSVRIVUJfUEVSU09OQUxfQUNDRVNTX1RPS0VOIiwiR0lUSFVCX0ZJTkVfR1JBSU5FRF9UT0tFTiIsIkFaVVJFX0FQUF9UT0tFTiJdLCJmaWx0ZXJUeXBlIjoic2V0In19LCJzb3J0TW9kZWwiOltdLCJsaW1pdCI6NTAwfQ%253D%253D) Inventory *graph view for all NHIs*[#inventory-and-lifecycle-management-inventory-graph-view-for-all-nhis](#inventory-and-lifecycle-management-inventory-graph-view-for-all-nhis)

**Where to find it: **[NHI Inventory](https://eval.entro.security/admin/nhi-tokens-inventory?customFilter=&externalFilters=eyJFWFBMT0lURUQiOmZhbHNlfQ%253D%253D&filters=WyJvcmlnaW5BY2Nlc3NNZXRob2QiXQ%253D%253D&encodedRequestJson=eyJzdGFydFJvdyI6MCwiZW5kUm93IjoxMDAsInJvd0dyb3VwQ29scyI6W10sInZhbHVlQ29scyI6W10sInBpdm90Q29scyI6W10sInBpdm90TW9kZSI6ZmFsc2UsImdyb3VwS2V5cyI6W10sImZpbHRlck1vZGVsIjp7Im9yaWdpbkFjY2Vzc01ldGhvZCI6eyJ2YWx1ZXMiOlsiQVdTX0lBTV9BQ0NFU1NfS0VZIiwiR0NQX1NFUlZJQ0VfQUNDT1VOVCIsIk9LVEFfQVBQTElDQVRJT04iLCJHSVRIVUJfUEVSU09OQUxfQUNDRVNTX1RPS0VOIiwiR0lUSFVCX0ZJTkVfR1JBSU5FRF9UT0tFTiIsIkFaVVJFX0FQUF9UT0tFTiJdLCJmaWx0ZXJUeXBlIjoic2V0In19LCJzb3J0TW9kZWwiOltdLCJsaW1pdCI6NTAwfQ%253D%253D) -> Any NHI Token -> `Lineage map` tab.
GitBook Assistant

What am I seeing: Graph view of all data collected per NHI token, learn more about each field in the [Lineage Map](https://docs.entro.security/knowledge-base/non-human-identity/nhi-lineage-map) KB.
GitBook Assistant

**Why it's important: **Unified view and scheme for Comprehensive NHI Data Across the Organization.
GitBook Assistant

**Screenshot**
GitBook Assistant[**Former Employee Identity Token**](https://eval.entro.security/admin/risks?tab=misconfiguration&status=OPEN&riskGuid=RSK-13459)** **Posture Risk *w/ Admin & Critical Data Access *[#former-employee-identity-token-posture-risk-w-admin-and-critical-data-access](#former-employee-identity-token-posture-risk-w-admin-and-critical-data-access)

**Where to find it: **[Risk](https://eval.entro.security/admin/nhi-risks?tab=misconfiguration&status=OPEN&riskGuid=RSK-13203) /** **[Inventory](https://eval.entro.security/admin/nhi-tokens-inventory?filters=WyJ0b2tlbklkIl0%253D&encodedRequestJson=eyJzdGFydFJvdyI6MCwiZW5kUm93IjoxMDAsInJvd0dyb3VwQ29scyI6W10sInZhbHVlQ29scyI6W10sInBpdm90Q29scyI6W10sInBpdm90TW9kZSI6ZmFsc2UsImdyb3VwS2V5cyI6W10sImZpbHRlck1vZGVsIjp7InRva2VuSWQiOnsidmFsdWVzIjpbIkFLSUFaMkg3U0lHS1A2NUVTWUZBIl0sImZpbHRlclR5cGUiOiJzZXQifX0sInNvcnRNb2RlbCI6W3sic29ydCI6ImRlc2MiLCJjb2xJZCI6ImFjY2Vzc2VkRGF0ZSJ9XSwibGltaXQiOjUwMH0%253D&customFilter=&externalFilters=) **What happened: **NHI Token associated with a former employee is still active, with sensitive privileged access.
GitBook Assistant

**What am I seeing**
GitBook Assistant

- 

**Finding:** “Former employee token is enabled”
GitBook Assistant
- 

**Asset type:** **AWS IAM access key**
GitBook Assistant
- 

**Key ID:** `AKIAZ2H7SIGKP65ESYFA`
GitBook Assistant
- 

**Matched identity:** **Ori Maor** / IAM username `Ori.maor`
GitBook Assistant
- 

**Status:** **Enabled**
GitBook Assistant
- 

**Last used:** shown as In use
GitBook Assistant
- 

**Expires:** **Never**
GitBook Assistant
- 

**Category:** **Misconfiguration**
GitBook Assistant
- 

**Permissions: Admin over AlexaForBusiness and write over EC2, EKS, IAM, and Route53**
GitBook Assistant

**Why it's risky**
GitBook Assistant

- 

**A former employee should not still have a usable credential.** If the identity match is correct, this is an offboarding failure. Former employees should lose access completely.
GitBook Assistant
- 

**AWS access keys are long-lived static credentials.** Unlike SSO sessions, these keys can keep working until they are disabled or deleted. That means even if the person’s normal account was deprovisioned in Okta, this key still authenticate from anywhere.
GitBook Assistant
- 

**IAM User has admin and critical write access to various microservices**
GitBook Assistant

**Remediation options**
GitBook Assistant

- 

Investigate if the last usage is after the SSO deprovision status change, to eliminate misuse scenario
GitBook Assistant
- 

Disable the identity and token
GitBook Assistant

**Screenshot**
GitBook Assistant[**Human-Workforce effective permissions automated mapping**](https://eval.entro.security/admin/employees?customFilter=&externalFilters=eyJISURFX1VOTUFUQ0hFRF9FTVBMT1lFRVMiOnRydWV9&filters=WyJzb3VyY2VzIl0%253D&encodedRequestJson=eyJzdGFydFJvdyI6MCwiZW5kUm93IjoxMDAsInJvd0dyb3VwQ29scyI6W10sInZhbHVlQ29scyI6W10sInBpdm90Q29scyI6W10sInBpdm90TW9kZSI6ZmFsc2UsImdyb3VwS2V5cyI6W10sImZpbHRlck1vZGVsIjp7InNvdXJjZXMiOnsidmFsdWVzIjpbIkFaVVJFIiwiT0tUQSJdLCJmaWx0ZXJUeXBlIjoic2V0In19LCJzb3J0TW9kZWwiOltdLCJsaW1pdCI6NTAwfQ%253D%253D) Management *List the AI-Agents, NHIs, and Secrets a human user can use to understand their effective permissions*[#human-workforce-effective-permissions-automated-mapping-management-list-the-ai-agents-nhis-and-secre](#human-workforce-effective-permissions-automated-mapping-management-list-the-ai-agents-nhis-and-secre)

**What am I seeing: **Visualizing the Effective Permissions of your human workforce. This view maps the hidden pathways from a single human user to the high-privilege AI-Agents, Non-Human Identities (NHIs), and Secrets they actually control.
GitBook Assistant

**Why it’s important: ** 
GitBook Assistant

- 

**The "Shadow Admin"** Most organizations only audit human permissions. Entro reveals the hidden blast radius. You aren't just seeing.
GitBook Assistant
- 

**Automated Entitlement Mapping ** Forget manual spreadsheets. Entro continuously crawls your Desktops, CI/CD, SaaS, and Cloud providers to link human owners to their digital "proxies" (Ai-Agents, NHIs and Secrets) in real-time.
GitBook Assistant
- 

**Identity Chain Visibility** You can trace exactly how a human user might unintentionally expose the company. If Alex's laptop is compromised.
GitBook Assistant
[***JIT-Managed tokens, *****auto-rotation**](https://eval.entro.security/admin/nhi-tokens-inventory?customFilter=&externalFilters=eyJKSVRfTUFOQUdFRCI6dHJ1ZX0%253D&filters=WyJvcmlnaW5BY2Nlc3NNZXRob2QiXQ%253D%253D&encodedRequestJson=eyJzdGFydFJvdyI6MCwiZW5kUm93IjoxMDAsInJvd0dyb3VwQ29scyI6W10sInZhbHVlQ29scyI6W10sInBpdm90Q29scyI6W10sInBpdm90TW9kZSI6ZmFsc2UsImdyb3VwS2V5cyI6W10sImZpbHRlck1vZGVsIjp7Im9yaWdpbkFjY2Vzc01ldGhvZCI6eyJ2YWx1ZXMiOlsiQVdTX0lBTV9BQ0NFU1NfS0VZIl0sImZpbHRlclR5cGUiOiJzZXQifX0sInNvcnRNb2RlbCI6W3sic29ydCI6ImRlc2MiLCJjb2xJZCI6ImFjY2Vzc2VkRGF0ZSJ9XSwibGltaXQiOjUwMH0%253D)** **Management *List and manage all JIT-Managed NHIs and rotate via JIT Portal*[#jit-managed-tokens-auto-rotation-management-list-and-manage-all-jit-managed-nhis-and-rotate-via-jit](#jit-managed-tokens-auto-rotation-management-list-and-manage-all-jit-managed-nhis-and-rotate-via-jit)

**What am I seeing: **A list of Non-Human Identities (NHIs) managed through Entro’s JIT (Just-In-Time) Portal. These NHIs are fully automated, auto-rotating, or ephemeral. Eliminating the danger of static, long-lived secrets.
GitBook Assistant

**Asset type:** Managed SaaS & Cloud Tokens (GitHub, Slack, AWS, etc.)
GitBook Assistant

**Status:** Fully Governed
GitBook Assistant

**Management & Orchestration**:
GitBook Assistant

- 

**Instant Rotation via JIT Portal** If you suspect an AI Agent is misbehaving or if an NHI has been compromised, you don't need to write a ticket. Reach out to the owner and rotate the token using the JIT Portal to reset the security boundary instantly.
GitBook Assistant
- 

**Centralized Governance** Entro provides a single pane of glass to view, rotate, and revoke every Non-Human identity in your organization.
GitBook Assistant
- 

**Audit-Ready Identity Lifecycle ** Every rotation, creation, and deletion is logged. You no longer. Govern the entire identity lifecycle from birth to burial.
GitBook Assistant
**Apply *****Zero Trust*** Remediation Prevention *Manually apply Zero Trust CA on supported identities (IAM User, IAM Role, Azure app registration)*[#apply-zero-trust-remediation-prevention-manually-apply-zero-trust-ca-on-supported-identities-iam-use](#apply-zero-trust-remediation-prevention-manually-apply-zero-trust-ca-on-supported-identities-iam-use)

**Where to find it: **[Inventory](https://eval.entro.security/admin/secrets-inventory?tab=cloud-service-tokens&tokenGuid=TKN-44) in Zero Trust tab to see blocked actions
GitBook Assistant

**What am I seeing: **
GitBook Assistant

- 

NHIs that can be enforced with Zero Trust in the identity level.
GitBook Assistant
- 

Zero trust is applying a conditional policy (IAM Policy / Azure CA) that restricts new usage outside of previously learned baseline. New usage = combination of new device and new action.
GitBook Assistant

**Why it's important:**
GitBook Assistant

- 

NHI tokens are designed for specific tasks and intended to function within a singular workload. 
GitBook Assistant
- 

Entro Zero trust adapt by monitoring each token's usage at scale, empowering customers to enhance security without affecting business operations or causing downtime. This approach significantly reduces the attack surface effortlessly.
GitBook Assistant

**Remediation options**
GitBook Assistant

- 

Navigate to the [NHI Inventory](https://eval.entro.security/admin/nhi-tokens-inventory?customFilter=&externalFilters=&filters=WyJvcmlnaW5BY2Nlc3NNZXRob2QiLCJ6ZXJvVHJ1c3RBcHBsaWNhYmlsaXR5Il0%253D&encodedRequestJson=eyJzdGFydFJvdyI6MCwiZW5kUm93IjoxMDAsInJvd0dyb3VwQ29scyI6W10sInZhbHVlQ29scyI6W10sInBpdm90Q29scyI6W10sInBpdm90TW9kZSI6ZmFsc2UsImdyb3VwS2V5cyI6W10sImZpbHRlck1vZGVsIjp7Im9yaWdpbkFjY2Vzc01ldGhvZCI6eyJ2YWx1ZXMiOlsiQVdTX0lBTV9BQ0NFU1NfS0VZIl0sImZpbHRlclR5cGUiOiJzZXQifSwiemVyb1RydXN0QXBwbGljYWJpbGl0eSI6eyJ2YWx1ZXMiOlsiUFJPVEVDVEVEIiwiQVBQTElDQUJMRSJdLCJmaWx0ZXJUeXBlIjoic2V0In19LCJzb3J0TW9kZWwiOlt7InNvcnQiOiJkZXNjIiwiY29sSWQiOiJhY2Nlc3NlZERhdGUifV0sImxpbWl0Ijo1MDB9)
GitBook Assistant
- 

Make sure you see the `Zero Trust` column
GitBook Assistant
- 

**Right-click** a row in the Inventory, then select `Zero Trust` at the bottom to activate or check applicability. A wizard will open, allowing you to apply Zero Trust directly through Entro or by creating an IaC template (CloudFormation).
GitBook Assistant

**Screenshots**
GitBook Assistant
### **AI Agents**[#ai-agents](#ai-agents)
[Agent Discovery](https://eval.entro.security/admin/agentic-ai-nhi-inventory) Discovery & Monitoring[#agent-discovery-discovery-and-monitoring](#agent-discovery-discovery-and-monitoring)

**Where to find it: **[AI Inventory](https://eval.entro.security/admin/agentic-ai-nhi-inventory)
GitBook Assistant

**What am I seeing: **A list of all discovered "Shadow AI" clients, from variety of sources (Endpoint, SaaS, Identity, AI Builders), and their properties
GitBook Assistant

- 

**AI Client:** detected agent/integration (e.g., ChatGPT / OpenAI, Copilot)
GitBook Assistant
- 

**Discovered on:** platform/source (Azure, SaaS Application)
GitBook Assistant
- 

**Connected Services:** downstream targets (SharePoint, Outlook, Teams, etc.) shown as icons
GitBook Assistant
- 

**Severity: **Calculated severity based on all observed factors
GitBook Assistant
- 

**Owners:** people or teams responsible for the agent
GitBook Assistant
- 

**Insights / Sessions / Last Seen:** risk counts, activity, and recent activity timestamp
GitBook Assistant
- 

**AI Classification:** Homegrown / Third-party / Not Monitored status
GitBook Assistant
- 

**Identity column:** identity used (human impersonation, service principal, “All Users”)
GitBook Assistant
- 

**Lineage panel:** graph showing Owner → Discovered On → Agent → Identity → Connected Services with effective permissions (Read/Write/Admin) → Activity
GitBook Assistant

**Why it's important**
GitBook Assistant

- 

**Shows who/what can access your data.** Quickly maps agents to services and identities so you know the blast radius.
GitBook Assistant
- 

**Reveals risky patterns:** human impersonation, Admin or “All Users” access, and unsanctioned (Homegrown/Not Monitored) agents.
GitBook Assistant
- 

**Prioritizes response:** Insights, sessions, and Last Seen help pick which agents to investigate first.
GitBook Assistant
- 

**Drives remediation:** owners + lineage let you remove privileges, replace long-lived secrets, and enforce least privilege.
GitBook Assistant

**Screenshot**
GitBook Assistant

[**Shadow Claude Code Consuming Production AWS Token via MCP**](https://eval.entro.security/admin/ai-risks?status=OPEN&riskGuid=RSK-14104) Shadow AI *NHI Consumer / MCP Config file*[#shadow-claude-code-consuming-production-aws-token-via-mcp-shadow-ai-nhi-consumer-mcp-config-file](#shadow-claude-code-consuming-production-aws-token-via-mcp-shadow-ai-nhi-consumer-mcp-config-file)

**Where to find it: **[Risk](https://eval.entro.security/admin/ai-risks?status=OPEN&riskGuid=RSK-14104) / AI Inventory / [NHI Inventory](https://eval.entro.security/admin/nhi-tokens-inventory?filters=WyJ0b2tlbklkIl0%253D&encodedRequestJson=eyJzdGFydFJvdyI6MCwiZW5kUm93IjoxMDAsInJvd0dyb3VwQ29scyI6W10sInZhbHVlQ29scyI6W10sInBpdm90Q29scyI6W10sInBpdm90TW9kZSI6ZmFsc2UsImdyb3VwS2V5cyI6W10sImZpbHRlck1vZGVsIjp7InRva2VuSWQiOnsidmFsdWVzIjpbIkFLSUFaUVZXREI0SzNMUk9QV1hGIl0sImZpbHRlclR5cGUiOiJzZXQifX0sInNvcnRNb2RlbCI6W3sic29ydCI6ImRlc2MiLCJjb2xJZCI6ImFjY2Vzc2VkRGF0ZSJ9XSwibGltaXQiOjUwMH0%253D&customFilter=&externalFilters=)
GitBook Assistant

**What happened: **Entro observed a production, privileged NHI is being used by agentic actor (Claude), which could lead to unintended changes or data leak.
GitBook Assistant

**What am I seeing**
GitBook Assistant

- 

**Finding:** “Privileged Production NHI used by AI Client”
GitBook Assistant
- 

**Asset type:** AWS IAM access key
GitBook Assistant
- 

**Key ID:** `AKIAZQVWDB4K3LROPWXF`
GitBook Assistant
- 

**Identity / user:** `dev-access` (`ARN: arn:aws:iam::654290652949:user/dev-access`)
GitBook Assistant
- 

**Identity owner / email:** `eyal.neemany@entro.security`
GitBook Assistant
- 

**Status:** Enabled
GitBook Assistant
- 

**Environment / Account:** AWS account `654290652949` / (Production)
GitBook Assistant

**Why it's important / risky**
GitBook Assistant

- 

**AI clients are automated and can act at scale.** A privileged production token used by an AI client can perform unintended or destructive changes quickly.
GitBook Assistant
- 

**Violates least-privilege principle.** Production/NHI credentials should not be used by generic AI integrations - increases blast radius.
GitBook Assistant
- 

**Harder to control & audit.** AI-driven requests may bypass human approvals and create noisy or dangerous activity.
GitBook Assistant
- 

**Potential for data loss or escalation.** If the token has broad rights, an AI client compromise or misconfiguration could lead to data exfiltration or privilege escalation.
GitBook Assistant

#### Remediation options[#remediation-options](#remediation-options)

- 

**Immediate:** identify which AI client is using the token and stop its usage (rotate/disable the key if misuse suspected).
GitBook Assistant
- 

**Replace with least-privilege model:** provision a scoped service identity or role for the AI client with only required production read/write scopes; prefer short-lived credentials/role assumption.
GitBook Assistant
- 

**Preventive:** use Entro's AI policy controls to block AI clients from using sensitive actions NHIs.
GitBook Assistant

**Screenshot**
GitBook Assistant[**AI Agent with Over-Permissive access as "All Users"**](https://eval.entro.security/admin/agentic-ai-nhi-inventory?encodedRequestJson=eyJzdGFydFJvdyI6MCwiZW5kUm93IjoxMDAsInJvd0dyb3VwQ29scyI6W10sInZhbHVlQ29scyI6W10sInBpdm90Q29scyI6W10sInBpdm90TW9kZSI6ZmFsc2UsImdyb3VwS2V5cyI6W10sImZpbHRlck1vZGVsIjp7Imluc2lnaHRzIjp7InZhbHVlcyI6WyJBZG1pbiBjb25zZW50IGJyb2FkIGFwcGxpY2F0aW9uIHBlcm1pc3Npb25zIl0sImZpbHRlclR5cGUiOiJzZXQifX0sInNvcnRNb2RlbCI6W10sImxpbWl0Ijo1MDB9) Posture[#ai-agent-with-over-permissive-access-as-all-users-posture](#ai-agent-with-over-permissive-access-as-all-users-posture)

**Where to find it:** [AI Inventory -> Perplexity](https://eval.entro.security/admin/agentic-ai-nhi-inventory?encodedRequestJson=eyJzdGFydFJvdyI6MCwiZW5kUm93IjoxMDAsInJvd0dyb3VwQ29scyI6W10sInZhbHVlQ29scyI6W10sInBpdm90Q29scyI6W10sInBpdm90TW9kZSI6ZmFsc2UsImdyb3VwS2V5cyI6W10sImZpbHRlck1vZGVsIjp7Imluc2lnaHRzIjp7InZhbHVlcyI6WyJBZG1pbiBjb25zZW50IGJyb2FkIGFwcGxpY2F0aW9uIHBlcm1pc3Npb25zIl0sImZpbHRlclR5cGUiOiJzZXQifX0sInNvcnRNb2RlbCI6W10sImxpbWl0Ijo1MDB9) **What happened: **Entro observed an active Azure Enterprise Application identity associated with Perplexity, with Graph permissions to the customer Entra tenant, targeting Sharepoint, Outlook, and Entra services.
GitBook Assistant

**What am I seeing**
GitBook Assistant

- 

**Access Scope:**
GitBook Assistant

- 

**Sharepoint: **`FullControl`** (****All Users**** Scope)**
GitBook Assistant
- 

**Outlook: **`Read`** (Single user data scope)**
GitBook Assistant
- 

**Entra: **`Read`** (Single user data scope)**
GitBook Assistant

- 

**Identity type:** Azure Enterprise Application
GitBook Assistant
- 

**AI Client:** Perplexity
GitBook Assistant

**Why it's risky**
GitBook Assistant

- 

**FullControl access to all users data ** Perplexity provides unrestricted access to the entire SharePoint organization data, allowing users to read and write all pages without limitations, removing barriers to access sensitive and private company information, this is a serious destructive data leak.
GitBook Assistant
- 

**Perplexity might be connected via private account** Private accounts are not bound by company policies on restrictions, posing a risk of data leaks if the training flag is enabled.
GitBook Assistant
- 

**Unscantioned sensitive shadow AI**
GitBook Assistant

**Remediation options**
GitBook Assistant

- 

Reduce excessive permissions
GitBook Assistant
- 

Disable connection app
GitBook Assistant

**Screenshot**
GitBook Assistant

[**Shadow Claude Usage Outside of Org management**](https://eval.entro.security/admin/agentic-ai-nhi-inventory?encodedRequestJson=eyJzdGFydFJvdyI6MCwiZW5kUm93IjoxMDAsInJvd0dyb3VwQ29scyI6W10sInZhbHVlQ29scyI6W10sInBpdm90Q29scyI6W10sInBpdm90TW9kZSI6ZmFsc2UsImdyb3VwS2V5cyI6W10sImZpbHRlck1vZGVsIjp7Imluc2lnaHRzIjp7InZhbHVlcyI6WyJTaGFkb3cgbm9uLW9yZyBDbGF1ZGUgdXNhZ2UgLSBDbGF1ZGUgYWN0aXZpdHkgZGV0ZWN0ZWQgd2l0aG91dCBhbiBhc3NvY2lhdGVkIENsYXVkZSBDb2RlIG9yZ2FuaXphdGlvbiBzZXNzaW9uIl0sImZpbHRlclR5cGUiOiJzZXQifX0sInNvcnRNb2RlbCI6W10sImxpbWl0Ijo1MDB9) Shadow AI[#shadow-claude-usage-outside-of-org-management-shadow-ai](#shadow-claude-usage-outside-of-org-management-shadow-ai)

**Where to find it: **[AI Inventory](https://eval.entro.security/admin/agentic-ai-nhi-inventory?encodedRequestJson=eyJzdGFydFJvdyI6MCwiZW5kUm93IjoxMDAsInJvd0dyb3VwQ29scyI6W10sInZhbHVlQ29scyI6W10sInBpdm90Q29scyI6W10sInBpdm90TW9kZSI6ZmFsc2UsImdyb3VwS2V5cyI6W10sImZpbHRlck1vZGVsIjp7Imluc2lnaHRzIjp7InZhbHVlcyI6WyJTaGFkb3cgbm9uLW9yZyBDbGF1ZGUgdXNhZ2UgLSBDbGF1ZGUgYWN0aXZpdHkgZGV0ZWN0ZWQgd2l0aG91dCBhbiBhc3NvY2lhdGVkIENsYXVkZSBDb2RlIG9yZ2FuaXphdGlvbiBzZXNzaW9uIl0sImZpbHRlclR5cGUiOiJzZXQifX0sInNvcnRNb2RlbCI6W10sImxpbWl0Ijo1MDB9) **What happened: **Some users are accessing Claude without using their organizational accounts.
GitBook Assistant

**What am I seeing**
GitBook Assistant

- 

Shadow AI Claude instances within Engineers endpoints, detected via EDR
GitBook Assistant
- 

Under insight - see the risk insight: `Shadow non-org Claude usage`
GitBook Assistant

**Screenshot**
GitBook Assistant[AI Agent Access Management and Policy](https://eval.entro.security/admin/ai-agents-policies) Agentic Guardrails[#ai-agent-access-management-and-policy-agentic-guardrails](#ai-agent-access-management-and-policy-agentic-guardrails)

**Where to find it: **AI Agents -> [Policies](https://eval.entro.security/admin/ai-agents-policies)
GitBook Assistant

**What am I seeing: **Policies to allow / deny specific managed agents usage patterns targeting MCPs / Enterprise service.
GitBook Assistant

**Why it's important: **Real-time governance enforcement for Agentic AI across all enterprise agents, ensuring seamless adoption.
GitBook Assistant

**Screenshot**
GitBook Assistant
### **Secret Security**[#secret-security](#secret-security)
SaaS Token Sprawl - GitHub PAT exposed on ServiceNow Incident[#saas-token-sprawl-github-pat-exposed-on-servicenow-incident](#saas-token-sprawl-github-pat-exposed-on-servicenow-incident)

**Where to find it:** [Risk](https://eval.entro.security/admin/risks?tab=exposed-secrets&status=OPEN&riskGuid=RSK-13720) **What happened: **A high-privilege NHI credential / Secret was leaked in a ServiceNow Incident ticket
GitBook Assistant

**What am I seeing**
GitBook Assistant

- 

**Finding:** “NHI Exposure"
GitBook Assistant
- 

**Asset type:** GitHub Personal Access Token
GitBook Assistant
- 

**Status: **Enabled
GitBook Assistant
- 

**Expires:** Never
GitBook Assistant
- 

**Category:** NHI Leakage / Lateral Movement
GitBook Assistant
- 

**Data access:** Unauthorized access to proprietary source code (GitHub).
GitBook Assistant

**Why it's risky**
GitBook Assistant

- 

**Plaintext Exposure in a ServiceNow Incident Ticket **The token was posted in a ServiceNow ticket. Any user (or compromised account) that can access that ticket now has the same permissions as the service account.
GitBook Assistant
- 

**Privilege Escalation** The GitHub PAT has `admin:enterprise` scopes. This allows an attacker not just to read code, but to delete repositories, change branch protection rules, or inject malicious code into the build pipeline. Currently this token has access to 38 repos within GitHub Enterprise for `liminal-security`
GitBook Assistant
- 

**Bypassing Perimeter Security** Because these tokens are programmatic, they do not trigger SSO or MFA prompts. The attacker is currently "impersonating" a trusted service, bypassing your identity provider (e.g., Okta/Azure AD).
GitBook Assistant

**Remediation options**
GitBook Assistant

- 

**Reach out to the owner and Rotate the token using the JIT Portal **Reach out to the owner responsible for the exposed token. Use the Just-In-Time (JIT) Portal to trigger an immediate rotation. This ensures the new token is injected directly into the secure vault without being handled in plaintext again. 
GitBook Assistant

**Screenshot**
GitBook Assistant[**CI/CD Secret Exposure - Databricks PAT exposed in Jenkins CI/CD**](https://eval.entro.security/admin/exposed-risks?status=OPEN&riskGuid=RSK-13124)[#ci-cd-secret-exposure-databricks-pat-exposed-in-jenkins-ci-cd](#ci-cd-secret-exposure-databricks-pat-exposed-in-jenkins-ci-cd)

**Where to find it:** [Risk](https://eval.entro.security/admin/exposed-risks?status=OPEN&riskGuid=RSK-13124) **What happened: **A production Databricks PAT was leaked in plaintext within Jenkins CI/CD job logs. The key is now indexed and viewable by anyone with repository access.
GitBook Assistant

**What am I seeing**
GitBook Assistant

- 

**Finding:** “CI/CD NHI Leakage"
GitBook Assistant
- 

**Asset type:** Databricks Personal Access Token
GitBook Assistant
- 

**Key ID:** `dapi04d58162***********839c622b213b7`
GitBook Assistant
- 

**NHI Username: **`entro`
GitBook Assistant
- 

**Status: **Enabled
GitBook Assistant
- 

**Expires:** Never
GitBook Assistant
- 

**Category:** NHI Leakage / Lateral Movement
GitBook Assistant
- 

**Data access:** Unauthorized access to a cloud production environment.
GitBook Assistant

**Why it's risky**
GitBook Assistant

- 

**Plaintext Exposure in logs **Even if you fix the code, the key remains in your history for 90 days. Every contractor or guest with "Read" access now has your AWS environment.
GitBook Assistant
- 

**Privilege Escalation** An attacker can use this foothold to elevate themselves, creating new users or deleting backups to lock you out.
GitBook Assistant
- 

**Zero-MFA Bypass:** This key provides a direct, unauthenticated back door into your cloud, bypassing SSO and all perimeter security.
GitBook Assistant

**Remediation options**
GitBook Assistant

- 

**Purge Log History** Delete the specific workflow run and all cached logs. Simply fixing the code isn't enough; the plaintext secret remains in your Jenkins history for 90 days unless manually purged.
GitBook Assistant
- 

**Reach out to the owner and Rotate the token using the JIT Portal **Reach out to **owner**, the owner responsible for the exposed token. Use the Just-In-Time (JIT) Portal to trigger an immediate rotation. This ensures the new token is injected directly into the secure vault without being handled in plaintext again.
GitBook Assistant
[**Google Drive used as a "personal vault"**](https://eval.entro.security/admin/risks?status=OPEN&riskGuid=RSK-14682)[#google-drive-used-as-a-personal-vault](#google-drive-used-as-a-personal-vault)

**Where to find it: **[Risk](https://eval.entro.security/admin/risks?status=OPEN&riskGuid=RSK-14682) **What happened: **Plaintext sensitive secrets are stored in a Sharepoint site called `Vault-for-Secret.aspx` in a shared site (across the entire organization).
GitBook Assistant

**What am I seeing**
GitBook Assistant

- 

**Finding:** “Exposed secrets ‘gold-mine’ found in Google Drive”
GitBook Assistant
- 

**Asset type:** Google Drive file / document (`Test file,`)
GitBook Assistant
- 

**Scope:** 12** occurrences** in one location representing **5 unique secret types**
GitBook Assistant
- 

**Secret types shown:** Jdbc, Generic creds, Slack app tokens, Gitlab PAT, and GitHub API Token
GitBook Assistant
- 

**Last editor / Risk owner:** Eyal Neemany (`admin@neeyal.com`)
GitBook Assistant
- 

**Category:** Exposed Secret
GitBook Assistant
- 

**Integration account:** `neeyal.com`
GitBook Assistant
- 

**Exposure time:** Tue, 14 Jul 2026
GitBook Assistant

**Why it's risky**
GitBook Assistant

- 

**Concentrated attack surface.** Many different valid credentials in one place (“gold-mine”) makes compromise extremely efficient.
GitBook Assistant
- 

**Ease of discovery & reuse.** SharePoint is often searchable or shared; leaked secrets there are easy for attackers or insiders to find and abuse.
GitBook Assistant
- 

**Compliance / data exposure:** Could expose PII, financial or IP assets and fail audit/DLP requirements.
GitBook Assistant

**Remediation options**
GitBook Assistant

- 

**Immediate:** revoke/rotate all exposed secrets (Jdbc, Slack tokens, DB/API keys) and treat as incident if access shows suspicious activity.
GitBook Assistant
- 

**Remove exposure:** delete the secrets from the SharePoint page and any version history; remove public/overbroad sharing.
GitBook Assistant

**Screenshot**
GitBook Assistant
### **Shift-left toolkit**[#shift-left-toolkit](#shift-left-toolkit)

Shift-left feature testing is limited to customer owned accounts. Contact Entro support for details.
GitBook AssistantCLI (Pre-commit hook / local scanner) Secrets Scanning[#cli-pre-commit-hook-local-scanner-secrets-scanning](#cli-pre-commit-hook-local-scanner-secrets-scanning)

Entro scanner and intent monitoring on each device (via MDM / Manually - adoption is monitored in the platform)
GitBook AssistantPR Scanner (Merge Prevention) Secrets Scanning[#pr-scanner-merge-prevention-secrets-scanning](#pr-scanner-merge-prevention-secrets-scanning)

Entro scanner to prevent merging sensitive data to production systems and promoting awareness
GitBook AssistantWebGuard Chrome Extension Secrets Scanning (GA), Agentic AI (TBD)[#webguard-chrome-extension-secrets-scanning-ga-agentic-ai-tbd](#webguard-chrome-extension-secrets-scanning-ga-agentic-ai-tbd)

Entro scanner to prevent sharing sensitive data with AI Chats (GPTs / etc).
GitBook AssistantCode Plugin (IDE Extension) Secrets Scanning[#code-plugin-ide-extension-secrets-scanning](#code-plugin-ide-extension-secrets-scanning)

Entro scanner to prevent deploying sensitive data while coding and collaborating.
GitBook AssistantAI Agent Plugin (Claude, Cursor, Gemini) Agentic AI (GA), Secrets Scanning (TBD)[#ai-agent-plugin-claude-cursor-gemini-agentic-ai-ga-secrets-scanning-tbd](#ai-agent-plugin-claude-cursor-gemini-agentic-ai-ga-secrets-scanning-tbd)

Entro Agentic AI Audit, Prevention and Governance plugins
GitBook AssistantSlack DLP Prevention (Enterprise Grid license only) Secrets Scanning[#slack-dlp-prevention-enterprise-grid-license-only-secrets-scanning](#slack-dlp-prevention-enterprise-grid-license-only-secrets-scanning)

Entro Secret Scanning immediate redaction to prevent potential sensitive data and secrets leakage withi Enterprise Grid Slack channel messages
GitBook Assistant

[PreviousIntegrations](/product-demo/integrations)

Last updated 26 days ago

- [Non Human Identity](#non-human-identity)
- [AI Agents](#ai-agents)
- [Secret Security](#secret-security)
- [Shift-left toolkit](#shift-left-toolkit)
