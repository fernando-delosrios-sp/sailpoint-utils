Request New Secret | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/administration/settings/request-new-secret.md).

The **Request New Secret** page allows administrators to request detection support for secret types that are not yet recognized by Entro. By submitting details about your secret’s format, prefix, or validation logic, you help Entro expand its detection coverage and improve accuracy across diverse environments.
GitBook Assistant
### **Submitting a Request**[#submitting-a-request](#submitting-a-request)

To submit a new secret type for support:
GitBook Assistant

1. 

Navigate to **Settings → Request New Secret**.
GitBook Assistant
1. 

Complete the **Custom Secret Support Form** by providing as much detail as possible.
GitBook Assistant

**The form includes the following fields**:
GitBook Assistant

- 

**Target Service Name** *(required)* — The name of the platform, app, or service using the secret.
GitBook Assistant
- 

**Secret Example** *(required)* — One or more representative examples of the secret format.
GitBook Assistant
- 

**Service URL** *(optional)* — A link to the service or API documentation for additional context.
GitBook Assistant
- 

**Regex Pattern** *(optional)* — The detection pattern (regex) used to identify the secret structure.
GitBook Assistant
- 

**Secret Prefix** *(optional)* — Any known prefix associated with the secret type.
GitBook Assistant
- 

**Validators and Expected Response** *(optional)* — Example API calls or validator endpoints used to verify secret authenticity.
GitBook Assistant

### **Review and Support**[#review-and-support](#review-and-support)

Once submitted, the Entro research team reviews your request and evaluates the secret for detection support. If approved, the new secret type will be incorporated into Entro’s detection engine and automatically available for your organization and other users in future updates.
GitBook Assistant
> 

💡 **Tip:** Provide as much detail as possible — including real examples and validation logic — to help Entro replicate the detection pattern accurately.
GitBook Assistant[PreviousRisk Configuration](/administration/settings/risk-configuration)[NextExclusion Rule](/administration/settings/exclusion-rule)

Last updated 10 months ago

- [Submitting a Request](#submitting-a-request)
- [Review and Support](#review-and-support)
