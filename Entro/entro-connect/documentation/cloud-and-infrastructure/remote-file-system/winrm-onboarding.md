WinRM Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/remote-file-system/winrm-onboarding.md).1
#### Open Accounts & Integrations[#open-accounts-and-integrations](#open-accounts-and-integrations)

Log in to Entro and go to **Management → Accounts & Integrations**.
GitBook Assistant2
#### Add new account[#add-new-account](#add-new-account)

Click **Add new account** and choose **File Shares Scanning**.
GitBook Assistant3
#### Enter credentials[#enter-credentials](#enter-credentials)

Enter the following credential details in the onboarding form:
GitBook AssistantFieldDescription

**Nickname**
GitBook Assistant

Name to display in Entro for this integration
GitBook Assistant

**Host**
GitBook Assistant

DNS or public IP of the remote server. *Multiple hosts can be configured*.
GitBook Assistant

**Username**
GitBook Assistant

WinRM user with read access.
GitBook Assistant

**Password OR Private Key** 
GitBook Assistant

Either password or Private Key used for authentication.
GitBook Assistant

**Passphrase (optional)**
GitBook Assistant

Optional when using Private Key.
GitBook Assistant4
#### Select Target files to be scanned (optional)[#select-target-files-to-be-scanned-optional](#select-target-files-to-be-scanned-optional)

- 

**Target Directories (Optional)**: List absolute paths separated by commas.
GitBook Assistant
- 

**File Extensions (Optional)**: list of file extensions to be scanned(e.g., `.json, .yaml`).
GitBook Assistant

By default, following directories will be scanned: /home, /etc, /tmp, /mnt with all available file types
GitBook Assistant5
#### Select Worker Group[#select-worker-group](#select-worker-group)

Choose your assigned entro connector with access to the required hosts.
GitBook Assistant6
#### Create Account[#create-account](#create-account)

Click on ‘Create Account’ to launch this integration
GitBook Assistant

[https://app.gitbook.com/s/kBc5agk1d2vaiel2LYpL](https://app.gitbook.com/s/kBc5agk1d2vaiel2LYpL)
[PreviousSFTP (SSH) Onboarding](/integrations/cloud-and-infrastructure/remote-file-system/sftp-ssh-onboarding)[NextRemote File System Troubleshooting And Validation](/integrations/cloud-and-infrastructure/remote-file-system/remote-file-system-troubleshooting-and-validation)

Last updated 4 months ago
