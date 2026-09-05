AWS CloudTrail S3 Setup | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/aws-cloudtrail-s3-setup.md).

The AWS CloudTrail integration enables Entro Security to correlate secret activity with AWS audit logs. By connecting your CloudTrail S3 bucket, Entro can detect when secrets are created, modified, or accessed - improving visibility into credential usage and anomaly detection.
GitBook Assistant
## Overview[#overview](#overview)

Integrating AWS CloudTrail with Entro allows:
GitBook Assistant

- 

Correlation between discovered secrets and API activity.
GitBook Assistant
- 

Identification of access anomalies tied to NHIs.
GitBook Assistant
- 

Contextual enrichment of incident investigations.
GitBook Assistant
- 

Optional continuous validation of secret rotation and key management.
GitBook Assistant

The integration uses read-only permissions to access S3 log data. No log files are modified, and no data is exported outside of your AWS environment.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

Management → Accounts & Integrations → Add New Account (top right) → AWS → Manual Onboarding → CloudTrail S3 Setup
GitBook Assistant
## Architecture Diagram[#architecture-diagram](#architecture-diagram)
GitBook AssistantAskCopy
```
Entro Security Cloud
   ↕ (HTTPS/TLS)
AWS Account
   ├── CloudTrail
   │     └── S3 Bucket (Log Delivery)
   └── IAM Role (EntroRoleAWS)
```

## Prerequisites[#prerequisites](#prerequisites)

- 

An existing **AWS CloudTrail Trail** configured to deliver logs to an S3 bucket.
GitBook Assistant
- 

The **EntroAWSIntegrationRole** IAM Role must include S3 read-only access.
GitBook Assistant
- 

Outbound HTTPS/TLS connectivity from Entro to AWS APIs.
GitBook Assistant
- 

Permission to update the S3 bucket policy if access must be granted manually.
GitBook Assistant

## Permissions Required[#permissions-required](#permissions-required)

Entro needs the following S3 read-only permissions to collect and process CloudTrail logs:
GitBook Assistant
## Setup Steps[#setup-steps](#setup-steps)
1
#### Create a Trail (if none exists)[#create-a-trail-if-none-exists](#create-a-trail-if-none-exists)

If CloudTrail is not yet configured, follow: [Creating a Trail with the CloudTrail Console →](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/aws-cloudtrail-s3-setup/creating-trail-cloudtrail-console)
GitBook Assistant2
#### Configure the Trail for Entro Access[#configure-the-trail-for-entro-access](#configure-the-trail-for-entro-access)

If you already have a CloudTrail trail, configure it to allow Entro to read logs from the S3 bucket: [Configure a Trail with the CloudTrail Console →](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/aws-cloudtrail-s3-setup/configure-trail-cloudtrail-console)
GitBook Assistant3
#### Validate in Entro[#validate-in-entro](#validate-in-entro)

After setup:
GitBook Assistant

- 

Return to **Entro → Integrations → AWS**.
GitBook Assistant
- 

Confirm CloudTrail S3 integration shows as **Connected**.
GitBook Assistant
- 

Verify event correlation in the **Activity Logs** or **Inventory → Secrets** tab.
GitBook Assistant

## Security Notes[#security-notes](#security-notes)

- 

Entro never modifies or exports CloudTrail logs.
GitBook Assistant
- 

Access is limited to metadata analysis and contextual event mapping.
GitBook Assistant
- 

S3 objects remain within your AWS environment.
GitBook Assistant
- 

All communications use secure HTTPS/TLS endpoints.
GitBook Assistant

## Troubleshooting[#troubleshooting](#troubleshooting)
IssueCauseResolution

Entro cannot access logs
GitBook Assistant

Missing S3 permissions
GitBook Assistant

Add `s3:GetObject` and `s3:ListBucket` to the IAM Policy
GitBook Assistant

No CloudTrail data visible
GitBook Assistant

Trail not delivering to S3
GitBook Assistant

Verify CloudTrail delivery settings
GitBook Assistant

Partial event correlation
GitBook Assistant

Incorrect S3 path prefix
GitBook Assistant

Confirm Entro has the correct log folder path
GitBook Assistant[PreviousAssume Role Link to Entro](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/assume-role-link-to-entro)[NextCreating Trail CloudTrail Console](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/aws-cloudtrail-s3-setup/creating-trail-cloudtrail-console)

Last updated 4 months ago

- [Overview](#overview)
- [Navigation Path](#navigation-path)
- [Architecture Diagram](#architecture-diagram)
- [Prerequisites](#prerequisites)
- [Permissions Required](#permissions-required)
- [Setup Steps](#setup-steps)
- [Security Notes](#security-notes)
- [Troubleshooting](#troubleshooting)
S3 permissions (example)GitBook AssistantAskCopy
```
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:ListBucket"
  ],
  "Resource": [
    "arn:aws:s3:::<cloudtrail-logs-bucket>",
    "arn:aws:s3:::<cloudtrail-logs-bucket>/*"
  ]
}
```
