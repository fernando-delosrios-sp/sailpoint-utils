Google Workspace GDrive Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/google-workspace-google-drive/google-workspace-gdrive-onboarding.md).
### **GCP integration is required prior to the GDrive onboarding. If the onboarding wasn't completed yet, please use this** [**guide**](/integrations/cloud-and-infrastructure/google-cloud-platform-1)**. Else, skip to step 2.**[#gcp-integration-is-required-prior-to-the-gdrive-onboarding.-if-the-onboarding-wasnt-completed-yet-pl](#gcp-integration-is-required-prior-to-the-gdrive-onboarding.-if-the-onboarding-wasnt-completed-yet-pl)

Follow the steps below to integrate Google Workspace (GDrive) with Entro Security for secure, read-only scanning of files and shared drives.
GitBook Assistant
## **Navigation Path**[#navigation-path](#navigation-path)

**Management → Accounts & Integrations → Add New Account (top right) → Google Workspace (GDrive)**
GitBook Assistant1
#### Step 1 - Onboard via GCP Service Account[#step-1-onboard-via-gcp-service-account](#step-1-onboard-via-gcp-service-account)

To integrate Google Workspace with Entro, use a **GCP Service Account**. You can either reuse an existing account from your GCP Integration or create a new one dedicated to GDrive.
GitBook Assistant

Entro supports two authorization methods:
GitBook Assistant

- 

**Service Account Key**
GitBook Assistant
- 

**Workload Identity Federation**
GitBook Assistant

> 

**If using Workload Identity Federation:** The service account must have the **Service Account Token Creator** role (`roles/iam.serviceAccountTokenCreator`) assigned to itself. This allows server-side JWT signing required for Google Workspace access.
GitBook Assistant

To configure: GCP Console → IAM & Admin → IAM → find your service account → Edit → Add Role → "Service Account Token Creator" → Save.
GitBook Assistant

2
#### Step 2 - Enable Google Drive API[#step-2-enable-google-drive-api](#step-2-enable-google-drive-api)

- 

Log in to your **Google Cloud Console**.
GitBook Assistant
- 

Navigate to **APIs & Services → Library → Google Drive API**.
GitBook Assistant
- 

Select your project (same one used for the Service Account).
GitBook Assistant
- 

Click **Enable** if not already enabled.
GitBook Assistant
- 

Optionally, enable the **Admin SDK API** for organization-wide scanning.
GitBook Assistant
3
#### Step 3 - Grant Access to Google Drive Files[#step-3-grant-access-to-google-drive-files](#step-3-grant-access-to-google-drive-files)

You can either grant access to specific drives (Option 1) or allow domain-wide scanning (Option 2).
GitBook Assistant1

**Option 1 - Share Specific Drives**
GitBook Assistant

- 

Open Google Drive.
GitBook Assistant
- 

Right-click the target drive, folder, or file and choose **Manage members**.
GitBook Assistant
- 

Enter your Service Account email and assign one of the following roles:
GitBook Assistant

- 

**Viewer:** Scans the most recent version of each file.
GitBook Assistant
- 

**Contributor:** Allows review of version history.
GitBook Assistant

- 

Shared drives from external organizations can also be scanned if permission is granted.
GitBook Assistant
2

**Option 2 - Allow Access to All Files (Domain-Wide Delegation)**
GitBook Assistant

1. 

Retrieve your Service Account **Client ID** from the GCP Console.
GitBook Assistant
1. 

In your **Google Workspace Admin Console**, navigate to: **Security → Access and data control → API controls → Domain-wide delegation**
GitBook Assistant
1. 

Click **Add new** and insert:
GitBook Assistant

- 

The **Client ID** from step 1
GitBook Assistant
- 

The following OAuth scopes:
GitBook Assistant

GitBook AssistantAskCopy
```
https://www.googleapis.com/auth/admin.directory.group.readonly
https://www.googleapis.com/auth/admin.directory.group.member.readonly
https://www.googleapis.com/auth/drive.readonly
https://www.googleapis.com/auth/cloud-platform
https://www.googleapis.com/auth/admin.directory.user.readonly
https://www.googleapis.com/auth/admin.directory.customer.readonly
```

1. 

Click **Authorize** to complete domain-wide delegation.
GitBook Assistant
4
#### Step 4 - Complete Entro Onboarding[#step-4-complete-entro-onboarding](#step-4-complete-entro-onboarding)

In the Entro Dashboard:
GitBook Assistant

- 

Navigate to **Management → Accounts & Integrations → Google Workspace (GDrive)**
GitBook Assistant
- 

Fill in the onboarding form:
GitBook Assistant

- 

**GCP Project:** Select your Service Account project
GitBook Assistant
- 

**Google Workspace Domain:** Enter your organization domain
GitBook Assistant
- 

**Admin Email:** Provide an admin user email for impersonation
GitBook Assistant

- 

Click **Create Account** to finalize onboarding.
GitBook Assistant

## Security & Compliance[#security-and-compliance](#security-and-compliance)

- 

Read-only data retrieval (no modification of file content)
GitBook Assistant
- 

TLS 1.2+ encryption
GitBook Assistant
- 

AES-256 at rest
GitBook Assistant
- 

SOC 2 Type II, ISO 27001, GDPR compliant
GitBook Assistant
[PreviousGoogle Workspace - Google Drive](/integrations/collaboration-and-saas/google-workspace-google-drive)[NextGoogle Workspace GDrive Troubleshooting And Validation](/integrations/collaboration-and-saas/google-workspace-google-drive/google-workspace-gdrive-troubleshooting-and-validation)

Last updated 2 months ago

- [Navigation Path](#navigation-path)
- [Security & Compliance](#security-and-compliance)
