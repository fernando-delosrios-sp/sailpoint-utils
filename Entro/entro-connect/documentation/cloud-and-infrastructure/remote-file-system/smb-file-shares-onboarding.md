SMB File Shares Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/remote-file-system/smb-file-shares-onboarding.md).

This page describes both supported onboarding options: **Manual Onboarding** and **JSON Upload**.
GitBook Assistant
## Option 1 - Manual Onboarding[#option-1-manual-onboarding](#option-1-manual-onboarding)
1
#### Create a service account[#create-a-service-account](#create-a-service-account)

Create a **service account** with **read permissions** over your file shares. Save the credentials for later.
GitBook Assistant2
#### Open Accounts & Integrations[#open-accounts-and-integrations](#open-accounts-and-integrations)

Log in to Entro and go to **Management → Accounts & Integrations**.
GitBook Assistant3
#### Add new account[#add-new-account](#add-new-account)

Click **Add new account** and choose **File Shares Scanning**.
GitBook Assistant4
#### Enter credentials[#enter-credentials](#enter-credentials)

Enter the following credential details in the onboarding form:
GitBook AssistantFieldDescription

**Nickname**
GitBook Assistant

Name to display in Entro for this file share
GitBook Assistant

**Username**
GitBook Assistant

The service account name, including domain (e.g. `myOrg.demo\johndoe`)
GitBook Assistant

**Password**
GitBook Assistant

The password for the service account
GitBook Assistant

**File Share IP or Hostname**
GitBook Assistant

e.g. `183.12.13.13:445` or `FILE‑SHARE.myOrg.demo:445` (ensure port 445 is included)
GitBook Assistant

**Worker Group**
GitBook Assistant

Select your assigned Worker Group. If unsure, contact [support@entro.security](mailto:support@entro.security)
GitBook Assistant5
#### Next[#next](#next)

Click **Next**.
GitBook Assistant6
#### Optional: Exclude shares[#optional-exclude-shares](#optional-exclude-shares)

On the 2nd step, specify file shares to **exclude** from scanning.
GitBook Assistant

- 

Enter each file share name on the server to exclude.
GitBook Assistant
- 

Click **Save** when complete.
GitBook Assistant

## [#undefined](#undefined)

## Option 2 - JSON Upload (Bulk Onboarding)[#option-2-json-upload-bulk-onboarding](#option-2-json-upload-bulk-onboarding)
1
#### Create a service account[#create-a-service-account-1](#create-a-service-account-1)

Create a **service account** with **read permissions** over your shares. Save the credentials.
GitBook Assistant2
#### Open Accounts & Integrations[#open-accounts-and-integrations-1](#open-accounts-and-integrations-1)

Log in to Entro → **Management → Accounts & Integrations → Add new account → File Shares Scanning**.
GitBook Assistant3
#### Choose JSON Upload[#choose-json-upload](#choose-json-upload)

Choose the **JSON Upload** option.
GitBook Assistant4
#### Select Worker Group[#select-worker-group](#select-worker-group)

Select your assigned **Worker Group**. If you are unsure, contact [support@entro.security](mailto:support@entro.security).
GitBook Assistant5
#### Review template[#review-template](#review-template)

Review the [provided JSON template](/integrations/cloud-and-infrastructure/remote-file-system/smb-file-shares-onboarding#example-json-for-3-servers) and example. Download it for editing.
GitBook Assistant6
#### Upload JSON[#upload-json](#upload-json)

Upload the edited JSON file in Entro.
GitBook Assistant7
#### Save[#save](#save)

Click **Save** to complete onboarding.
GitBook Assistant
### JSON Fields[#json-fields](#json-fields)
FieldDescription

**nickname**
GitBook Assistant

The file share name to be displayed in Entro
GitBook Assistant

**user**
GitBook Assistant

Full username path (e.g. `myOrg.demo\johndoe`)
GitBook Assistant

**password**
GitBook Assistant

The service account password
GitBook Assistant

**url**
GitBook Assistant

The file share IP or hostname (e.g. `183.12.13.13:445`)
GitBook Assistant

**ignore_shares**
GitBook Assistant

Array of share names to exclude from scanning
GitBook Assistant
### Example JSON for 3 Servers[#example-json-for-3-servers](#example-json-for-3-servers)
[PreviousRemote File System](/integrations/cloud-and-infrastructure/remote-file-system)[NextSFTP (SSH) Onboarding](/integrations/cloud-and-infrastructure/remote-file-system/sftp-ssh-onboarding)

Last updated 4 months ago

- [Option 1 - Manual Onboarding](#option-1-manual-onboarding)
- [#undefined](#undefined)
- [Option 2 - JSON Upload (Bulk Onboarding)](#option-2-json-upload-bulk-onboarding)
- [JSON Fields](#json-fields)
- [Example JSON for 3 Servers](#example-json-for-3-servers)
smb-file-shares.jsonGitBook AssistantAskCopy
```
[
  {
    "nickname": "ENVIRONMENT_NAME",
    "user": "USERNAME_PATH",
    "password": "PASSWORD",
    "url": "FILE_SHARE_IP_WITH_PORT_OR_HOSTNAME",
    "ignore_shares": [
      "FILESHARE_NAME", "FILESHARE_NAME", "FILESHARE_NAME"
    ]
  },
  {
    "nickname": "ENVIRONMENT_NAME",
    "user": "USERNAME_PATH",
    "password": "PASSWORD",
    "url": "FILE_SHARE_IP_WITH_PORT_OR_HOSTNAME",
    "ignore_shares": [
      "FILESHARE_NAME", "FILESHARE_NAME", "FILESHARE_NAME"
    ]
  },
  {
    "nickname": "ENVIRONMENT_NAME",
    "user": "USERNAME_PATH",
    "password": "PASSWORD",
    "url": "FILE_SHARE_IP_WITH_PORT_OR_HOSTNAME",
    "ignore_shares": [
      "FILESHARE_NAME", "FILESHARE_NAME", "FILESHARE_NAME"
    ]
  }
]
```
