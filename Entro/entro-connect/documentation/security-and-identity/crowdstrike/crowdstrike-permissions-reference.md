CrowdStrike Permissions Reference | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/crowdstrike/crowdstrike-permissions-reference.md).
### Required API Scopes[#required-api-scopes](#required-api-scopes)
ScopePermissionPurposeAPIFeatures

Hosts
GitBook Assistant

Read
GitBook Assistant

List devices for scanning
GitBook Assistant

`/devices/queries/devices-scroll/v1 /devices/queries/devices-scroll/v1` 
GitBook Assistant

All
GitBook Assistant

Real Time Response 
GitBook Assistant

Read
GitBook Assistant

Create RTR sessions and read agents, secrets on devices AI MCP File lookup and Secrets Scanning
GitBook Assistant

`/real-time-response/entities/command/v1/real-time-response/entities/sessions/v1`
GitBook Assistant

Shadow Agentic AI Secrets Scanning
GitBook Assistant

NGSIEM
GitBook Assistant

Read/Write
GitBook Assistant

EDR Telemetry to classify AI Agents, MCPs on endpoints and their activity Write is required to create queries, there's no modification of data whatsoever.
GitBook Assistant

-
GitBook Assistant

Shadow Agentic AI
GitBook Assistant

Identity Protection GraphQL
GitBook Assistant

Write
GitBook Assistant

List identities (human, programmatic, groups)
GitBook Assistant

`/identity-protection/combined/graphql/v1`
GitBook Assistant

Active Directory Identities
GitBook Assistant

Identity Protection Entities
GitBook Assistant

Read
GitBook Assistant

Retrieve identity entity details
GitBook Assistant

`/identity-protection/entities/*`
GitBook Assistant

Active Directory Identities
GitBook Assistant

Identity Protection Detections
GitBook Assistant

Read
GitBook Assistant

Retrieve identity-based threat detections
GitBook Assistant

`/identity-protection/detections/*`
GitBook Assistant

Active Directory Identities
GitBook Assistant

Identity Protection Timeline
GitBook Assistant

Read
GitBook Assistant

Access identity activity timeline
GitBook Assistant

`/identity-protection/timeline/*`
GitBook Assistant

Active Directory Identities
GitBook Assistant

Write permissions are restricted and only granted for:
GitBook Assistant

- 

NGSIEM (creation of telemetry query)
GitBook Assistant
- 

Identity Protection GraphQL (creation of identity query)
GitBook Assistant
[PreviousCrowdStrike Troubleshooting And Validation](/integrations/security-and-identity/crowdstrike/crowdstrike-troubleshooting-and-validation)[NextFalcon RTR Secrets Scanner](/integrations/security-and-identity/crowdstrike/falcon-rtr-secrets-scanner)

Last updated 2 months ago
