# Changelog

All notable changes to **sailpoint-utils** — reusable SailPoint ISC/IIQ utilities, integration patterns, and supporting tools.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Dates use ISO 8601.

## 2026-09-05

### ✨ New Features

- **Source Connection Setup (IQService Control)** — Added **Stream logs** (`-Action StreamLogs`) to follow `iqtrace.log` with colored `ERROR` / `INFO` / `DEBUG` lines, including stack-trace continuations and log rotation.

### 🔧 Improvements

- **Source Connection Setup** — Connection Settings files default to `sourceConfig/<source>` (AWS, Entra ID, Google Workspace) instead of a folder in the working directory. That tree is gitignored.

- **Source Connection Setup** — Interactive prompts use **Esc** to go back to the previous question and **Ctrl+C** to exit. The completion copy/open menu still treats Esc as Done.

- **Google Workspace source setup** — Domain-wide delegation still has no Google API; the script now opens the Admin console page and copies Client ID then scopes in order. Workspace admin roles (User Management Admin, Groups Admin) can be assigned through the Admin SDK after a Super Admin OAuth sign-in.
- **Google Workspace NHI discovery** — Bind GCP's real predefined roles for Secret Manager Viewer (`roles/secretmanager.viewer`) and API Keys Viewer (`roles/serviceusage.apiKeysViewer`). The display-name slugs are not grantable on a project or organization.
- **Google Workspace domain-wide delegation walkthrough** — Print Client ID and the comma-delimited OAuth scopes (plus each scope) before the first paste prompt, then copy those fields in order. Esc on a wait returns to the previous field so a clipboard overwrite is recoverable.
- **Google Workspace OAuth client** — Creating one has no Google API, so the bare `OAuth client ID for Super Admin sign-in` prompt is now a walkthrough: it opens the Cloud Console create page, lists the fields to fill, copies the redirect URI, then collects the client ID and secret. Declining assigns the roles in the Admin console instead, and a failed sign-in (such as `redirect_uri_mismatch`) explains the cause and offers a retry. The Client Credentials grant type gets the same guidance.
- **Google Workspace OAuth audience** — A new External client starts in Testing, where Google blocks every account that is not a test user (`Access blocked … has not completed the Google verification process`) and never redirects back. The walkthrough now opens the Audience page and copies the account to add before the sign-in, notes that Internal is only offered for Workspace organization projects, and warns that leaving a Client Credentials app in Testing expires its refresh token after 7 days.

- **Google Workspace impersonate user** — Reject Gmail addresses that cannot exist (Gmail allows only letters, digits, and dots, so a hyphen means a typo), and warn that a consumer account cannot be the impersonate user or the Super Admin, since only a managed domain has an Admin console. A bad address used to reach Connection Settings and the OAuth test-user list before failing. When role assignment finds no such user, the script now says so plainly and lists the admin accounts that do exist, instead of surfacing a raw Admin SDK 404 and offering a pointless retry with another OAuth client.

### 🐛 Fixes

- **Google Workspace OAuth sign-in** — A consent screen that blocks the sign-in never reaches the loopback listener, which waited forever. The wait now stops after 5 minutes with the audience fix, and stays responsive to Ctrl+C.

---

## 2026-09-04

### ✨ New Features

- **Source Connection Setup (Entra ID)** — Interactive Microsoft Graph script that creates or updates the app registration used by the ISC Microsoft Entra connector (`ISC/Source Connection Setup/`).
  - Grants every application permission from SailPoint's required-permissions table by default, with a `Directory` mode for the documented coarse alternative.
  - Optional feature packs for access packages, MFA management, CIEM PIM groups, NHI discovery, Teams and SharePoint scanning, Copilot discovery, and Defender hunting.
  - Assigns the User Administrator role required for Set Password and Delete User; Global Administrator is no longer assigned by default.
  - Idempotent updates: merge permissions, grant missing admin consent, optionally rotate the client secret.
  - Replaces the retired AzureAD / Azure AD Graph workflow.
