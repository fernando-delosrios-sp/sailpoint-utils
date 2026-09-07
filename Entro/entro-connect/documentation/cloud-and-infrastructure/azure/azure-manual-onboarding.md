Azure Manual Onboarding | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/cloud-and-infrastructure/azure/azure-manual-onboarding.md).
## Entro Application Creation and Permissions[#entro-application-creation-and-permissions](#entro-application-creation-and-permissions)

1. 

Login to Azure [Portal App registrations](https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade)
GitBook Assistant
1. 

Click on **“+ New registration”**
GitBook Assistant

1. 

Register an application
GitBook Assistant

- 

Name: Entro Security App
GitBook Assistant
- 

Supported account types: Accounts in any organizational directory (Any Microsoft Entra AD tenant - Multitenant)
GitBook Assistant
- 

Select “Register”
GitBook Assistant

1. 

After the App is registered, copy and save the following fields from Overview page:
GitBook Assistant

- 

Client ID
GitBook Assistant
- 

Tenant ID
GitBook Assistant
We will need these IDs to onboard to Entro Security later

1. 

Add Secret to the app
GitBook Assistant
1. 

Click on** "Certificates & Secrets"**
GitBook Assistant
1. 

Click on “**+ New Client Secret**”
GitBook Assistant
A screenshot of a computer AI-generated content may be incorrect.

1. 

Add **“Entro Security”** as a description, adjust expiration date, and click** "Add"**
GitBook Assistant
A screenshot of a security account AI-generated content may be incorrect.

1. 

Copy the secret value and save as we will need this to onboard to Entro Security later
GitBook Assistant
1. 

Add API Permissions to the Entro Security Application
GitBook Assistant
1. 

Under “*Manage*” section, click “**API permissions**”
GitBook Assistant
1. 

Click “**+ Add a permission**”
GitBook Assistant

1. 

Select “**Microsoft Graph**”
GitBook Assistant
1. 

Select “**Application permissions**”
GitBook Assistant

1. 

Add the following permissions manually or via JS Console script (dev tools -> console)
GitBook Assistant

1. 

Manually: 
GitBook Assistant

1. 

**Mandatory permissions for any use case:**
GitBook Assistant

- 

User.Read.All
GitBook Assistant

1. 

**Azure Cloud support: {*****Analyze NHIs in Azure*****}**
GitBook Assistant

- 

Application.Read.All
GitBook Assistant
- 

AuditLog.Read.All
GitBook Assistant
- 

Device.Read.All
GitBook Assistant
- 

Directory.Read.All
GitBook Assistant

1. 

**Microsoft Teams support: {*****Find secrets exposed in chats/channels*****}**
GitBook Assistant

- 

Channel.ReadBasic.All
GitBook Assistant
- 

ChannelMember.Read.All
GitBook Assistant
- 

ChannelMessage.Read.All
GitBook Assistant
- 

ChannelSettings.Read.All
GitBook Assistant
- 

Chat.Read.All
GitBook Assistant
- 

TeamsActivity.Read.All
GitBook Assistant
- 

TeamsAppInstallation.ReadForChat.All
GitBook Assistant
- 

TeamsAppInstallation.ReadForTeam.All
GitBook Assistant
- 

TeamsAppInstallation.ReadForUser.All
GitBook Assistant
- 

TeamsTab.Read.All
GitBook Assistant
- 

TeamSettings.Read.All
GitBook Assistant

1. 

**Microsoft Teams – Messaging Functionality: {*****Send Teams messages from Entro platform}***
GitBook Assistant

- 

TeamsAppInstallation.ReadWriteForTeam.All
GitBook Assistant
- 

TeamsAppInstallation.ReadWriteForUser.All
GitBook Assistant
- 

TeamsAppInstallation.ReadWriteSelfForUser.All
GitBook Assistant

1. 

**SharePoint Online support: {*****Find secrets exposed in sites/OneDrive*****}**
GitBook Assistant

- 

Files.Read.All
GitBook Assistant
- 

Sites.Read.All
GitBook Assistant

1. 

**Microsoft Copilot: {Discover and Analyze AI Agents}**
GitBook Assistant

- 

AiEnterpriseInteraction.Read.All
GitBook Assistant
- 

Reports.Read.All
GitBook Assistant
- 

