Shared Responsibility Model | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/legal-and-privacy/shared-responsibility-model.md).
## Why a shared responsibility model[#why-a-shared-responsibility-model](#why-a-shared-responsibility-model)

Entro gives your organization visibility and control over secrets and non-human identities (NHIs) across cloud, code, and SaaS environments. To do that, the platform connects to systems you own (code repositories, cloud accounts, vaults, collaboration tools) using credentials you provision. That makes the security of the overall solution a joint effort: Entro is responsible for the security of the platform, and you are responsible for security in your environment - the credentials you grant, the users you authorize, and the actions you take on the risks Entro surfaces.
GitBook Assistant

A clear division of responsibility eliminates ambiguity. Most cloud security incidents stem not from platform vulnerabilities but from misunderstandings about who owns a control. This document removes that ambiguity.
GitBook Assistant
## The model at a glance[#the-model-at-a-glance](#the-model-at-a-glance)
Entro is responsible forShared responsibilitiesYou are responsible for

Security of the platform: infrastructure, application code, encryption, data minimization, availability, and the controls behind our SOC 2 Type II and ISO 27001 alignment.
GitBook Assistant

Configuration of integrations and connectors, incident communication, patching (by deployment model), and keeping the connection between our systems healthy.
GitBook Assistant

Security in your environment: integration credentials, user access and roles, SSO and MFA enforcement, and remediating the findings Entro surfaces.
GitBook Assistant
## How Entro is built to minimize your burden[#how-entro-is-built-to-minimize-your-burden](#how-entro-is-built-to-minimize-your-burden)

Entro’s architecture is designed so that the platform itself carries as little of your sensitive data as possible:
GitBook Assistant

- 

Read-only by design. Collectors connect to your systems with read-only credentials. Entro does not modify your source code, configurations, or data during scanning.
GitBook Assistant
- 

No plaintext secrets stored. Detected secrets are SHA-256 hashed (for correlation) and redacted. Only metadata and secret fingerprints are retained - never the secret values themselves, and no source code is permanently stored.
GitBook Assistant
- 

Encryption everywhere. TLS 1.3 for data in motion (with mutual TLS between connectors and the platform) and AES-256 for data at rest.
GitBook Assistant
- 

Zero trust and least privilege. No implicit trust between platform services; each module operates with minimal access rights, and every data action is logged and traceable.
GitBook Assistant

## Entro’s responsibilities - security of the platform[#entros-responsibilities-security-of-the-platform](#entros-responsibilities-security-of-the-platform)

### Infrastructure and application security[#infrastructure-and-application-security](#infrastructure-and-application-security)

Entro secures, patches, and operates the platform infrastructure (hosted on AWS with selectable regions for SaaS deployments), the application code, APIs, and the web console. This includes network segmentation, IAM-restricted database access, vulnerability management, and secure development practices.
GitBook Assistant
### Data protection[#data-protection](#data-protection)

All customer data is encrypted in transit (TLS 1.3) and at rest (AES-256). Secret material is hashed and redacted before storage. The platform follows data-minimization principles, retaining only the metadata required for analysis.
GitBook Assistant
### Access control enforcement[#access-control-enforcement](#access-control-enforcement)

Entro provides and enforces role-based access control (RBAC) at both the UI and API layers - every API endpoint re-checks roles server-side, and endpoints without explicit role configuration default to admin-only. SSO (SAML) and MFA support are built in.
GitBook Assistant
### Availability, updates, and compliance[#availability-updates-and-compliance](#availability-updates-and-compliance)

For SaaS deployments, Entro manages uptime, scaling, automated daily backups, and continuous updates. Platform controls are aligned with SOC 2 Type II and ISO 27001, and operations align with GDPR data-management practices. Audit logging covers every data action.
GitBook Assistant
## Your responsibilities - security in your environment[#your-responsibilities-security-in-your-environment](#your-responsibilities-security-in-your-environment)

### Integration credentials and scope[#integration-credentials-and-scope](#integration-credentials-and-scope)

You provision the tokens, service accounts, and API keys Entro uses to scan your environments. Follow our least-privilege onboarding guides (read-only scopes wherever supported), store these credentials securely, and rotate or revoke them per your policies. You decide which accounts, repositories, and systems to onboard.
GitBook Assistant
### User access and identity[#user-access-and-identity](#user-access-and-identity)

You manage who can access your Entro tenant: assigning the predefined roles (Admin, Operator, Viewer, Integrator, API Key Manager, Engineer) according to least privilege, configuring SSO with your identity provider, enforcing MFA, and deprovisioning users who leave. Keep RBAC enabled - with it disabled, every authenticated user behaves as an admin.
GitBook Assistant
### Acting on findings[#acting-on-findings](#acting-on-findings)

Entro detects, prioritizes, and provides remediation paths - but rotating exposed secrets, disabling risky tokens, assigning owners, running remediation campaigns, and resolving findings in your systems are actions only you can authorize and complete. Timely remediation is the single most important customer responsibility.
GitBook Assistant
### Your environments and data[#your-environments-and-data](#your-environments-and-data)

The systems Entro scans remain yours to secure: source repositories, cloud accounts, vaults, and SaaS tools. You are also responsible for ensuring your use of Entro complies with the laws and regulations that apply to your organization.
GitBook Assistant
### Self-managed infrastructure (hybrid and self-hosted)[#self-managed-infrastructure-hybrid-and-self-hosted](#self-managed-infrastructure-hybrid-and-self-hosted)

If you deploy Entro Outpost connectors in your environment, or run the full platform self-hosted in your own AWS account, you operate that infrastructure: the Kubernetes or Docker environment, network access, host patching, customer-managed keys (CMK) where used, and applying Entro-published updates.
GitBook Assistant
## Shared responsibilities[#shared-responsibilities](#shared-responsibilities)

