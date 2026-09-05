Active Directory Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/active-directory/active-directory-onboarding.md).
## Prerequisite[#prerequisite](#prerequisite)

- 

Network reachability from chosen **Worker Group (Connector)** to a Domain Controller.
GitBook Assistant

- 

LDAP TCP Por 389
GitBook Assistant
- 

LDAPS TCP Port 636
GitBook Assistant
- 

Microsoft Global Catalog TCP Port 3268
GitBook Assistant
- 

Microsoft Global Catalog TCP Port 3269
GitBook Assistant
- 

DNS resolution (UDP Port 53) for DC hostnames
GitBook Assistant

- 

Service account UPN for LDAP bind (example: `svc_entro@corp.local`)
GitBook Assistant

- 

Must have **read** access to directory objects and attributes within all required target domains.
GitBook Assistant

1
#### Create the Service Account in Active Directory[#create-the-service-account-in-active-directory](#create-the-service-account-in-active-directory)

- 

**Name**: `svc_entro`
GitBook Assistant
- 

**UPN**: `svc_entro@<domain>`
GitBook Assistant
- 

Assign **read-only built-in group permissions only**.
GitBook Assistant
- 

Do **not** grant any elevated admin roles.
GitBook Assistant
2
#### Collect Connector Network Information[#collect-connector-network-information](#collect-connector-network-information)

**Validate DNS Resolution**
GitBook Assistant

Ensure the Worker VM can resolve the domain controller FQDN:
GitBook AssistantGitBook AssistantAskCopy
```
dc01.example.local
```

**Validate LDAPS Connectivity (Port 636)**
GitBook AssistantGitBook AssistantAskCopy
```
openssl s_client -connect dc01.example.local:636 -showcerts
```

If the connection succeeds, LDAPS is reachable.
GitBook Assistant3
#### Copy the Root CA Certificate[#copy-the-root-ca-certificate](#copy-the-root-ca-certificate)

Entro expects the **raw certificate text**, not a file upload.
GitBook Assistant

If you need further assistance with retrieving the certificate please see "export public certificate" below.
GitBook Assistant

Steps:
GitBook Assistant

- 

Open the **Root CA certificate** (`.cer`) in a text editor such as Notepad or VS Code.
GitBook Assistant
- 

Copy the **entire certificate block**, including the headers and footers:
GitBook Assistant
GitBook AssistantAskCopy
```
-----BEGIN CERTIFICATE-----
...certificate data...
-----END CERTIFICATE-----
```

- 

Paste this text directly into the **Root CA (PEM)** field in the Entro Console.
GitBook Assistant

The certificate field is **multiline**. Ensure the full block is pasted with no extra spaces or missing lines.
GitBook Assistant
## In Entro Console[#in-entro-console](#in-entro-console)

Navigate: **Management → Accounts & Integrations → Add New Account → Active Directory**
GitBook Assistant

Fill out the following fields:
GitBook Assistant
#### Integration Fields[#integration-fields](#integration-fields)

- 

**Nickname** Free-text label for identification Example: `ENTRO-PROD-AD`
GitBook Assistant
- 

**Domain Controller (DC)** Short hostname or IP of the primary DC Example: `DC01` or `10.0.0.5`
GitBook Assistant
- 

**DC Name (FQDN)** Fully qualified domain controller name Example: `dc01.example.local`
GitBook Assistant
> 

*Both the short name/IP and the FQDN are required by the current connector version.*
GitBook Assistant
- 

**Root CA (PEM)** Paste the full certificate text copied above.
GitBook Assistant
- 

**Domain** Active Directory domain Example: `example.local`
GitBook Assistant
- 

**Username** Service account UPN Example: `svc_entro@example.local`
GitBook Assistant
- 

**Password** Service account password
GitBook Assistant
- 

**Environment Nickname** Human-readable label for this deployment Example: `PROD-AD`
GitBook Assistant
- 

**Environment Type** `Production` / `Staging` / `Dev`
GitBook Assistant
- 

**Worker Group (Connector)** Select the Connector/Outpost that will run the AD scans.
GitBook Assistant