ExternalConnection.Read.All
GitBook Assistant
- 

AppCatalog.Read.All
GitBook Assistant

1. 

**MS Defender: {Discover and Analyze AI Agents on Local Machines}**
GitBook Assistant

- 

Machine.Read.All (this is a WindowsDefenderATP API)
GitBook Assistant
- 

ThreatHunting.Read.All
GitBook Assistant

1. 

JS Console script (Run it on the API Permission screen -> Add a permission) to auto select all permissions
GitBook Assistant

1. 

Grant Admin Consent for API Permissions
GitBook Assistant

- 

Status should now be green/granted for the entire list
GitBook Assistant

## Entro Role Creation and Assignment[#entro-role-creation-and-assignment](#entro-role-creation-and-assignment)

1. 

Navigate to Management Groups (preferred) or to Subscriptions
GitBook Assistant

1. 

Create custom role for Entro
GitBook Assistant
1. 

Choose a Management Group (preferred) or a Subscription
GitBook Assistant
1. 

Select **"Access control IAM"** from the left menu pane
GitBook Assistant
1. 

Select **“+ Add”**
GitBook Assistant
1. 

Select “**Add custom role**”
GitBook Assistant

1. 

Click “JSON” tab, then the Edit button
GitBook Assistant

1. 

Replace "permissions" JSON default with the following:
GitBook Assistant

1. 

Select “**Assignable Scopes**” tab
GitBook Assistant
1. 

Add scope assignments (Management Groups or Subscriptions) by clicking “**+ Add assignable scope**”
GitBook Assistant

1. 

Change “Type” as needed to Management Group or Subscription and add scopes to the role. Click “**Select**” button when finished.
GitBook Assistant

1. 

To finalize custom role creation, click “**Review + create**” button, then “**Create**” button.
GitBook Assistant
1. 

Add Entro App as an assignment to the new custom Entro Role
GitBook Assistant
1. 

While still in “**Access control (IAM)**” menu, click “**+ Add**” then “**Add role assignment**”
GitBook Assistant

1. 

In the “**Role**” tab, search for “**Entro**”, click to select the Entro custom role previously created, then click “**Next**” button.
GitBook Assistant

1. 

