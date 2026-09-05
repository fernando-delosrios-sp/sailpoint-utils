OCI Troubleshooting And Validation | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/oci/oci-troubleshooting-and-validation.md).

This section provides validation steps and troubleshooting procedures for the Oracle Cloud Infrastructure integration.
GitBook Assistant
## Validation Steps[#validation-steps](#validation-steps)

After clicking Connect, verify the following:
GitBook Assistant

1. 

**Account Status:** Ensure the status shows **Verified** in the Entro Console.
GitBook Assistant

1. 

If an **Error** status is shown, click on it to see the error message.
GitBook Assistant

1. 

**Initial Scan:** Confirm that OCI users appear in the **NHI Inventory** section.
GitBook Assistant
1. 

**Sync Timestamp:** Check the **Last Sync** time on the OCI integration card.
GitBook Assistant

#### Common Issues[#common-issues](#common-issues)

**Issue**
GitBook Assistant

**Potential Cause**
GitBook Assistant

**Resolution**
GitBook Assistant

Status: Error (401 error)
GitBook Assistant

Incorrect OCID or Fingerprint.
GitBook Assistant

Double-check the Tenancy OCID and User OCID from the OCI Console.
GitBook Assistant

Invalid Signature
GitBook Assistant

Private Key mismatch.
GitBook Assistant

Ensure the pasted PEM content includes the `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----` headers.
GitBook Assistant

Permission Denied
GitBook Assistant

Missing IAM Policies.
GitBook Assistant

Verify that the `entro-readers` group has all five required policy statements applied at the tenancy level.
GitBook Assistant

Region Error
GitBook Assistant

Mismatched region.
GitBook Assistant

Ensure the region provided (e.g., `us-phoenix-1`) matches the home region where the API key was generated.
GitBook Assistant
#### Advanced Diagnostics[#advanced-diagnostics](#advanced-diagnostics)

If connection fails, Entro performs a "smoke test" by attempting to `ListCompartments`. If this fails with a `401 Unauthorized`, the API key or signature is invalid. If it fails with `403 Forbidden`, the IAM policies are likely missing.
GitBook Assistant[PreviousOCI Onboarding](/integrations/cloud-and-infrastructure/oci/oci-onboarding)[NextOCI Permissions Reference](/integrations/cloud-and-infrastructure/oci/oci-permissions-reference)

Last updated 2 months ago
