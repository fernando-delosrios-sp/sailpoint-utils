Configure Trail CloudTrail Console | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/aws-cloudtrail-s3-setup/configure-trail-cloudtrail-console.md).

After creating a CloudTrail trail, you must configure S3 bucket permissions so Entro can securely read audit logs. This enables correlation between AWS events and secret activity within Entro Security.
GitBook Assistant
## Navigation Path[#navigation-path](#navigation-path)

**AWS Console → CloudTrail → Trails → Select Trail → Storage Location (S3 Bucket)**
GitBook Assistant1
#### Open the CloudTrail Console[#open-the-cloudtrail-console](#open-the-cloudtrail-console)

- 

Sign in to the **AWS Management Console**.
GitBook Assistant
- 

Navigate to **CloudTrail → Trails**.
GitBook Assistant
- 

Select the trail you previously created (e.g. `EntroTrail`).
GitBook Assistant
- 

In the **Storage location** section, click the linked S3 bucket name.
GitBook Assistant
2
#### Edit the S3 Bucket Permissions[#edit-the-s3-bucket-permissions](#edit-the-s3-bucket-permissions)

- 

In the S3 Console, open the **Permissions** tab for your log bucket.
GitBook Assistant
- 

Scroll to **Bucket policy** and click **Edit**.
GitBook Assistant
- 

Add the following JSON snippet to grant Entro read access (replace placeholders with your values):
GitBook Assistant
s3-bucket-policy.jsonGitBook AssistantAskCopy
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::<ENTRO_ACCOUNT_ID>:root"
      },
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::<cloudtrail-logs-bucket>",
        "arn:aws:s3:::<cloudtrail-logs-bucket>/*"
      ]
    }
  ]
}
```
3
#### Save and Validate the Policy[#save-and-validate-the-policy](#save-and-validate-the-policy)

- 

Click **Save Changes**.
GitBook Assistant
- 

Return to **CloudTrail → Trails**.
GitBook Assistant
- 

Select your trail and confirm the S3 bucket path matches your intended destination.
GitBook Assistant
- 

Wait a few minutes for AWS to validate and apply the new permissions.
GitBook Assistant
4
#### Confirm Log Delivery and Access[#confirm-log-delivery-and-access](#confirm-log-delivery-and-access)

- 

Open the S3 bucket in AWS Console.
GitBook Assistant
- 

Ensure new log files are appearing under your account folder (`AWSLogs/<account-id>/CloudTrail/...`).
GitBook Assistant
- 

In Entro, verify that CloudTrail events are being ingested.
GitBook Assistant
5
#### Validation in Entro[#validation-in-entro](#validation-in-entro)

In the Entro Dashboard:
GitBook Assistant

- 

Go to **Integrations → AWS → CloudTrail S3 Setup**.
GitBook Assistant
- 

Confirm the CloudTrail integration status = **Connected**.
GitBook Assistant
- 

Check the **Activity Logs** tab for correlated events.
GitBook Assistant

## Troubleshooting[#troubleshooting](#troubleshooting)
Entro cannot read logs[#entro-cannot-read-logs](#entro-cannot-read-logs)

Cause:
GitBook Assistant

- 

Incorrect bucket policy
GitBook Assistant

Resolution:
GitBook Assistant

- 

Ensure the Entro role and AWS Account ID are listed as a principal in the bucket policy (see the JSON snippet above).
GitBook Assistant
Logs missing in S3[#logs-missing-in-s3](#logs-missing-in-s3)

Cause:
GitBook Assistant

- 

CloudTrail misconfiguration
GitBook Assistant

Resolution:
GitBook Assistant

- 

Verify CloudTrail log delivery is enabled and the configured bucket path is correct.
GitBook Assistant
Partial access[#partial-access](#partial-access)

Cause:
GitBook Assistant

- 

Missing `s3:ListBucket` permission
GitBook Assistant

Resolution:
GitBook Assistant

- 

Add the missing `s3:ListBucket` action in the bucket policy or IAM policy as appropriate.
GitBook Assistant

Security Notes
GitBook Assistant

- 

Entro uses **read-only access** to S3 log data.
GitBook Assistant
- 

No log modification, deletion, or external export occurs.
GitBook Assistant
- 

Access is authenticated through AWS STS AssumeRole and encrypted via HTTPS/TLS.
GitBook Assistant
[PreviousCreating Trail CloudTrail Console](/integrations/cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-manual-onboarding/aws-cloudtrail-s3-setup/creating-trail-cloudtrail-console)[NextAWS Troubleshooting and Validation](/integrations/cloud-and-infrastructure/amazon-web-services/aws-troubleshooting-and-validation)

Last updated 4 months ago

- [Navigation Path](#navigation-path)
- [Troubleshooting](#troubleshooting)
