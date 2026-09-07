ServiceNow Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/collaboration-and-saas/servicenow/servicenow-onboarding.md).

This guide outlines the steps required to connect your ServiceNow instance to Entro Security. The integration operates in **read-only mode**, using a **ServiceNow API Access Token** to authenticate through the **Table API** and **Attachment API**.
GitBook Assistant
## Prerequisites[#prerequisites](#prerequisites)

Before starting the onboarding process, ensure you have:
GitBook Assistant

- 

ServiceNow **Admin permissions**
GitBook Assistant
- 

Access to the **System Web Services** and **User Administration** modules
GitBook Assistant
- 

An active **Worker Group (Connector)** in Entro
GitBook Assistant
- 

The ServiceNow domain URL (e.g., `https://<yourDomain>.service-now.com`)
GitBook Assistant
1
#### Create an Inbound Authentication Profile[#create-an-inbound-authentication-profile](#create-an-inbound-authentication-profile)

In ServiceNow, navigate to: **All → System Web Services → API Access Policies → Inbound Authentication Profile**
GitBook Assistant

- 

Click **New**.
GitBook Assistant
- 

Choose **Create API Key Authentication Profiles**.
GitBook Assistant
- 

Enter a name for the profile (e.g. `Entro Profile`).
GitBook Assistant
- 

Click the lock icon to open **Auth Parameter** selection.
GitBook Assistant
- 

Click on the **magnifying glass** and select the parameter that corresponds to the **Auth Header **(e.g. `x-sn-apikey`).
GitBook Assistant
- 

Click **Submit**.
GitBook Assistant
2
#### Create an Integration User[#create-an-integration-user](#create-an-integration-user)

Navigate to: **All → User Administration → Users**
GitBook Assistant

- 

Click **New**.
GitBook Assistant
- 

Fill in **User ID** (e.g. `Entro User`) and optionally fill in the details.
GitBook Assistant
- 

Mark the user as **Active** and **Internal Integration User**.
GitBook Assistant
- 

Click **Submit**.
GitBook Assistant
- 

Enter the user you just created.
GitBook Assistant
- 

Below, in the **Roles**, click on **Edit...** and add the following roles:
GitBook Assistant

- 

`itil` - read access to incidents, problems, change requests, and CMDB records.
GitBook Assistant
- 

`snc_read_only` - enforces read-only behavior across the user's assigned roles.
GitBook Assistant
- 

`knowledge` - read access to knowledge articles, knowledge bases, and article feedback (`kb_knowledge`, `kb_knowledge_base`, `kb_feedback`).
GitBook Assistant
- 

`personalize_dictionary` - *optional*, allows discovery and scanning of custom tables (`sys_dictionary`, `sys_db_object`).
GitBook Assistant

- 

Click **Save**.
GitBook Assistant
- 

In the user details screen, click **Update**.
GitBook Assistant

**Knowledge Base access also depends on User Criteria.** The `knowledge` role grants table-level read, but ServiceNow additionally gates each article through the knowledge base's **"Can Read" user criteria**. To scan a knowledge base, the Integration User must be included in that base's **Can Read** criteria, either directly, via a group, or through a global Can Read criteria. Articles in bases where the user is not in the Can Read set will not be returned, even with the `knowledge` role assigned.
GitBook Assistant

**Scanning custom tables** may require additional roles per table. Consult your ServiceNow admin or Entro Support for further assistance.
GitBook Assistant3
#### Create ACL for Journal Data Scanning[#create-acl-for-journal-data-scanning](#create-acl-for-journal-data-scanning)

Scanning journal data (work notes and comments) requires an explicit ACL. Journal entries live in the `sys_journal_field` table, which ServiceNow keeps restricted by default. The `itil` role does not grant read access to it through the Table API. To scan journals, navigate to: **All → System Security → Access Control (ACL)**
GitBook Assistant

- 

Click **New** and create the Journal scanning ACL*:
GitBook Assistant

- 

**Type:** `Record`
GitBook Assistant
- 

**Operation:** `read`
GitBook Assistant
- 

**Name:** `sys_journal_field` (leave the field portion empty to cover the whole table)
GitBook Assistant
- 

Under **Requires role**, add the role assigned to your Integration User (e.g. `itil`, or a dedicated role you create for the integration)
GitBook Assistant
- 

Click **Submit**
GitBook Assistant

*If there is no **New** button on the Access Control (ACL) list, `security_admin` role is not in use. Admins do not hold it by default — it has to be elevated for the session:
GitBook Assistant

1. 

Click your **profile icon** in the top-right corner of ServiceNow
GitBook Assistant
1. 

Select **Elevate role **
GitBook Assistant
1. 

Check **security_admin** option and click **Update **
GitBook Assistant

Elevated privileges end when you log out. Refresh the **Access Control (ACL)** list and the **New** button will be available.
GitBook Assistant

4
#### Create REST API Auth Scopes[#create-rest-api-auth-scopes](#create-rest-api-auth-scopes)

Navigate to: **All → System Web Services → API Auth Scopes → REST API Auth Scope**
GitBook Assistant

- 

Click **New** and create the first scope for the **Table API**:
GitBook Assistant

- 

Name the API Auth Scope (e.g. `Entro Access Table API`)
GitBook Assistant
- 

