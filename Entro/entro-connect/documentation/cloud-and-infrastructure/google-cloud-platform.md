Google Cloud Platform | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/google-cloud-platform.md).

Entro's GCP integration connects your Google Cloud Platform organization for continuous secret discovery, IAM monitoring, and compliance validation - all using read-only access.
GitBook Assistant

📸 **Screenshot needed:** Entro portal → Management → Accounts & Integrations page showing the GCP integration card/tile.
GitBook Assistant
## Before You Start[#before-you-start](#before-you-start)

**Run the pre-onboarding check first.** Before choosing an onboarding method, run the pre-onboarding script to verify your account has the access needed. It takes 2–3 minutes and can prevent hours of troubleshooting.
GitBook Assistant

→ GCP Pre-Onboarding Check
GitBook Assistant
## Choose Your Onboarding Method[#choose-your-onboarding-method](#choose-your-onboarding-method)

### Option 1 - GCP Console Onboarding[#option-1-gcp-console-onboarding](#option-1-gcp-console-onboarding)

Use this if you can create and manage Service Accounts via the GCP Console. This is the most common path.
GitBook Assistant

**Authentication**
GitBook Assistant

Service Account JSON key *or* Workload Identity Federation (keyless)
GitBook Assistant

**Best for**
GitBook Assistant

GCP admins with console access · Single-org or single-project setups
GitBook Assistant

**Effort**
GitBook Assistant

~20–30 minutes
GitBook Assistant
### Option 2 - Terraform Onboarding (Infrastructure as Code)[#option-2-terraform-onboarding-infrastructure-as-code](#option-2-terraform-onboarding-infrastructure-as-code)

Automated setup using Terraform modules provided by Entro. Provisions the service account, roles, and API configuration in a single `terraform apply`.
GitBook Assistant

**Authentication**
GitBook Assistant

Service Account JSON key *or* Workload Identity Federation (keyless)
GitBook Assistant

**Best for**
GitBook Assistant

DevOps/SecOps teams · Enterprises with IaC pipelines · Multi-project orgs
GitBook Assistant

**Effort**
GitBook Assistant

~10 minutes (once Terraform is configured)
GitBook Assistant
### Option 3 - Workload Identity Federation (Keyless)[#option-3-workload-identity-federation-keyless](#option-3-workload-identity-federation-keyless)

Secretless authentication — Entro's AWS role impersonates your GCP service account with no JSON key file required or stored.
GitBook Assistant

**Authentication**
GitBook Assistant

Keyless (AWS ↔ GCP federation)
GitBook Assistant

**Best for**
GitBook Assistant

Organizations enforcing minimal credential storage · Multi-cloud setups · Security-sensitive environments
GitBook Assistant

**Effort**
GitBook Assistant

~15–20 minutes
GitBook Assistant
## Summary[#summary](#summary)
MethodAuthenticationSetupRecommended For

Console (Manual)
GitBook Assistant

JSON key or WIF
GitBook Assistant

Manual
GitBook Assistant

Admins managing via GCP UI
GitBook Assistant

Terraform
GitBook Assistant

JSON key or WIF
GitBook Assistant

Automated
GitBook Assistant

DevOps & SecOps teams
GitBook Assistant

WIF Only
GitBook Assistant

Keyless
GitBook Assistant

Manual or Automated
GitBook Assistant

Keyless / multi-cloud setups
GitBook Assistant
## Reference[#reference](#reference)

Last updated 4 months ago

- [Before You Start](#before-you-start)
- [Choose Your Onboarding Method](#choose-your-onboarding-method)
- [Option 1 - GCP Console Onboarding](#option-1-gcp-console-onboarding)
- [Option 2 - Terraform Onboarding (Infrastructure as Code)](#option-2-terraform-onboarding-infrastructure-as-code)
- [Option 3 - Workload Identity Federation (Keyless)](#option-3-workload-identity-federation-keyless)
- [Summary](#summary)
- [Reference](#reference)
