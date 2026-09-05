Exposed Secrets | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/settings/exposed-secrets.md).

The **Exposed Secrets** section allows administrators to configure how Entro manages, validates, and automates the handling of discovered secrets across connected environments. These settings help reduce false positives, improve triage efficiency, and maintain a consistent, secure approach to secret detection.
GitBook Assistant

Each configuration option updates automatically and applies to future scans and detections.
GitBook Assistant
### **Excluded “Not-a-secret” Hashes**[#excluded-not-a-secret-hashes](#excluded-not-a-secret-hashes)

The **Excluded “Not-a-secret” hashes** table lists all secrets that have been explicitly marked as **“Not a secret”** in the **Exposed Inventory**.
GitBook Assistant

This process helps reduce noise in the system by removing non-sensitive values that may resemble credentials but pose no actual risk.
GitBook Assistant

Each excluded entry includes:
GitBook Assistant

- 

**Hash:** A unique identifier of the excluded secret.
GitBook Assistant
- 

**Secret Snippet:** A short, redacted preview for reference.
GitBook Assistant
- 

**Exclusion Timestamp:** The date and time when the secret was marked as “Not a Secret.”
GitBook Assistant
- 

**Excluded By:** Indicates who or what performed the exclusion.
GitBook Assistant

> 

⚠️ **Note: **Once a secret is added to the exclusion list, it will no longer appear in scans or trigger risk alerts unless the exclusion is manually removed.
GitBook Assistant[PreviousCustom Severity Rules](/administration/settings/custom-severity-rules)[NextOrganization Configuration](/administration/settings/organization-configuration)

Last updated 10 months ago