Click **Connect** to complete onboarding.
GitBook AssistantExport Public CA Certificate[#export-public-ca-certificate](#export-public-ca-certificate)
### **Option 1: Using OpenSSL (Linux, macOS, Windows with OpenSSL installed)**[#option-1-using-openssl-linux-macos-windows-with-openssl-installed](#option-1-using-openssl-linux-macos-windows-with-openssl-installed)

If your Root CA certificate is in an existing format (like `.crt`, `.cer`, `.der`, or `.pfx`), you can export it to a PEM file easily.
GitBook Assistant
#### **Step 1: Locate your Root CA certificate**[#step-1-locate-your-root-ca-certificate](#step-1-locate-your-root-ca-certificate)

Find the file (for example):
GitBook Assistant

- 

`rootCA.crt`
GitBook Assistant
- 

`rootCA.cer`
GitBook Assistant
- 

or part of a PKCS#12 bundle (like `rootCA.pfx`).
GitBook Assistant

#### **Step 2: Convert to PEM (if not already)**[#step-2-convert-to-pem-if-not-already](#step-2-convert-to-pem-if-not-already)

Depending on the format:
GitBook Assistant

**🔹 If it’s a DER (.der or .cer) file:**
GitBook Assistant

**🔹 If it’s a CRT (.crt) file:**
GitBook Assistant

**🔹 If it’s a PFX / PKCS#12 (.pfx) file (contains private key + certs):**
GitBook Assistant

You’ll be asked for the import password (if the PFX is protected).
GitBook Assistant
#### **Step 3: Verify the PEM file**[#step-3-verify-the-pem-file](#step-3-verify-the-pem-file)

Check the output:
GitBook Assistant

You should see details like:
GitBook Assistant

That confirms you have the root CA certificate in PEM format.
GitBook Assistant
### **Option 2: From Windows Certificate Store**[#option-2-from-windows-certificate-store](#option-2-from-windows-certificate-store)

If your Root CA is stored in the Windows Certificate Manager:
GitBook Assistant
#### **Step 1: Open the Certificate Manager**[#step-1-open-the-certificate-manager](#step-1-open-the-certificate-manager)

Press **Win + R** → type:
GitBook Assistant

Press **Enter**.
GitBook Assistant
#### **Step 2: Locate the Root CA**[#step-2-locate-the-root-ca](#step-2-locate-the-root-ca)

Go to:
GitBook Assistant

Find your root CA certificate (look for the name in the list).
GitBook Assistant
#### **Step 3: Export the certificate**[#step-3-export-the-certificate](#step-3-export-the-certificate)

Right-click → **All Tasks → Export** → follow the wizard:
GitBook Assistant

- 

Choose **No, do not export the private key**
GitBook Assistant
- 

Select **Base-64 encoded X.509 (.CER)** format
GitBook Assistant
- 

Save it as `root-ca.cer`
GitBook Assistant

#### **Step 4: Rename or convert to PEM**[#step-4-rename-or-convert-to-pem](#step-4-rename-or-convert-to-pem)

You can simply rename it:
GitBook Assistant

Or convert it using OpenSSL (optional):
GitBook AssistantTroubleshooting: Certificate Issues[#troubleshooting-certificate-issues](#troubleshooting-certificate-issues)

- 

Ensure the certificate contains the **BEGIN** and **END** lines.
GitBook Assistant
- 

Do not add or remove line breaks.
GitBook Assistant
- 

Certificate must be **Base64-encoded X.509**.
GitBook Assistant
- 

Confirm port **636** is reachable and DNS resolves the DC correctly.
GitBook Assistant

Security & Compliance Notes
GitBook Assistant

- 

LDAPS should always run over **TLS 1.2+**.
GitBook Assistant
- 

Do **not** assign write permissions to the service account.
GitBook Assistant
- 

Passwords should be stored in your internal secrets vault or a secure encrypted channel.
GitBook Assistant
[PreviousActive Directory](/integrations/security-and-identity/active-directory)[NextActive Directory Troubleshooting And Validation](/integrations/security-and-identity/active-directory/active-directory-troubleshooting-and-validation)

Last updated 2 months ago

- [Prerequisite](#prerequisite)
- [In Entro Console](#in-entro-console)
GitBook AssistantAskCopy
```
openssl x509 -inform DER -in rootCA.cer -out root-ca.pem
```
GitBook AssistantAskCopy
```
openssl x509 -in rootCA.crt -out root-ca.pem
```
GitBook AssistantAskCopy
```
openssl pkcs12 -in rootCA.pfx -out root-ca.pem -clcerts -nokeys
```
GitBook AssistantAskCopy
```
openssl x509 -in root-ca.pem -text -noout
```
GitBook AssistantAskCopy
```
Issuer: CN = RootCA
Subject: CN = RootCA
```
GitBook AssistantAskCopy
```
certmgr.msc
```
GitBook AssistantAskCopy
```
Trusted Root Certification Authorities → Certificates
```
GitBook AssistantAskCopy
```
root-ca.cer → root-ca.pem
```
GitBook AssistantAskCopy
```
openssl x509 -in root-ca.cer -out root-ca.pem
```