- **Source Connection Setup (AWS SaaS)** — Interactive AWS Tools for PowerShell script that creates or updates the IAM role used by the ISC Amazon Web Services SaaS connector (`ISC/Source Connection Setup/AWS.ps1`).
  - Trusts SailPoint `ciem_universal` for commercial **CIEM** (`874540850173`) and **ISC SaaS** (`706944607044`), or GovCloud (`229634586956`), with the External ID from the ISC source.
  - Attaches documented MGO (default) or non-MGO aggregation, organization, and provisioning policies; optional Activity Insights, CIEM, Bedrock / AgentCore discovery, and IAM Identity Center packs.
  - Idempotent updates of trust and customer-managed policies; optional organization-wide create using a member assume role.
- **Source Connection Setup (Google Workspace SaaS)** — Interactive gcloud script that configures either grant type for the ISC Google Workspace SaaS connector (`ISC/Source Connection Setup/Google Workspace.ps1`).
  - **Service Account:** creates or updates the service account, enables documented Admin SDK / Groups Settings APIs, issues a JSON key, and converts it with OpenSSL to the encrypted RSA PEM the source expects; prints the client ID and scopes for Admin console domain-wide delegation.
  - **Client Credentials:** runs the OAuth 2.0 authorization-code flow against your OAuth client — loopback redirect caught by the script, or the documented OAuth Playground redirect — and returns the offline refresh token.
  - Optional feature packs for GCP inventory, CIEM, Gmail delegates, delta aggregation, Activity Insights, domain management, NHI discovery, and Vertex AI agents.
  - Idempotent updates of the service account and organization custom role `sailpointGoogleWorkspace`, bound to the service account or the authorizing user depending on grant type.
  - Connection Settings are printed one value per line, written to files, and offered through a repeatable copy-to-clipboard menu.
- **Source Connection Setup (IQService Control)** — Windows operator script for IQService hosts (`ISC/Source Connection Setup/IQService Control.ps1`).
  - Downloads `IQService.zip` from a pasted ISC pre-signed URL or a local file, unblocks the archive before extraction.
  - Installs or updates IQService with backup, service stop/uninstall, binary unblock, registry-aware reinstall, and optional auto-start.
  - Service management (start/stop/restart/uninstall), trace log level configuration, status reporting, and `Utils.dll` unblock.
  - Interactive lists use the same arrow-key menus as the Entra ID script, with numbered prompts when the host cannot read single keystrokes.

---

## 2026-09-03

### 🔧 Improvements

- **PowerShell Rule Context** — Connector-rule custom code can now read normalized account requests and source settings through `$ctx.Request` and `$ctx.Application`, with helpers for common lookups and preserved arrays, nested maps, and Modify operations.
- **PowerShell Rule Template internals** — Runtime paths and resolved `Pwsh*` options now live under `$ctx.Runtime` and `$ctx.Options`; source-side option names and precedence remain unchanged.
- **Active Directory Home Folders** — Uses the shared `$ctx` interface and no longer requires `Utils.dll` solely to parse the account request.
- **Documentation and tests** — Added interface, value-shape, security, migration, replay, troubleshooting, and fixture-test coverage for the new context API.

---

## 2026-08-25

### ✨ New Features

- **PowerShell Rule Template** — Copy-ready IQService connector-rule bootstrap for AD and Azure AD (`ISC/PowerShell Rule Template/`).
  - Handles IQService directory lookup, per-run logging, payload redaction, explicit exit codes, and optional replay of a captured invocation.
  - Supports Before/After Create, Modify, and Delete connector rule types; custom logic stays in a dedicated process section.

### 🔧 Improvements

- **Active Directory Home Folders** — Rebuilt on the PowerShell Rule Template so bootstrap, artifact preservation, and logging stay aligned with other IQService rules.

---

## 2026-08-24

### ✨ New Features

