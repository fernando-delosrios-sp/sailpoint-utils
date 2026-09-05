SharePoint Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/sharepoint/sharepoint-onboarding.md).

Follow these steps to integrate SharePoint with Entro Security using Microsoft Entra App Registration.
GitBook Assistant1
#### Step 1 - Configure API Permissions in Microsoft Entra[#step-1-configure-api-permissions-in-microsoft-entra](#step-1-configure-api-permissions-in-microsoft-entra)

- 

In Microsoft Entra Console, navigate to: Applications → App registrations → `Entro App` → API Permissions
GitBook Assistant
- 

Click **+ Add a permission**
GitBook Assistant
- 

Select **Microsoft Graph → Application permissions**
GitBook Assistant
- 

Enable the following permissions:
GitBook Assistant

- 

`User.Read.All`
GitBook Assistant
- 

`Directory.Read.All`
GitBook Assistant
- 

`Sites.Read.All`
GitBook Assistant
- 

`Files.Read.All`
GitBook Assistant
- 

`AuditLog.Read.All`
GitBook Assistant

- 

Click **Add Permission** for each permission above.
GitBook Assistant
- 

Click **Grant admin consent for...** and approve with **Yes**.
GitBook Assistant

Please reuse the same App Registration used for Azure onboarding
GitBook Assistant2
#### Step 2 - Complete Integration in Entro[#step-2-complete-integration-in-entro](#step-2-complete-integration-in-entro)

- 

If the Entro App for the same tenant as your SharePoint or OneDrive integration is already onboarded, no further action is required.
GitBook Assistant
- 

Otherwise, enter the **Client ID**, **Client Secret**, and **Tenant ID** in the Entro onboarding screen of `Microsoft Ecosystem` integration.
GitBook Assistant

## Security & Compliance Notes[#security-and-compliance-notes](#security-and-compliance-notes)

- 

Integration uses Microsoft Graph and SharePoint APIs in read-only mode
GitBook Assistant
- 

All data encrypted with AES-256 at rest and TLS 1.2+ in transit
GitBook Assistant
- 

Fully compliant with SOC 2 Type II, ISO 27001, and GDPR
GitBook Assistant
[PreviousSharePoint / OneDrive](/integrations/collaboration-and-saas/sharepoint)[NextSharePoint Troubleshooting And Validation](/integrations/collaboration-and-saas/sharepoint/sharepoint-troubleshooting-and-validation)

Last updated 2 months ago
