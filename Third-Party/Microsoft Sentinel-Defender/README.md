# Cheap Sentinel ↔ SailPoint (`emea-tes-team`)

Headless install of an isolated, pay-as-you-go Microsoft Sentinel workspace, SailPoint ISC
ingestion (RestApiPoller / CCF), operator content (workbook + detections), and an **opt-in**
Sentinel → ISC containment playbook.

Ingestion stays cheap. Analytic rules and the workbook are included in `just up`.
The response playbook is **not** deployed unless you explicitly run `just response` with
separate remediation credentials.

## Architecture

```text
ISC Search API (sp:search:read PAT)
    → RestApiPoller ×3 → DCE/DCR → SailPointISC_*_CL tables
    → KQL functions + workbook + scheduled analytics rules
    → (opt-in) Logic App playbook
         → POST /intelligence/v1/response-actions (source=SENTINEL)
         → ISC Intel Response Actions workflow (approval required)
```

Shared Signals Framework (SSF) is checked during `just response-capability`. Prefer SSF only
when a Microsoft CAEP/SSF transmitter discovery URL is available (`MICROSOFT_SSF_DISCOVERY_URL`)
and the tenant has SSF entitlement. Otherwise the documented Sentinel containment path is the
Response Actions API, which triggers the ISC workflow.

## Prerequisites

- `az` logged into subscription `PAYG - Fernando` (`180aa0bd-2861-4b9e-9593-eba6a027c2c5`)
- `sail` with env `emea-tes-team` (PAT auth) already configured
- `jq`, `curl`, `just`, `python3`
- For response playbook only:
  - Tenant license `idn:response-and-remediation`
  - Separate PAT/OAuth client with `sp:identity-sec-intel:read` and `sp:identity-sec-intel:write`
  - ISC workflow from template **SecOps Identity Intelligence Response Action** with approval enabled  
    (see [`content/workflows/intel-response-actions.contract.md`](content/workflows/intel-response-actions.contract.md))

> **Region note:** West Europe currently rejects new Log Analytics workspaces on this
> subscription (`RequestDisallowedByAzure` / locationineligible). The recipes default
> to **North Europe**.

## Quick start

```bash
cd sentinel-sailpoint
just preflight   # non-billable checks + provider registration
just up          # RG, workspace, solution, PAT, connector, content, verify
just status
just events      # first rows can take ~15 minutes (5m window + 10m delay)
```

Operator content only (workspace already up):

```bash
just content
just verify-content
```

Opt-in response path (credentials via env; never written to the repo):

```bash
just response-capability
RESPONSE_CLIENT_ID=... RESPONSE_CLIENT_SECRET=... just response
# default dry_run=true — identity resolve only, no disable
# RESPONSE_CLIENT_ID=... RESPONSE_CLIENT_SECRET=... just response dry_run=false
```

Tear down:

```bash
just down confirm=yes
```

## What gets created

| Resource | Name / note |
| --- | --- |
| Resource group | `rg-sentinel-emea-tes-team` (North Europe) |
| Log Analytics | `law-emea-tes-sentinel`, sku `PerGB2018`, 90-day retention |
| Sentinel | onboarding state `default` |
| Content Hub | SailPoint IdentityNow ≥ 3.0.1 (templates registered; Hub rules/playbooks not auto-enabled) |
| DCE / DCR / tables | Three custom tables via RestApiPoller streams |
| Data connectors | One `RestApiPoller` per ISC search index for `company24509-poc` / `identitynow-demo` |
| SailPoint PAT | name `sentinel-ccf`, scope `sp:search:read` only |
| KQL functions | `SailPointISC_Events`, `SailPointISC_AccountActivities`, `SailPointISC_WorkflowHistory` |
| Saved searches | Workspace queries in five Logs folders: SailPoint - Security Events, SailPoint - Account Operations, SailPoint - Workflow Operations, SailPoint - Ingestion Health, and SailPoint - Response |
| Identity assets | `SailPointISC_Identities_CL` refreshes every 5 minutes from ISC. A changed `userPrincipalName` replaces the previous row on the next poll |
| Analytics rules | Privileged change, failed-auth burst, failed/stalled remediation workflow. Each incident carries the matched Entra UPN and the Defender response to take |
| Workbook | **SailPoint ISC Operations** (KPIs, trends, actors/targets, AA/workflows, ingestion health) |
| Response (opt-in) | Key Vault + Logic App `sailpoint-isc-response` (default `dryRun=true`) |

