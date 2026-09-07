Creating Trail CloudTrail Console | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/aws-cloudtrail-s3-setup/creating-trail-cloudtrail-console.md).1
#### Open the CloudTrail Console[#open-the-cloudtrail-console](#open-the-cloudtrail-console)

1. 

Sign in to the **AWS Management Console**.
GitBook Assistant
1. 

Navigate to **CloudTrail → Trails → Create Trail**.
GitBook Assistant
1. 

Click **Create Trail**.
GitBook Assistant
2
#### Configure Basic Trail Settings[#configure-basic-trail-settings](#configure-basic-trail-settings)
FieldValue / Description

**Trail name**
GitBook Assistant

`EntroTrail` (or another descriptive name)
GitBook Assistant

**Storage location**
GitBook Assistant

Select **Create a new S3 bucket**
GitBook Assistant

**S3 bucket name**
GitBook Assistant

Use a unique name, e.g. `entro-cloudtrail-logs-prod`
GitBook Assistant

**Log file SSE-KMS encryption**
GitBook Assistant

(Optional) Enable if KMS encryption is required
GitBook Assistant

**Enable CloudWatch Logs**
GitBook Assistant

Optional, for real-time streaming (Entro does not require this)
GitBook Assistant3
#### Choose Event Types[#choose-event-types](#choose-event-types)

In the **Event type** section, select the following:
GitBook Assistant

- 

**Management events**
GitBook Assistant
- 

**Data events** (recommended for broader coverage)
GitBook Assistant
- 

**Read/Write events** → choose **All**
GitBook Assistant

This ensures Entro has complete context around API calls, secret reads, and key management actions.
GitBook Assistant4
#### Review and Create[#review-and-create](#review-and-create)

1. 

Review all settings.
GitBook Assistant
1. 

Click **Create Trail**.
GitBook Assistant
1. 

Wait for confirmation that the trail has been successfully created.
GitBook Assistant
5
#### Verify Log Delivery to S3[#verify-log-delivery-to-s3](#verify-log-delivery-to-s3)

1. 

Navigate to **S3 → Buckets → entro-cloudtrail-logs-prod** (or your selected name).
GitBook Assistant
1. 

Confirm that a folder structure appears for each region: `AWSLogs/<account-id>/CloudTrail/<region>/YYYY/MM/DD/...`
GitBook Assistant
1. 

Wait for initial log delivery (~15 minutes).
GitBook Assistant
6
#### Apply Entro Access Permissions[#apply-entro-access-permissions](#apply-entro-access-permissions)

If you are setting up Entro CloudTrail integration, ensure that the bucket policy allows Entro’s role to read logs. Follow: [Configure a Trail with the CloudTrail Console →](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/aws-cloudtrail-s3-setup/configure-trail-cloudtrail-console)
GitBook Assistant

Security Notes
GitBook Assistant

- 

Logs remain in your S3 bucket; Entro accesses them via read-only IAM permissions.
GitBook Assistant
- 

You retain full control over log lifecycle, retention, and encryption settings.
GitBook Assistant
- 

CloudTrail automatically applies least-privilege principles to its internal write actions.
GitBook Assistant
[PreviousAWS CloudTrail S3 Setup](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/aws-cloudtrail-s3-setup)[NextConfigure Trail CloudTrail Console](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/aws-cloudtrail-s3-setup/configure-trail-cloudtrail-console)

Last updated 4 months ago