**REST API:** Table API
GitBook Assistant
- 

**Auth Scope:** create new `entro-auth-scope`
GitBook Assistant
- 

Uncheck **Apply auth scope to all HTTP methods in this API**
GitBook Assistant
- 

Click **Submit**
GitBook Assistant

- 

Repeat for the **Attachment API**:
GitBook Assistant

- 

Name the API Auth Scope (e.g. `Entro Access Attachment API`)
GitBook Assistant
- 

**REST API:** Attachment API
GitBook Assistant
- 

**Auth Scope:** select `entro-auth-scope` created earlier
GitBook Assistant
- 

Uncheck **Apply auth scope to all HTTP methods in this API**
GitBook Assistant
- 

Click **Submit**
GitBook Assistant

5
#### Create an API Access Token[#create-an-api-access-token](#create-an-api-access-token)

Navigate to: **All → System Web Services → API Access Policies → REST API Key**
GitBook Assistant

- 

Click **New**.
GitBook Assistant
- 

**Name:** Enter a name for the API key. (e.g. `Entro integration`)
GitBook Assistant
- 

**User:** Assign the **Integration User** created earlier in step 2.
GitBook Assistant
- 

**Auth Scope:** Select the `entro-auth-scope` from the previous step.
GitBook Assistant
- 

Click **Submit**.
GitBook Assistant
- 

Reopen the created API Key and click the lock icon next to **Token**.
GitBook Assistant
- 

Copy the token and store it securely.
GitBook Assistant
6
#### Create REST API Access Policies[#create-rest-api-access-policies](#create-rest-api-access-policies)

Navigate to: **All → System Web Services → REST API Access Policies**
GitBook Assistant

- 

Create a new policy for the **Table API**:
GitBook Assistant

- 

Name the API Access Policy (e.g. `Entro Table API Access Policy`)
GitBook Assistant
- 

**REST API:** Table API
GitBook Assistant
- 

Uncheck **Apply to all methods**
GitBook Assistant
- 

Under **Inbound Authentication Profiles**, select the profile from Step 1
GitBook Assistant
- 

Click **Submit**
GitBook Assistant

- 

Repeat for the **Attachment API**:
GitBook Assistant

- 

Name the API Access Policy (e.g. `Entro Attachment API Access Policy`)
GitBook Assistant
- 

**REST API:** Attachment API
GitBook Assistant
- 

Uncheck **Apply to all methods**
GitBook Assistant
- 

Under **Inbound Authentication Profiles**, select the profile from Step 1
GitBook Assistant
- 

Click **Submit**
GitBook Assistant

**If users/integrations are using Basic Auth to login into ServiceNow consider doing the following to avoid login issues**[#if-users-integrations-are-using-basic-auth-to-login-into-servicenow-consider-doing-the-following-to](#if-users-integrations-are-using-basic-auth-to-login-into-servicenow-consider-doing-the-following-to)

1. 

Create BasicAuth Authentication Profile:
GitBook Assistant

1. 

Go to **All → System Web Services → API Access Policies → Inbound Authentication Profiles**
GitBook Assistant
1. 

Select **New**
GitBook Assistant
1. 

Select **Create standard http authentication profiles**
GitBook Assistant
1. 

Give the new profile a name (like BasicAuth) and make sure that `Basic Auth` is selected as the Type
GitBook Assistant
1. 

Click **Submit**
GitBook Assistant

1. 

Add the new profile to all the REST API Access Policies:
GitBook Assistant

1. 

Go to **Navigate to All → System Web Services → REST API Access Policies**
GitBook Assistant
1. 

Click the **Table API policy**
GitBook Assistant
1. 

In the Inbound authentication profiles at the bottom, add the new BasicAuth auth profile to the list (in addition to the Entro auth profile)
GitBook Assistant
1. 

Do the same for the **Attachments API policy**
GitBook Assistant

7
#### Connect ServiceNow to Entro[#connect-servicenow-to-entro](#connect-servicenow-to-entro)

In the Entro Dashboard, navigate to: **Management → Accounts & Integrations → Add New Account (top right) → ServiceNow**
GitBook Assistant

Fill in the integration form using the details from ServiceNow:
GitBook Assistant

- 

**Environment: **Integration's name
GitBook Assistant
- 

**Display Name:** Friendly display name for the integration (optional)
GitBook Assistant
- 

**ServiceNow URL:** e.g., `https://<yourDomain>.service-now.com`
GitBook Assistant
- 

**Access Token:** Paste the token copied from the API Access Token step
GitBook Assistant
- 

**Worker Group:** Select the connector to handle the integration
GitBook Assistant

Click **Connect**.
GitBook Assistant8
#### Validation[#validation](#validation)

After connecting, Entro automatically:
GitBook Assistant

- 

Validates the token and API scope configuration
GitBook Assistant
- 

Confirms read access to Table and Attachment APIs
GitBook Assistant
- 

Begins secret scanning of records and attachments
GitBook Assistant

When successful, the integration status will display **Verified** in the Entro Console.
GitBook Assistant[PreviousServiceNow](/integrations/collaboration-and-saas/servicenow)[NextServiceNow Troubleshooting and Validation](/integrations/collaboration-and-saas/servicenow/servicenow-troubleshooting-and-validation)

Last updated 2 days ago