- 

Integration configuration. Entro provides connectors, onboarding scripts, and least-privilege permission references; you execute them in your environment and keep credentials current.
GitBook Assistant
- 

Patch management. Entro patches the platform and publishes versioned connector images; in hybrid and self-hosted deployments, you apply updates to components running in your environment.
GitBook Assistant
- 

Incident response. Entro monitors, alerts, and supports investigation of platform-side events; you investigate and respond to exposures within your own systems.
GitBook Assistant
- 

Detection tuning. Entro maintains detection models; you tune custom detections, triage findings, and mark verified false positives so signal quality stays high.
GitBook Assistant
- 

Awareness and training. Entro trains its personnel; you train your teams on secrets hygiene and on using Entro effectively.
GitBook Assistant

## Responsibility by deployment model[#responsibility-by-deployment-model](#responsibility-by-deployment-model)

Like all shared responsibility models, the boundary shifts with how you deploy. Entro offers SaaS, hybrid (Entro Outpost connectors in your perimeter), and self-hosted deployments. The further the platform moves into your environment, the more operational responsibility you assume.
GitBook AssistantResponsibilitySaaSHybridSelf-hosted

**Application code & detection engine**
GitBook Assistant

**Entro**
GitBook Assistant

**Entro**
GitBook Assistant

**Entro**
GitBook Assistant

**Platform hosting & availability**
GitBook Assistant

**Entro**
GitBook Assistant

**Entro**
GitBook Assistant

**Customer**
GitBook Assistant

**Connector infrastructure & updates**
GitBook Assistant

**Entro**
GitBook Assistant

**Customer**
GitBook Assistant

**Customer**
GitBook Assistant

**Encryption in transit & at rest**
GitBook Assistant

**Entro**
GitBook Assistant

**Shared**
GitBook Assistant

**Shared**
GitBook Assistant

**Encryption key management**
GitBook Assistant

**Entro**
GitBook Assistant

**Shared (CMK)**
GitBook Assistant

**Customer**
GitBook Assistant

**Integration credentials & scoping**
GitBook Assistant

**Customer**
GitBook Assistant

**Customer**
GitBook Assistant

**Customer**
GitBook Assistant

**User management, RBAC, SSO & MFA**
GitBook Assistant

**Customer**
GitBook Assistant

**Customer**
GitBook Assistant

**Customer**
GitBook Assistant

**Finding triage & remediation**
GitBook Assistant

**Customer**
GitBook Assistant

**Customer**
GitBook Assistant

**Customer**
GitBook Assistant

**Security of scanned environments**
GitBook Assistant

**Customer**
GitBook Assistant

**Customer**
GitBook Assistant

**Customer**
GitBook Assistant

**Network access to integrations**
GitBook Assistant

**Shared**
GitBook Assistant

**Customer**
GitBook Assistant

**Customer**
GitBook Assistant

**Backups of platform data**
GitBook Assistant

**Entro**
GitBook Assistant

**Entro**
GitBook Assistant

**Customer**
GitBook Assistant

**Regulatory compliance of your usage**
GitBook Assistant

**Customer**
GitBook Assistant

**Customer**
GitBook Assistant

**Customer**
GitBook Assistant
> 

In hybrid deployments, Outpost connectors process integration data (including hashing and redaction) inside your perimeter before metadata is sent to the Entro management layer. In self-hosted deployments, the full platform runs in a customer-owned AWS account.
GitBook Assistant
## Customer best practices[#customer-best-practices](#customer-best-practices)

- 

Use least-privilege, read-only credentials for every integration, following Entro’s per-platform permission references.
GitBook Assistant
- 

Enable SSO with your identity provider and enforce MFA for all Entro users.
GitBook Assistant
- 

Keep RBAC enabled and review role assignments quarterly; remove access for departed users promptly.
GitBook Assistant
- 

Establish an SLA for remediating critical findings, and use remediation campaigns to assign clear ownership.
GitBook Assistant
- 

Rotate integration credentials on a defined schedule and after personnel changes.
GitBook Assistant
- 

In hybrid or self-hosted deployments, keep Outpost connectors and platform components on supported, current versions.
GitBook Assistant
- 

Tune custom detections and resolve false positives so your team can focus on real exposure.
GitBook Assistant
[PreviousLicense and Service Level Agreement](/legal-and-privacy/license-and-service-level-agreement)

Last updated 2 months ago

- [Why a shared responsibility model](#why-a-shared-responsibility-model)
- [The model at a glance](#the-model-at-a-glance)
- [How Entro is built to minimize your burden](#how-entro-is-built-to-minimize-your-burden)
- [Entro’s responsibilities - security of the platform](#entros-responsibilities-security-of-the-platform)
- [Infrastructure and application security](#infrastructure-and-application-security)
- [Data protection](#data-protection)
- [Access control enforcement](#access-control-enforcement)
- [Availability, updates, and compliance](#availability-updates-and-compliance)
- [Your responsibilities - security in your environment](#your-responsibilities-security-in-your-environment)
- [Integration credentials and scope](#integration-credentials-and-scope)
- [User access and identity](#user-access-and-identity)
- [Acting on findings](#acting-on-findings)
- [Your environments and data](#your-environments-and-data)
- [Self-managed infrastructure (hybrid and self-hosted)](#self-managed-infrastructure-hybrid-and-self-hosted)
- [Shared responsibilities](#shared-responsibilities)
- [Responsibility by deployment model](#responsibility-by-deployment-model)
- [Customer best practices](#customer-best-practices)
