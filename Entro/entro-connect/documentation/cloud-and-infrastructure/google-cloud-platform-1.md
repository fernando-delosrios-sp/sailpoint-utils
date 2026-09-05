Google Cloud Platform | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/google-cloud-platform-1.md).

Entro’s GCP integration connects your Google Cloud Platform (GCP) organization to Entro for continuous secret discovery, IAM monitoring, and compliance validation.
GitBook Assistant

Depending on your environment, permissions, and deployment strategy, several onboarding paths are available. This page explains each option and when to use it.
GitBook Assistant1
#### GCP Console Onboarding (Recommended)[#gcp-console-onboarding-recommended](#gcp-console-onboarding-recommended)

Use this option if you can create or manage **Service Accounts** in the GCP Console.
GitBook Assistant

This setup uses either a **Service Account JSON key** or **Workload Identity Federation (WIF)** for authentication.
GitBook Assistant

Best for:
GitBook Assistant

- 

GCP administrators with console access
GitBook Assistant
- 

Teams comfortable managing IAM roles and APIs manually
GitBook Assistant
- 

Single-organization onboarding
GitBook Assistant
- 

Single-project onboarding
GitBook Assistant
2
#### GCP Terraform Onboarding (Infrastructure as Code)[#gcp-terraform-onboarding-infrastructure-as-code](#gcp-terraform-onboarding-infrastructure-as-code)

Automated onboarding using **Terraform** modules provided by Entro. This method provisions the required service account, roles, and API configurations in one step.
GitBook Assistant

Best for:
GitBook Assistant

- 

DevOps or SecOps teams managing IaC environments
GitBook Assistant
- 

Enterprises with policy-driven deployment pipelines
GitBook Assistant
3
#### Pre-Onboarding Check[#pre-onboarding-check](#pre-onboarding-check)

Run this step before onboarding to validate permissions and logging configuration.
GitBook Assistant

The provided bash script checks that:
GitBook Assistant

- 

Your user can access all relevant projects
GitBook Assistant
- 

Required APIs (e.g. Logging, Secret Manager) are enabled
GitBook Assistant
- 

IAM roles are properly assigned
GitBook Assistant

A `report.txt` file will summarize all findings for validation.
GitBook Assistant4
#### Permissions Reference[#permissions-reference](#permissions-reference)

Centralized list of IAM roles and API scopes required for Entro to function.
GitBook Assistant5
#### Troubleshooting & Validation[#troubleshooting-and-validation](#troubleshooting-and-validation)

After onboarding, verify that Entro displays a **Verified** connection and data synchronization is working.
GitBook Assistant

Includes curl validation examples, API checks, and troubleshooting scenarios for permissions or API enablement issues.
GitBook Assistant
## Summary of Methods[#summary-of-methods](#summary-of-methods)
MethodAuthenticationAutomationRecommended For

Console
GitBook Assistant

Service Account or WIF
GitBook Assistant

Manual
GitBook Assistant

Admins managing via GCP UI
GitBook Assistant

Terraform
GitBook Assistant

Service Account or WIF
GitBook Assistant

Automated
GitBook Assistant

DevOps & SecOps Teams
GitBook Assistant[PreviousAzure DevOps Troubleshooting And Validation](/integrations/cloud-and-infrastructure/azure-devops/azure-devops-troubleshooting-and-validation)[NextGCP Pre Onboarding Check](/integrations/cloud-and-infrastructure/google-cloud-platform-1/gcp-pre-onboarding-check)

Last updated 4 months ago
