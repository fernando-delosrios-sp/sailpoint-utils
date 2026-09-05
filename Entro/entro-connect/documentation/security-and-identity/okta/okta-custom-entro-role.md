Okta Custom Entro Role | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/okta/okta-custom-entro-role.md).

If your organization cannot grant **Super Administrator** to Entro's API Service App, you can create a custom least-privilege role instead. Note that this will result in **partial visibility** - specifically, API grant permissions per Okta app will not be available.
GitBook Assistant

When using a custom role, you must also assign the **Report Administrator** built-in role to enable audit log collection.
GitBook Assistant1
### Create the Custom Role[#create-the-custom-role](#create-the-custom-role)

- 

In the Okta Admin Console, navigate to **Security → Administrators → Roles tab**.
GitBook Assistant
- 

Click **Create New Role**.
GitBook Assistant

- 

Enter the following details:
GitBook Assistant

- 

**Role Name:** `Entro Security Role`
GitBook Assistant
- 

**Role Description:** `Integration app for securing users, apps, permissions, and log collection`
GitBook Assistant

- 

Select the following permissions:
GitBook Assistant
CategoryPermission

**User**
GitBook Assistant

View users' profile attributes
GitBook Assistant

**User**
GitBook Assistant

View users and their details
GitBook Assistant

**User**
GitBook Assistant

View API tokens
GitBook Assistant

**Group**
GitBook Assistant

View groups and their details
GitBook Assistant

**Identity and Access Management**
GitBook Assistant

View roles, resources, and admin assignments
GitBook Assistant

**Application**
GitBook Assistant

View application and their details
GitBook Assistant

**Application**
GitBook Assistant

View client credentials
GitBook Assistant

- 

Click **Save Role**.
GitBook Assistant
2
### Create a Resource Set[#create-a-resource-set](#create-a-resource-set)

- 

Go to the **Resources** tab and click **Create new resource set**.
GitBook Assistant

- 

Enter the following details:
GitBook Assistant

- 

**Name:** `Entro Resource Set`
GitBook Assistant
- 

**Description:** `Apps, Users, Groups`
GitBook Assistant

- 

Click **+ Add resource** and add the following:
GitBook Assistant
ResourcePurpose

**Applications → All applications**
GitBook Assistant

Observe all apps and their client secrets
GitBook Assistant

**Identity and Access Management → All IAM resources**
GitBook Assistant

Read permissions and resource set info per user and app
GitBook Assistant

**Users → All users**
GitBook Assistant

Enumerate all users for ownership attribution and employee/IdP data
GitBook Assistant

**Groups → All groups** *(optional — future)*
GitBook Assistant

Will be required once Entro covers group membership
GitBook Assistant

- 

Click **Create**.
GitBook Assistant
3
### Assign the Role to Entro's App[#assign-the-role-to-entros-app](#assign-the-role-to-entros-app)

- 

In the Okta Admin Console, navigate to **Applications → Applications** and open Entro's API Service App.
GitBook Assistant

- 

Go to the **Admin Roles** tab and click **Edit Assignment**.
GitBook Assistant

- 

Select **Entro Security Role** and assign the **Entro Resource Set**.
GitBook Assistant

- 

Click **Save Changes**.
GitBook Assistant
4
### Assign Report Administrator[#assign-report-administrator](#assign-report-administrator)

- 

Still on the **Admin Roles** tab, click **Edit Assignment** again.
GitBook Assistant
- 

Add the **Report Administrator** built-in role.
GitBook Assistant

- 

Click **Save Changes**.
GitBook Assistant
[PreviousOkta Onboarding](/integrations/security-and-identity/okta/okta-onboarding)[NextOkta Permissions Reference](/integrations/security-and-identity/okta/okta-permissions-reference)

Last updated 2 months ago

- [Create the Custom Role](#create-the-custom-role)
- [Create a Resource Set](#create-a-resource-set)
- [Assign the Role to Entro's App](#assign-the-role-to-entros-app)
- [Assign Report Administrator](#assign-report-administrator)
