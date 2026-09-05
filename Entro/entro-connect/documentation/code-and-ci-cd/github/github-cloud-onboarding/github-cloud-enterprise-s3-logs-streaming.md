GitHub Cloud Enterprise S3 Logs Streaming | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/code-and-ci-cd/github/github-cloud-onboarding/github-cloud-enterprise-s3-logs-streaming.md).

Entro can ingest GitHub Enterprise audit logs streamed into a designated AWS S3 Bucket for large-scale visibility and processing efficiency..
GitBook Assistant
## Prerequisites[#prerequisites](#prerequisites)

- 

Entro already connected to the AWS Account hosting the relevant S3 bucket.
GitBook Assistant
- 

Entro IAM role must have assigned AWS Policy with S3 Service permissions 
GitBook AssistantGitBook AssistantAskCopy
```
"s3:ListBucket",
"s3:GetObject"
```

## Configuration Steps[#configuration-steps](#configuration-steps)
1
#### In GitHub, Navigate to Log Streaming[#in-github-navigate-to-log-streaming](#in-github-navigate-to-log-streaming)

- 

Click on your profile avatar in the right side of your screen, then navigate to **Your Enterprises -> Settings -> Audit logs -> Log streaming **
GitBook Assistant

 and go back to Entro.In Entro account screen, either choose one existing GitHub organization onboarding account within your GitHub Enterprise, or add a new one.
GitBook Assistant2
### Configure Audit Log Streaming[#configure-audit-log-streaming](#configure-audit-log-streaming)

- 

Configure strean for "Amazon S3". Follow the Amazon S3 guide to setup bucket logs forwarding within your AWS account.
GitBook Assistant

- 

Once completed, save the bucket name and go back to Entro. 
GitBook Assistant
3
#### Configure in Entro after redirect (complete integration form)[#configure-in-entro-after-redirect-complete-integration-form](#configure-in-entro-after-redirect-complete-integration-form)

- 

After completing the [onboarding of GitHub App for your organization](/integrations/code-and-ci-cd/github/github-cloud-onboarding/githubcloud-app-manual-install)
GitBook Assistant
- 

Provide the **AWS Account** with the S3 bucket.
GitBook Assistant
- 

Enter the **S3 Bucket Name** used in GitHub streaming setup.
GitBook Assistant
4
#### Finalize[#finalize](#finalize)

Click **Connect** or **Update Account**.
GitBook Assistant[PreviousGitHub Cloud App Install (Recommended)](/integrations/code-and-ci-cd/github/github-cloud-onboarding/githubcloud-app-manual-install)[NextGitHub Cloud Fine-grained Token Onboarding](/integrations/code-and-ci-cd/github/github-cloud-onboarding/github-cloud-finegrained-token-onboarding)

Last updated 2 months ago

- [Prerequisites](#prerequisites)
- [Configuration Steps](#configuration-steps)
- [Configure Audit Log Streaming](#configure-audit-log-streaming)
