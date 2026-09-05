Active Directory Onboarding - Old | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/active-directory/active-directory-onboarding-1.md).
## Prerequisite[#prerequisite](#prerequisite)

- 

Network reachability from chosen **Worker Group (Connector)** to a Domain Controller.
GitBook Assistant

- 

LDAP port 389
GitBook Assistant
- 

Microsoft Global Catalog 3268
GitBook Assistant
- 

Microsoft Global Catalog 3269
GitBook Assistant
- 

LDAPS port 636
GitBook Assistant
- 

DNS resolution for DC hostnames
GitBook Assistant

- 

Service account UPN for LDAP bind (example: `svc_entro@corp.local`)
GitBook Assistant

- 

Must have **read** access to directory objects and attributes within all required target domains.
GitBook Assistant

- 

If LDAPS uses an internal Public CA Cert .Pem
GitBook Assistant
- 

Time synchronization (NTP) between connector and DCs.
GitBook Assistant
- 

Firewall rules allowing outbound to Entro
GitBook Assistant

## Account Onboarding[#account-onboarding](#account-onboarding)
1
#### Create service account on AD[#create-service-account-on-a-d](#create-service-account-on-a-d)

- 

Name: `svc_entro`
GitBook Assistant
- 

UPN: `svc_entro@<domain>`
GitBook Assistant
- 

Grant membership only to built-in groups required for read access. Do not assign elevated admin roles.
GitBook Assistant
2
#### Collect connector network info[#collect-connector-network-info](#collect-connector-network-info)

- 

Confirm the worker VM can resolve `dc01.example.local`.
GitBook Assistant
- 

Confirm LDAPS 636 connectivity:
GitBook Assistant
Test LDAPS connectivityGitBook AssistantAskCopy
```
openssl s_client -connect dc01.example.local:636 -showcerts
```
3
#### Export root Public CA PEM[#export-root-public-ca-pem](#export-root-public-ca-pem)

- 

Export the root CA to a PEM file (e.g. `root-ca.pem`).
GitBook Assistant
- 

Click [here](/integrations/security-and-identity/active-directory/active-directory-onboarding-1#export-public-ca-certificate) if you need assistance to export.
GitBook Assistant
- 

Provide the `root-ca.pem` file contents to Entro by pasting into the Root CA (PEM) field.
GitBook Assistant
4
#### In Entro Console[#in-entro-console](#in-entro-console)

- 

Navigate: **Management → Accounts & Integrations → Add New Account (top right) → Active Directory**
GitBook Assistant

Fill these fields when creating the integration in Entro.
GitBook Assistant

- 

**Nickname** - free text (e.g. ENTRO-PROD-AD)
GitBook Assistant
- 

**Domain Controller (DC)** - short name or primary DC hostname (e.g. DC01) or IP Address accessible via the domain network
GitBook Assistant
- 

**DC Name** - fully qualified DC name (e.g. dc01.example.local)
GitBook Assistant
- 

**Root CA (PEM)** -
GitBook Assistant
- 

**Domain** - AD domain (e.g. example.local)
GitBook Assistant
- 

**Username** - service account UPN (e.g. svc_entro@example.local)
GitBook Assistant
- 

**Password** - service account password (store securely)
GitBook Assistant
- 

**Environment Nickname** - environment label (e.g. PROD-AD)
GitBook Assistant
- 

**Environment Type** - Production / Staging / Dev
GitBook Assistant
- 

**Worker Group (Connector)** - choose the Worker Group that will run scans
GitBook Assistant
- 

Click **Connect**.
GitBook Assistant
Export Public CA Certificate[#export-public-ca-certificate](#export-public-ca-certificate)
#### **Option 1: Using OpenSSL (Linux, macOS, Windows with OpenSSL installed)**[#option-1-using-openssl-linux-macos-windows-with-openssl-installed](#option-1-using-openssl-linux-macos-windows-with-openssl-installed)

If your Root CA certificate is in an existing format (like `.crt`, `.cer`, `.der`, or `.pfx`), you can export it to a PEM file easily.
GitBook Assistant

**Step 1: Locate your Root CA certificate**
GitBook Assistant

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

**Step 2: Convert to PEM (if not already)**
GitBook Assistant

Depending on the format:
GitBook Assistant

**🔹 If it’s a DER (.der or .cer) file:**
GitBook AssistantGitBook AssistantAskCopy
```
openssl x509 -inform DER -in rootCA.cer -out root-ca.pem
```

**🔹 If it’s a CRT (.crt) file:**
GitBook AssistantGitBook AssistantAskCopy
```
openssl x509 -in rootCA.crt -out root-ca.pem
```

**🔹 If it’s a PFX / PKCS#12 (.pfx) file (contains private key + certs):**
GitBook AssistantGitBook AssistantAskCopy
```
openssl pkcs12 -in rootCA.pfx -out root-ca.pem -clcerts -nokeys
```

You’ll be asked for the import password (if the PFX is protected).
GitBook Assistant

**Step 3: Verify the PEM file**
GitBook Assistant

Check the output:
GitBook AssistantGitBook AssistantAskCopy
```
openssl x509 -in root-ca.pem -text -noout
```

You should see details like:
GitBook AssistantGitBook AssistantAskCopy
```
Issuer: CN = RootCA
Subject: CN = RootCA
```

That confirms you have the root CA certificate in PEM format.
GitBook Assistant
#### **Option 2: From Windows Certificate Store**[#option-2-from-windows-certificate-store](#option-2-from-windows-certificate-store)

If your Root CA is stored in the Windows Certificate Manager:
GitBook Assistant

**Step 1: Open the Certificate Manager**
GitBook Assistant

Press **Win + R** → type:
GitBook AssistantGitBook AssistantAskCopy
```
certmgr.msc
```

Press **Enter**.
GitBook Assistant

**Step 2: Locate the Root CA**
GitBook Assistant

Go to:
GitBook AssistantGitBook AssistantAskCopy
```
Trusted Root Certification Authorities → Certificates
```

Find your root CA certificate (look for the name in the list).
GitBook Assistant

**Step 3: Export the certificate**
GitBook Assistant

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

**Step 4: Rename or convert to PEM**
GitBook Assistant

You can simply rename it:
GitBook AssistantGitBook AssistantAskCopy
```
root-ca.cer → root-ca.pem
```

Or convert it using OpenSSL (optional):
GitBook AssistantGitBook AssistantAskCopy
```
openssl x509 -in root-ca.cer -out root-ca.pem
```
Export Public CA Certificate[#export-public-ca-certificate-1](#export-public-ca-certificate-1)
### **Option 1: Using OpenSSL (Linux, macOS, Windows with OpenSSL installed)**[#option-1-using-openssl-linux-macos-windows-with-openssl-installed-1](#option-1-using-openssl-linux-macos-windows-with-openssl-installed-1)

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
### **Option 2: From Windows Certificate Store**[#option-2-from-windows-certificate-store-1](#option-2-from-windows-certificate-store-1)

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
GitBook Assistant
## Security & Compliance Notes[#security-and-compliance-notes](#security-and-compliance-notes)

- 

Use LDAPS and enforce TLS 1.2+.
GitBook Assistant
- 

Do not grant write permissions to the service account.
GitBook Assistant
- 

Use internal secrets vault or encrypted channels for the password.
GitBook Assistant

Last updated 4 months ago

- [Prerequisite](#prerequisite)
- [Account Onboarding](#account-onboarding)
- [Security & Compliance Notes](#security-and-compliance-notes)
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
