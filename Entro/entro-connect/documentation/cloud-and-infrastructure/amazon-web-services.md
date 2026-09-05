Amazon Web Services | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/amazon-web-services.md).

Entro Security integrates natively with **Amazon Web Services (AWS)** to continuously discover, monitor, and secure secrets, tokens, and Non-Human Identities (NHIs) across your organization’s AWS environments. This integration supports both **CloudFormation** and **Assume Role** authentication methods to ensure secure, least-privilege access for all connected accounts.
GitBook Assistant
## Capabilities[#capabilities](#capabilities)

- 

Continuous discovery of secrets in **AWS Secrets Manager** and **AWS Systems Manager (SSM) Parameter Store**
GitBook Assistant
- 

Monitoring of **IAM users, roles, and service accounts** for credential exposure and misconfiguration
GitBook Assistant
- 

Correlation of NHIs with workloads such as **Lambda**, **ECS**, and **EKS** functions
GitBook Assistant
- 

Detection of leaked AWS access keys across connected repositories and SaaS integrations
GitBook Assistant
- 

Centralized visibility of all AWS NHIs within Entro’s unified inventory
GitBook Assistant
- 

Optional integration with **AWS CloudTrail** for enriched event and audit insights
GitBook Assistant

## Supported AWS Services[#supported-aws-services](#supported-aws-services)
ServiceDescription

**AWS Secrets Manager**
GitBook Assistant

Scans stored secrets, tokens, and API keys for exposure
GitBook Assistant

**AWS Systems Manager (SSM)**
GitBook Assistant

Scans Parameter Store for plaintext or misconfigured parameters
GitBook Assistant

**AWS Identity and Access Management (IAM)**
GitBook Assistant

Monitors users, roles, and service accounts for NHI tracking
GitBook Assistant

**AWS Key Management Service (KMS)**
GitBook Assistant

Maps encryption keys, aliases, and access metadata
GitBook Assistant

**AWS Lambda / ECS / EKS**
GitBook Assistant

Correlates workload-linked NHIs and service tokens
GitBook Assistant

**AWS CloudTrail**
GitBook Assistant

Provides visibility into key creation, secret access, and audit logs
GitBook Assistant

**AWS Bedrock and Agent Core**
GitBook Assistant

Discover AI Agents and their connected services
GitBook Assistant
## Security Principles[#security-principles](#security-principles)

Entro integrates with AWS using **least-privilege**, **read-only** access. Permissions are restricted to discovery-level actions only, with no ability to modify or create resources in your AWS environment. All communications between Entro and AWS are secured over **HTTPS/TLS** and authenticated with either an **IAM role assumption** or an **AWS CloudFormation-provisioned role**.
GitBook Assistant
## Architecture Diagram[#architecture-diagram](#architecture-diagram)

***Diagram Placeholder:***
GitBook Assistant
## Prerequisites[#prerequisites](#prerequisites)

Before integrating, ensure that:
GitBook Assistant

1. 

You have **AWS Administrator** or **IAM Full Access** privileges to create roles and policies.
GitBook Assistant
1. 

You know your **Entro AWS Account ID** (displayed in the setup wizard).
GitBook Assistant
1. 

Outbound HTTPS access to `api.entro.security` is allowed from your environment.
GitBook Assistant

## Integration Options[#integration-options](#integration-options)
MethodDescription

**CloudFormation (Recommended)**
GitBook Assistant

Automatically deploys Entro’s IAM Role and Policy via an AWS CloudFormation stack
GitBook Assistant

**Assume Role**
GitBook Assistant

Manual configuration using IAM Role and trust relationship with Entro’s AWS account
GitBook Assistant
## Data Processed[#data-processed](#data-processed)

Entro retrieves only metadata and secret identifiers - **never plaintext secret values**. Sensitive data remains stored securely in your AWS account; Entro analyzes metadata, context, and policy configurations for exposure risk and correlation.
GitBook Assistant
## Compliance and Privacy[#compliance-and-privacy](#compliance-and-privacy)

All AWS connections adhere to Entro’s internal compliance standards:
GitBook Assistant

- 

No data persistence of secret content
GitBook Assistant
- 

SOC 2 Type II and ISO 27001 aligned processing
GitBook Assistant
- 

Encrypted data in transit and at rest
GitBook Assistant
- 

Audit-ready access logs for every secret discovery and sync event
GitBook Assistant
[PreviousAkeyless Permissions Reference](/integrations/cloud-and-infrastructure/akeyless-vault/akeyless-permissions-reference)[NextAWS Onboarding Steps](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps)

Last updated 3 months ago

- [Capabilities](#capabilities)
- [Supported AWS Services](#supported-aws-services)
- [Security Principles](#security-principles)
- [Architecture Diagram](#architecture-diagram)
- [Prerequisites](#prerequisites)
- [Integration Options](#integration-options)
- [Data Processed](#data-processed)
- [Compliance and Privacy](#compliance-and-privacy)
GitBook AssistantAskCopy
```
Entro Security Cloud
   ↕ (HTTPS/TLS)
AWS Account
   ├── IAM (Users, Roles, NHIs)
   ├── Secrets Manager
   ├── Systems Manager Parameter Store
   ├── Key Management Service (KMS)
   └── CloudTrail Logs (Optional)
```