- **Active Directory Home Folders** — ConnectorAfterCreate rule that provisions NTFS home folders after AD account creation (`ISC/Active Directory Home Folders/`).
  - Destination path driven by source `connectorAttributes`: `HomeFolderBasePath` plus a `HomeFolderTemplate` filled from account request attributes (`$attributeName` or `{attributeName}` placeholders).
  - Supports absolute UNC or drive-letter paths; falls back to `sAMAccountName` when the template is blank or unresolvable.
  - Creates the folder tree, breaks inheritance, and grants Full Control to the new user and `BUILTIN\Administrators`.
  - Installation and configuration documented for the [SailPoint Identity Security Cloud VS Code extension](https://marketplace.visualstudio.com/items?itemName=yannick-beot-sp.vscode-sailpoint-identitynow).

---

## 2026-08-12

### ✨ New Features

- **saas-custom-operations** — Foundation TypeScript connector template for ISC custom workflow operations (`SaaS Connectivity/saas-custom-operations/`).
  - Invoke commands from workflows, call back into ISC APIs via loopback, and persist typed results to an auto-provisioned DelimitedFile source for downstream **Get Accounts** steps.
  - Auto-provisions the result source by name, applies a shared base account schema, and reconciles per-operation output fields at persist time.
  - Build-time auto-registration of operations from command literals; schema codegen from operation signatures.
  - Local **test mode** and fixture runner for dry-run operation development (`npm run call:op`).
  - Example workflow export demonstrating invoke → persist → **Get Accounts**.
- **SOD remediation operation** (`custom:sod-remediation`) — Launch workflow forms for SOD violations with persisted form URL, email summary fields, revocable access-search filters, and launch-time `formInput` workflow keys.
- **Preventive SOD check** (`custom:preventive-sod-check`) — Evaluate existing or request-scoped SoD violations before approval, with persisted violation flags and policy summaries.
- **Governance group emails** (`custom:governance-group-emails`) — Resolve a workgroup by name and persist member emails for workflow notifications.
- **Repository catalog README** — Root README with purpose, layout tables, and links to all ISC, SaaS Connectivity, and Third-Party utilities.

### 🔧 Improvements

- **Result source schema management** — Base account schema applied on source create; schema attributes replaced on apply so re-provisioned sources stay aligned with registered operations.
- **Persist reliability** — Values truncated to ISC account storage limits; concurrent invokes deduplicated with keepAlive; default request logging for connector troubleshooting.
- **Local invoke tooling** — `call:op` script loads auto-registry and optional `ISC_TOKEN` for connected dry-runs.

### 🐛 Fixes

- **Custom operation error handling** — Operation failures propagate as `ConnectorError` to callers instead of silent success.
- **Persist upsert on existing accounts** — Uses `putAccountV1` when updating an identity's persisted result account.
- **SOD form definition owner** — Form definitions created with the access-token identity as owner (not the violation owner).
- **Result source provisioning** — Connector reference included on DelimitedFile source create; workflow token placeholders normalized in invoke payloads.

### 📚 Documentation

- **saas-custom-operations guides** — Co-located operation READMEs, workflow invoke payload reference, RequestContext API docs, and SOD/persist integration notes.
- **Utility README Purpose sections** — Added consistent Purpose sections across utility READMEs.
- **Custom workflow actions banner** — Promotional image in saas-custom-operations README.

---

## 2026-08-04

### ✨ New Features

- **JDBC SaaS Driver Downloader** — Download and package JDBC drivers for SailPoint SaaS upload from Maven Central (`ISC/JDBC SaaS Driver Downloader/`).
  - Interactive command (`npm run download`) to pick a database engine, select a version, and download a ready-to-upload JAR + ZIP.
  - Batch command (`npm run download:all`) to download and zip all supported JDBC drivers using defaults from `config/drivers.json`.
  - Supports DB2, Oracle, Sybase (jTDS), SQL Server, MySQL, and PostgreSQL from Maven Central.
  - Generates `drivers/manifest.json` with JDBC class names, versions, and source URLs for SailPoint upload.

---

## 2026-07-31

### ✨ New Features

- **Organizational Hierarchy Path** — Identity attribute rule now reads hierarchy settings from source attributes, making separator, entitlement fields, and parent-organization mapping configurable per source without rule edits.

---

## 2026-07-27

### ✨ New Features

- **OrangeHRM → ISC aggregation (Job custom fields)** — Saving valid custom fields on an employee Job page now triggers a SailPoint account aggregation, keeping ISC in sync after job metadata changes.

---

## 2026-07-24

### ✨ New Features

- **Dynamic forms and user data collection** — Example ISC form configuration with cascading dropdowns (buildings, locations, rooms) and CSV-backed reference data for structured user input during provisioning or access requests.

### 📚 Documentation

- **Dynamic forms README** — Expanded guide covering cascading dropdowns and how user selections persist.

### 🐛 Fixes

- **Dynamic forms guide screenshot** — Restored promotional screenshot accidentally removed from the guide.

---

## 2026-07-22

### ✨ New Features

- **OrangeHRM → ISC aggregation (initial integration)** — OrangeHRM now requests SailPoint account aggregation after key employee lifecycle events:
  - New employee creation
  - Job details saved (including contract dates)
  - Contact details updated
  - Supervisor / subordinate relationships added or changed
  - Employment termination or reactivation confirmed
- **Repository bootstrap** — Initial commit and merge of OrangeHRM integration work into the shared utilities repo.

### 🐛 Fixes

- **OrangeHRM new-employee aggregation** — Corrected aggregation trigger on employee creation.

---

## 2026-07-19

### ✨ New Features

- **LCS Operations** — BeforeProvisioning rule for LCS (Lifecycle Services) operations workflows.
- **Optimistic Provisioning Generic SDIM** — Configuration guide and assets for optimistic provisioning with Generic SDIM.

### 🔧 Improvements

- **Repository layout** — Reorganized under `ISC/`, `SaaS Connectivity/`, and `Third-Party/` for clearer navigation.
- **LCS and SDIM READMEs** — Added setup and usage documentation for LCS Operations and Optimistic Provisioning Generic SDIM.
- **Gitignore updates** — Excludes build and coverage output directories.

### 🗑️ Removed

- **Legacy Emergency Termination assets** — Configuration consolidated elsewhere.

### 📚 Documentation

- **Generic SDIM guide** — Added promotional image to the configuration guide.

---

## 2026-07-03

### 🔧 Improvements

- **Branch consolidation** — Merged prior work from the `fernando` branch into the main utilities tree (squash merge).

---

## 2026-03-23

### ✨ New Features

- **Generic Manager Correlation** — Reusable ISC pattern for correlating manager identities across heterogeneous sources using a normalized `attribute|value` transform and source-side correlation rule with multi-attribute fallback.
- **Postman Remote Source Evaluation** — Postman collection pre-request script that authenticates to ISC, resolves a source by name, merges connector configuration, and supports remote connector invoke mode for SaaS connectivity testing.

### 📚 Documentation

- **Generic Manager Correlation infographic** — Added visual guide for setup and flow.

---

## Project Areas

| Path                 | Description                                                     |
| -------------------- | --------------------------------------------------------------- |
| `ISC/`               | Identity Security Cloud rules, transforms, forms, and utilities |
| `SaaS Connectivity/` | Connector testing and SaaS integration helpers                  |
| `Third-Party/`       | Integrations with external systems (e.g., OrangeHRM)            |
| `IIQ/`               | IdentityIQ assets (reserved)                                    |

---

## Contributing

When adding a new utility or integration pattern:

1. Place it under the appropriate top-level folder.
2. Include a `README.md` with setup, artifacts, and usage.
3. Add an entry under the newest `## YYYY-MM-DD` release section (create one for today's date if needed).
