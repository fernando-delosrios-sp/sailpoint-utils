Manual Policy Creation Overview | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/azure/manual-policy-creation-overview.md).

The Manual Policy Creation flow provides an alternative onboarding path for securely connecting Microsoft Azure to Entro Security when automation through PowerShell is restricted or not permitted by organizational policy.
GitBook Assistant

This method achieves the same least-privilege read-only setup as the automated flow, ensuring full compliance while maintaining administrative control over all Azure actions.
GitBook Assistant
## Manual Policy Creation Flow[#manual-policy-creation-flow](#manual-policy-creation-flow)

The manual flow is divided into clear, actionable pages for structured setup:
GitBook Assistant1
#### Policy Creation Steps[#policy-creation-steps](#policy-creation-steps)

Create and assign Azure policies to enable Entro read‑only monitoring.
GitBook Assistant

[Open Policy Creation Steps](/integrations/cloud-and-infrastructure/azure/manual-policy-creation-overview/policy-creation-steps)
GitBook Assistant2
#### Role Creation Steps[#role-creation-steps](#role-creation-steps)

Define the Entro custom role and grant subscription‑level read permissions.
GitBook Assistant

[Open Role Creation Steps](/integrations/cloud-and-infrastructure/azure/manual-policy-creation-overview/role-creation-steps)
GitBook Assistant3
#### Link to Entro[#link-to-entro](#link-to-entro)

Connect your Tenant ID, Client ID, and Secret within the Entro Dashboard.
GitBook Assistant

[Open Link to Entro](/integrations/cloud-and-infrastructure/azure/manual-policy-creation-overview/link-to-entro)
GitBook Assistant4
#### Audit Setup[#audit-setup](#audit-setup)

Configure logging and diagnostics to verify successful connection.
GitBook Assistant

[Open Audit Setup](/integrations/cloud-and-infrastructure/azure/manual-policy-creation-overview/audit-logs-setup)
GitBook Assistant
## Security & Compliance[#security-and-compliance](#security-and-compliance)

- 

All data access is read‑only (Graph and ARM APIs).
GitBook Assistant
- 

Tokens are encrypted using AES‑256 and transmitted only over TLS 1.2+.
GitBook Assistant
- 

Credentials are stored transiently and never leave your tenant during verification.
GitBook Assistant
- 

Entro complies with SOC 2 Type II, ISO 27001, and GDPR standards.
GitBook Assistant

Rotate client secrets periodically to maintain compliance and minimize exposure risk.
GitBook Assistant

Last updated 4 months ago

- [Manual Policy Creation Flow](#manual-policy-creation-flow)
- [Security & Compliance](#security-and-compliance)
