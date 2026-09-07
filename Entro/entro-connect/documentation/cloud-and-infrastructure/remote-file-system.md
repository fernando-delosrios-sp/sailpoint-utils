Remote File System | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/remote-file-system.md).

Entro integrates with your organization's remote machines - supporting both **SMB** and **SFTP** protocols to detect exposed secrets used in remote file systems. This integration provides continuous discovery and monitoring of credentials, API keys, and tokens stored within network shares and remote servers. By analyzing files and folders, Entro prevents secret leakage and privilege escalation.
GitBook Assistant
### Onboarding Options[#onboarding-options](#onboarding-options)

**1.** [**SMB File Shares**](/integrations/cloud-and-infrastructure/remote-file-system/smb-file-shares-onboarding)
GitBook Assistant

Use this option to connect to file share servers over SMB. This method supports authentication using service account credentials and allows scanning of accessible shared directories.
GitBook Assistant

**Required Fields:**
GitBook Assistant

- 

Nickname
GitBook Assistant
- 

Host/IP of file share
GitBook Assistant
- 

Username and password
GitBook Assistant
- 

Worker Group (Connector)
GitBook Assistant

Optional:
GitBook Assistant

- 

Excluded shares
GitBook Assistant

> 

✅ Best suited for Windows-based environments or when accessing shared network drives.
GitBook Assistant
#### **2.** [**SFTP (SSH-based Access)**](/integrations/cloud-and-infrastructure/remote-file-system/sftp-ssh-onboarding)[#id-2.-sftp-ssh-based-access](#id-2.-sftp-ssh-based-access)

Use this method to connect directly to remote VM or server file systems using SFTP over SSH. This provides direct access to folders without requiring a file share setup.
GitBook Assistant

**Authentication Options:**
GitBook Assistant

- 

SSH Private Key (recommended)
GitBook Assistant
- 

Password (if key is not available)
GitBook Assistant

**Required Fields:**
GitBook Assistant

- 

Nickname
GitBook Assistant
- 

Host/IP of remote server
GitBook Assistant
- 

Username
GitBook Assistant
- 

Private Key **or** Password
GitBook Assistant
- 

Worker Group (Connector)
GitBook Assistant

Optional fields:
GitBook Assistant

- 

Passphrase (When using private key)
GitBook Assistant
- 

Target Directories to scan
GitBook Assistant
- 

Target File extensions to scan
GitBook Assistant

> 

✅ Ideal for Linux/Unix-based environments or when working directly with cloud-hosted VMs
GitBook Assistant
#### **3.** [**WinRM Onboarding**](/integrations/cloud-and-infrastructure/remote-file-system/winrm-onboarding)[#id-2.-sftp-ssh-based-access-1](#id-2.-sftp-ssh-based-access-1)

Use this method to connect directly to remote VM or server file systems using WinRM. This provides direct access to folders without requiring a file share setup.
GitBook Assistant

**Authentication Options:**
GitBook Assistant

- 

Kerberos
GitBook Assistant
- 

SSH Private Key (recommended)
GitBook Assistant
- 

Password (if key is not available)
GitBook Assistant

**Required Fields:**
GitBook Assistant

- 

Nickname
GitBook Assistant
- 

Host/IP of remote server
GitBook Assistant
- 

Username
GitBook Assistant
- 

Private Key **or** Password
GitBook Assistant
- 

Worker Group (Connector)
GitBook Assistant

Optional fields:
GitBook Assistant

- 

Passphrase (When using private key)
GitBook Assistant
- 

Target Directories to scan
GitBook Assistant
- 

Target File extensions to scan
GitBook Assistant

> 

✅ Ideal for Microsoft-based environments or when working directly with cloud-hosted VMs
GitBook Assistant[PreviousOCI Permissions Reference](/integrations/cloud-and-infrastructure/oci/oci-permissions-reference)[NextSMB File Shares Onboarding](/integrations/cloud-and-infrastructure/remote-file-system/smb-file-shares-onboarding)

Last updated 4 months ago