### Custom tables (streams)

| ISC search index | Stream | Log Analytics table |
| --- | --- | --- |
| `events` | `Custom-SailPointISC_Events_CL` | `SailPointISC_Events_CL` |
| `accountactivities` | `Custom-SailPointISC_AccountActivities_CL` | `SailPointISC_AccountActivities_CL` |
| `workflowsummaries` | `Custom-SailPointISC_WorkflowHistory_CL` | `SailPointISC_WorkflowHistory_CL` |

Account Activity and Workflow History poll `POST /v2025/search` (events keep `POST /v2025/search/events`). Each poller reads a 5-minute `created` window that ends 10 minutes ago.

## Content pack layout

```text
content/
  kql/           Shared functions plus the Logs saved-search library
  analytics/     Three scheduled Sentinel alert rule definitions
  workbooks/     SailPoint ISC Operations workbook
  response/      Logic App ARM + sample incident payload
  workflows/     ISC Intel Response Actions contract
```

## Safety defaults

- Ingestion PAT is read-only (`sp:search:read`) and is **never** reused for remediation
- Response playbook defaults to `dryRun=true` (resolve + report; no `DISABLE_*` submit)
- Preferred live action is `DISABLE_ACCOUNT`; `DISABLE_IDENTITY` is for confirmed compromise
- ISC workflow must require human approval before disable
- No automatic Sentinel automation rule is created; invoke the playbook manually from an incident / HTTP trigger
- Dedup key = Sentinel incident ARM id (or title) + action type

## Cost

- New workspaces can receive the Sentinel 31-day trial (first 10 GB/day free). Confirm in portal; the scripts report observed sku/retention rather than asserting trial eligibility.
- After trial: pay-as-you-go on ingested GB only. Do **not** pick a commitment tier (starts at 100 GB/day).
- Only `SailPointISC_Events_CL` should ingest heavily today. `just cost` prints Usage by DataType.
- Workbook queries and analytics use bounded lookbacks (1–2h for rules, parameterised for the workbook).

## Secrets

The connect step creates the ingestion PAT via `sail`, smoke-tests `/oauth/token` (prints HTTP status only), writes ARM parameters under `umask 077` into a temp dir, deploys, then shreds the temp dir. Only the PAT **id** is stored in `.out/pat-id.txt` (gitignored) so `just down` can revoke it.

The response step expects `RESPONSE_CLIENT_ID` / `RESPONSE_CLIENT_SECRET` in the environment, stores them in Key Vault, and redacts them from `.out/response-deployment.json`.

## Testing

1. `just content && just verify-content` — rules, functions, and 24 shared searches; each search is executed
2. `just response-capability` — records SSF vs Response Actions selection in `.out/response-capability.json`
3. Deploy playbook with `dry_run=true`, then POST [`content/response/sample-incident-payload.json`](content/response/sample-incident-payload.json) to the Logic App HTTP trigger (replace the sample email with a real lab identity)
4. Confirm ISC workflow receives nothing in dry-run; after `dry_run=false`, confirm an **approval** appears before disable

## Next slice: Microsoft Defender

Not enabled in this pass. When ready:

1. Connect Microsoft Defender for Endpoint / Microsoft 365 Defender to the same LAW
2. Join `SecurityAlert` / device identity fields to `SailPointISC_Events_CL` on normalized UPN / `AttributesUserId`
3. Reuse the same response playbook (`source=SENTINEL`) for containment