In the “**Members**” tab, click “**+ Select members**”, search for “**Entro**” in the search box, click to select the Entro application created previously (making sure it is listed under “Selected members”, then click “**Select**”.
GitBook Assistant

1. 

Click “**Review + assign**” button twice to finish role assignment.
GitBook Assistant
1. 

Add additionally required Entra Built-in roles as role assignments to the Entro application
GitBook Assistant
1. 
#### Repeat role assignments steps from above for each of the following Entra built-in roles: -[#repeat-role-assignments-steps-from-above-for-each-of-the-following-entra-built-in-roles](#repeat-role-assignments-steps-from-above-for-each-of-the-following-entra-built-in-roles)

- 

**Key Vault Reader**
GitBook Assistant
- 

**App Configuration Data Reader**
GitBook Assistant

1. 

When completed, the “**Role assignments**” tab should resemble the following:
GitBook Assistant

1. 

Repeat previous steps to add Entro custom role and required role assignments for Entro application to any other Management Groups and/or Subscriptions where Entro will be inventorying and monitoring.
GitBook Assistant

## Create Entro Log Analytics Workspace[#create-entro-log-analytics-workspace](#create-entro-log-analytics-workspace)

1. 

Navigate to “**Log Analytics Workspaces**”, and then click “**+ Create**”
GitBook Assistant

1. 

Choose the appropriate Subscription, Resource group, Name, and Region, then click “**Review + Create**”, and then “**Create**” again to complete the process.
GitBook Assistant

## Forward Service Principal Sign-in Logs[#forward-service-principal-sign-in-logs](#forward-service-principal-sign-in-logs)

1. 

Navigate to Sign-in Logs
GitBook Assistant

1. 

Click “**Export Data Settings**”
GitBook Assistant

1. 

Under Logs Categories, check “**ServicePrincipalSignInLogs**”, **“AuditLogs”**
GitBook Assistant
1. 

Under Destination Details, check “**Send to Log Analytics workspace**”
GitBook Assistant
1. 

Chose the appropriate Subscription and Log Analytics workspace from the workspace created above.
GitBook Assistant

1. 

Click “**Save**”.
GitBook Assistant

## Give Entro Permission to Analyze Key Vaults[#give-entro-permission-to-analyze-key-vaults](#give-entro-permission-to-analyze-key-vaults)

1. 

Navigate to “Key vaults”
GitBook Assistant

**** For Each Key Vault you wish to have Entro analyze: ****
GitBook Assistant

1. 

Select a Key Vault from the list
GitBook Assistant
1. 

Review current access policy type by navigating to “Access configuration” in the Settings section.
GitBook Assistant

- 

If your Permission model selection for this vault is “**Azure role-based access control**”, you have already granted Entro the ability to analyze the vault in Step 11 when assigning the built-in role, “**Key vault reader**”, to the Subscription or Management Group that the vault is contained in.
GitBook Assistant
- 

If your Permission model type is “**Vault access policy**” and not “Azure role-based access control”, see key benefits and best practices in Microsoft’s Documentation - [Migrate from vault access policy to an Azure RBAC permission model](https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-migration)
GitBook Assistant
- 

In case you persist on staying with **“Vault Access Policy”**, please continue to follow the next steps
GitBook Assistant

1. 

If “**Vault access policy**” is selected for this vault, select “**Access policies**”, then click “**+ Create**”
GitBook Assistant

1. 

Select the following permissions to be added:
GitBook Assistant

1. 

Select your created Entro App as Principal and then select **"Next"**, and **"Create"**.
GitBook Assistant

## Forward Key Vault Activity Logs to Entro Workspace[#forward-key-vault-activity-logs-to-entro-workspace](#forward-key-vault-activity-logs-to-entro-workspace)

1. 

While still in Key Vaults service page, select a Key Vault you wish to forward activity logs to the Entro Log Analytics workspace for Entro to analyze.
GitBook Assistant
1. 

Select “**Diagnostic settings**” in the “Monitoring” section of the menu. Then click “**+ Add diagnostic setting**”.
GitBook Assistant

1. 

Check “**audit**” and “**allLogs**” in Logs Category groups. Check “**Send to Log Analytics workspace**” and enter appropriate Subscription and Log Analytics workspace details created in Step 14. Click “**Save**”.
GitBook Assistant

1. 

Repeat these steps for remaining Key Vaults you wish for Entro to analyze.
GitBook Assistant

## Register Azure in the Entro Platform[#register-azure-in-the-entro-platform](#register-azure-in-the-entro-platform)

1. 

Navigate to the Integrations page in the Entro app portal, Management > Accounts & Integrations.
GitBook Assistant
1. 

Click “**+ Add new account**”, select “Microsoft Ecosystem” tile.
GitBook Assistant
1. 

Give the Environment a name. Add the details of the Entro App (tenant ID and client ID) and secret from Step 4 and Step 5. Chose the appropriate Worker Group (Connector). Click “**Create Account**”.
GitBook Assistant
[PreviousAutomated PowerShell Onboarding](/integrations/cloud-and-infrastructure/azure/automated-powershell-onboarding)[NextHybrid Entra AD](/integrations/cloud-and-infrastructure/azure/hybrid-entra-ad)

Last updated 1 month ago

- [Entro Application Creation and Permissions](#entro-application-creation-and-permissions)
- [Entro Role Creation and Assignment](#entro-role-creation-and-assignment)
- [Create Entro Log Analytics Workspace](#create-entro-log-analytics-workspace)
- [Forward Service Principal Sign-in Logs](#forward-service-principal-sign-in-logs)
- [Give Entro Permission to Analyze Key Vaults](#give-entro-permission-to-analyze-key-vaults)
- [Forward Key Vault Activity Logs to Entro Workspace](#forward-key-vault-activity-logs-to-entro-workspace)
- [Register Azure in the Entro Platform](#register-azure-in-the-entro-platform)
GitBook AssistantAskCopy
```
/* ============================================================================
 * Entro - Azure API permissions auto-selector  (v4)
 * Microsoft Graph (26 perms) + WindowsDefenderATP (Machine.Read.All)
 * + optional tenant-wide admin consent.
 * Built from the ACTUAL Entra portal DOM (verified June 2026).
 * ----------------------------------------------------------------------------
 * ❶ CRITICAL — RUN IT IN THE RIGHT FRAME
 *   The permissions UI lives inside a CROSS-ORIGIN IFRAME
 *   (hosting.portal.azure.net). The DevTools Console runs in the "top" frame by
 *   default, where this UI does NOT exist — that's why a pasted script "finds
 *   nothing". Before pasting, open the Console's JS-context dropdown (top-left
 *   of the Console toolbar, shows "top") and switch it to the portal extension
 *   frame (URL contains "hosting.portal.azure.net" / "RegisteredApps").
 *
 * ❷ WHERE TO START
 *   Open: App registrations → your app → API permissions.
 *   • AUTO_NAVIGATE = true  (default): just be on the API permissions page.
 *     The script opens "Add a permission", picks each API + Application
 *     permissions, ticks everything, clicks "Add permissions" per API, then
 *     (optionally) grants admin consent. Best-effort: the API-navigation clicks
 *     are the most fragile part; watch the log.
 *   • AUTO_NAVIGATE = false: open ONE API's "Application permissions" panel
 *     yourself, then run — it only ticks that API's matching permissions.
 *
 * ❸ Re-running is safe: already-selected permissions are skipped, never unticked.
 *    Anything it can't handle is listed at the end so you can finish by hand.
 * ========================================================================== */

(() => {
  "use strict";

  // ---- WHAT TO SELECT, grouped by API -------------------------------------
  const API_TARGETS = [
    {
      key: "graph",
      displayName: "Microsoft Graph",
      tab: "Microsoft APIs",          // which tab on "Select an API"
      tile: "Microsoft Graph",        // commonly-used tile to click
      search: null,
      permissions: [
        "User.Read.All",
        "Application.Read.All", "AuditLog.Read.All", "Device.Read.All", "Directory.Read.All",
        "Channel.ReadBasic.All", "ChannelMember.Read.All", "ChannelMessage.Read.All",
        "ChannelSettings.Read.All", "Chat.Read.All", "TeamsActivity.Read.All",
        "TeamsAppInstallation.ReadForChat.All", "TeamsAppInstallation.ReadForTeam.All",
        "TeamsAppInstallation.ReadForUser.All", "TeamsTab.Read.All", "TeamSettings.Read.All",
        "TeamsAppInstallation.ReadWriteForTeam.All", "TeamsAppInstallation.ReadWriteForUser.All",
        "TeamsAppInstallation.ReadWriteSelfForUser.All",
        "Files.Read.All", "Sites.Read.All",
        "AiEnterpriseInteraction.Read.All", "Reports.Read.All",
        "ExternalConnection.Read.All", "AppCatalog.Read.All",
        "ThreatHunting.Read.All",
      ],
    },
    {
      key: "defenderatp",
      displayName: "WindowsDefenderATP",
      tab: "APIs my organization uses", // not a commonly-used tile
      tile: null,
      search: "WindowsDefenderATP",      // typed into the API-name search box
      permissions: ["Machine.Read.All"], // Microsoft Defender for Endpoint
    },
  ];

  // ---- Settings ------------------------------------------------------------
  const AUTO_NAVIGATE      = true;   // false = only select on the panel already open
  const GRANT_ADMIN_CONSENT = true;  // grant tenant-wide consent at the end (with confirm prompt)

  const SEARCH_SETTLE = 800;   // ms after typing in a filter box
  const NAV_WAIT      = 2500;  // ms after a navigation click (panel/list load)
  const STEP          = 350;   // ms between small UI actions

  // ---- Helpers -------------------------------------------------------------
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const norm  = (s) => (s || "").replace(/\s+/g, " ").trim();
  const visible = (el) => el && el.offsetParent !== null;

  function setNativeValue(input, value) {
    const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "value").set;
    setter.call(input, value);
    input.dispatchEvent(new Event("input",  { bubbles: true }));
    input.dispatchEvent(new Event("change", { bubbles: true }));
    input.dispatchEvent(new KeyboardEvent("keyup", { bubbles: true, key: "a" }));
  }

  // click first visible element whose text/aria-label exactly matches one of `texts`
  function clickExact(texts, tags = 'button, a, [role="button"], [role="tab"], li, div, span') {
    const want = texts.map((t) => t.toLowerCase());
    const el = [...document.querySelectorAll(tags)].find((e) =>
      visible(e) && want.includes(norm(e.textContent || e.getAttribute("aria-label")).toLowerCase()));
    if (el) { el.click(); return true; }
    return false;
  }
  // click first visible element whose text STARTS WITH `prefix`
  function clickStartsWith(prefix, tags = 'li, div, button, [role="button"], [role="option"]') {
    const p = prefix.toLowerCase();
    const el = [...document.querySelectorAll(tags)].find((e) =>
      visible(e) && norm(e.textContent).toLowerCase().startsWith(p));
    if (el) { el.click(); return true; }
    return false;
  }

  const permFilterBox = () =>
    document.querySelector('input[placeholder="Start typing a permission to filter these results"]')
    || document.querySelector('input[placeholder*="filter these results" i]');
  const apiSearchBox = () =>
    document.querySelector('input[placeholder*="API name" i]')
    || document.querySelector('input[placeholder*="Application ID" i]');

  function expandGroups() {
    clickExact(["expand all"]);
    document.querySelectorAll('[aria-expanded="false"]').forEach((b) => {
      const t = norm((b.getAttribute("aria-label") || "") + " " + b.textContent).toLowerCase();
      if (/expand or collapse group|read|write|\.all/.test(t)) { try { b.click(); } catch (e) {} }
    });
  }

  // permission name is in a <label>; its grid row carries the selected state
  function findRow(name) {
    const label = [...document.querySelectorAll("label")].find((l) => norm(l.textContent) === name);
    return label ? { label, row: label.closest('[role="row"]') } : null;
  }
  function rowChecked(row) {
    if (!row) return null;
    const sel = row.getAttribute("aria-selected");
    if (sel === "true") return true;
    if (sel === "false") return false;
    for (const el of row.querySelectorAll('img, [role="img"], [aria-label]')) {
      const al = norm(el.getAttribute("aria-label")).toLowerCase();
      if (al === "selected") return true;
      if (al === "unselected" || al === "not selected") return false;
    }
    return null;
  }
  async function selectRow(found) {
    const cell = found.row && found.row.querySelector('[role="gridcell"]');
    for (const t of [cell, found.label, found.row].filter(Boolean)) {
      try { t.click(); } catch (e) {}
      await sleep(STEP);
      if (rowChecked(found.row) === true) return true;
    }
    return rowChecked(found.row) === true;
  }

  // tick every permission for the API whose panel is currently open
  async function selectPermissions(perms, report) {
    const box = permFilterBox();
    if (!box) { console.warn("  [!] permission filter box not visible — is the Application permissions panel open?");
                perms.forEach((p) => report.notFound.push(p)); return; }
    for (const perm of perms) {
      setNativeValue(box, perm);
      await sleep(SEARCH_SETTLE);
      expandGroups();
      await sleep(STEP);
      let found = findRow(perm);
      if (!found) { expandGroups(); await sleep(STEP); found = findRow(perm); }
      if (!found) { console.warn("  ✗ not found: " + perm); report.notFound.push(perm); continue; }
      if (rowChecked(found.row) === true) { console.log("  • already: " + perm); report.already++; continue; }
      if (await selectRow(found)) { console.log("  ✓ selected: " + perm); report.added++; }
      else { console.warn("  ? unconfirmed: " + perm); report.uncertain.push(perm); }
    }
    setNativeValue(box, "");
    await sleep(STEP);
  }

  // open "Add a permission" → pick API → Application permissions
  async function navigateToApi(target) {
    if (!clickExact(["Add a permission", "Add a permission "])) {
      console.warn("  [!] 'Add a permission' button not found."); return false;
    }
    await sleep(NAV_WAIT);
    clickExact([target.tab]);                 // tab: Microsoft APIs / APIs my organization uses
    await sleep(STEP);
    if (target.tile) {
      if (!clickExact([target.tile])) { console.warn("  [!] API tile not found: " + target.tile); return false; }
    } else if (target.search) {
      const sb = apiSearchBox();
      if (!sb) { console.warn("  [!] API search box not found."); return false; }
      setNativeValue(sb, target.search);
      await sleep(NAV_WAIT);
      if (!clickExact([target.displayName])) { console.warn("  [!] API result not found: " + target.displayName); return false; }
    }
    await sleep(NAV_WAIT);
    clickStartsWith("Application permissions"); // choose Application (not Delegated)
    await sleep(NAV_WAIT);
    return !!permFilterBox();
  }

  function clickAddPermissions() {
    return clickExact(["Add permissions", "Add permission"]);
  }

  // ---- Run -----------------------------------------------------------------
  (async () => {
    // frame guard
    if (!permFilterBox() && !document.querySelector('button, [role="button"]')) {
      console.error("%c[Entro] This frame looks empty. Switch the Console context dropdown to the " +
        "portal extension frame (hosting.portal.azure.net), then re-paste.", "color:#c00;font-weight:bold");
      return;
    }

    const report = { added: 0, already: 0, notFound: [], uncertain: [] };

    if (AUTO_NAVIGATE) {
      for (const target of API_TARGETS) {
        console.log("%c[Entro] === " + target.displayName + " ===", "color:#06c;font-weight:bold");
        const ok = await navigateToApi(target);
        if (!ok) {
          console.warn("  [!] Could not open " + target.displayName + " Application permissions panel — skipping. " +
            "Open it manually, set AUTO_NAVIGATE=false, and re-run for: " + target.permissions.join(", "));
          target.permissions.forEach((p) => report.notFound.push(target.displayName + ": " + p));
          continue;
        }
        await selectPermissions(target.permissions, report);
        await sleep(STEP);
        if (clickAddPermissions()) console.log("  ✓ Clicked 'Add permissions' for " + target.displayName);
        else console.warn("  [!] 'Add permissions' not found for " + target.displayName);
        await sleep(NAV_WAIT); // panel closes & list saves
      }
    } else {
      // single open panel: try every API's perms; non-matching ones report "not found"
      const all = API_TARGETS.flatMap((t) => t.permissions);
      console.log("%c[Entro] Selecting on the currently-open panel…", "color:#06c;font-weight:bold");
      await selectPermissions(all, report);
      await sleep(STEP);
      if (clickAddPermissions()) console.log("  ✓ Clicked 'Add permissions'");
      else console.warn("  [!] 'Add permissions' not found — click it manually.");
    }

    console.log("%c[Entro] Selection summary — %d added, %d already set, %d not found, %d uncertain.",
      "color:#0a7;font-weight:bold", report.added, report.already, report.notFound.length, report.uncertain.length);
    if (report.notFound.length)  console.warn("[Entro] Not found (tick by hand):\n" + report.notFound.join("\n"));
    if (report.uncertain.length) console.warn("[Entro] Verify (state unconfirmed):\n" + report.uncertain.join("\n"));

    // ---- Admin consent ----
    if (GRANT_ADMIN_CONSENT) {
      await sleep(NAV_WAIT);
      if (confirm("[Entro] Grant tenant-wide admin consent for ALL selected permissions now?\n" +
                  "This authorizes the app across your whole directory.")) {
        if (clickExact(["Grant admin consent for Default Directory"]) ||
            clickStartsWith("Grant admin consent")) {
          await sleep(900);
          if (clickExact(["Yes"])) console.log("%c[Entro] Admin consent confirmed.", "color:#0a7;font-weight:bold");
          else console.warn("[Entro] Consent 'Yes' button not found — confirm the dialog manually.");
        } else {
          console.warn("[Entro] 'Grant admin consent' button not found — click it manually on the API permissions page.");
        }
      } else {
        console.log("[Entro] Admin consent skipped (you declined the prompt).");
      }
    }

    console.log("%c[Entro] Finished.", "color:#0a7;font-weight:bold");
  })();
})();

```
Show all 256 linesGitBook AssistantAskCopy
```
"permissions": [
            {
                "actions": [
                    "*/read",
                    "Microsoft.OperationalInsights/workspaces/analytics/query/action",
                    "Microsoft.OperationalInsights/workspaces/search/action",
                    "Microsoft.Insights/alertRules/*",
                    "Microsoft.Support/*",
                    "Microsoft.Web/sites/config/list/Action"
                ],
                "notActions": [
                    "Microsoft.OperationalInsights/workspaces/sharedKeys/read"
                ],
                "dataActions": [],
                "notDataActions": []
            }
        ]
```
