# Access Model Change Management

GitHub-centric governance of SailPoint Identity Security Cloud (ISC) **entitlements** (metadata), **access profiles** and **roles**.

This folder is the **installer and template**. Running the installer creates (or updates) a dedicated GitHub repository wired to one ISC tenant: daily REST backups, pull-request-only changes, ISC Workflow approvals, auto-apply on merge, known-good tags, and governance-group-approved full restore.

## Why not SP-Config?

`sp-config` does not export entitlements. Access profiles and roles can ride SP-Config, but entitlements only support limited metadata updates through the Entitlements API. This project therefore uses each object's REST API end-to-end: dump → edit in git → push back.

## Layout

| Path | Purpose |
|------|---------|
| [`installer/`](installer/) | Node CLI that creates the target GitHub repo and enables the ISC tenant |
| [`template/`](template/) | Files copied into the target repo (scripts, workflows, schemas, `access/`) |
| [`isc/`](isc/) | Workflow export imported into ISC |

## Prerequisites

1. **PowerShell is not required.** Node.js 20+, `gh` (authenticated), and network access to the ISC tenant and GitHub.
2. A **dedicated service identity** in ISC with rights to manage access profiles, roles and entitlement metadata, plus the **Search** user level (`sp:search:read`). Create an API client (client credentials) for that identity — the installer stores it as GitHub Actions secrets so audit events attribute applies to the service identity. Search read lets drift approvals name the actor on the out-of-band edit. Without it, drift detection still runs and the actor is left unknown.
3. At least one **governance group** in ISC (first-level approver for changes; sole approver for restores).
4. A logged-in `gh` session, plus a **fine-grained GitHub PAT** for ISC→GitHub `repository_dispatch` (see [Dispatch PAT](#dispatch-pat-isc--github) below). The installer asks for this **after** the target repo exists.
5. Permission to create a **GitHub App** (user or org) that the installer configures as the only ruleset bypass actor on `main`.

## Install

From this folder:

```bash
cd "ISC/Access Model Change Management"
npm install
npm run install-tenant
```

The CLI will:

1. Validate `gh` auth and ISC client credentials  
2. Let you pick entitlement **source allowlist** and the **governance group**  
3. Create or update the GitHub repository from [`template/`](template/)  
4. Ask for the **dispatch PAT** (ISC→GitHub callbacks only — or optionally reuse your `gh` login token)  
5. Guide **GitHub App** creation / install (separate from the PAT: bot commits + ruleset bypass) and set repository secrets  
6. Upsert the single `AMCM Approval` ISC workflow, provision its external trigger OAuth client, and enable it  
7. Apply a `main` ruleset (PR-only + required `validate` and `isc-approval` checks). On a free GitHub plan this is skipped for private repositories, and the install continues.  
8. Dispatch the first backup  

Re-running is safe: the existing repo and workflow are updated in place.

### Dispatch PAT (ISC → GitHub)

The ISC workflow calls GitHub `repository_dispatch` when an approval is decided. That call needs a credential stored in the ISC workflow **Configuration** step (`githubDispatchToken`). GitHub does **not** allow creating personal access tokens via the API or `gh`, so the installer opens the creation page in your browser (or accepts a paste).

**Prefer a fine-grained PAT** scoped to the single AMCM repository with **Contents: Read and write**. Do not use a classic PAT or your day-to-day `gh` OAuth token in production tenants — those usually include `repo`, `workflow`, and org scopes across many repositories.

#### Start from the GitHub UI

1. Sign in at [github.com](https://github.com)  
2. Click your **profile photo** (top right) → **Settings**  
3. In the left sidebar, scroll to the bottom → **Developer settings**  
4. **Personal access tokens** → **Fine-grained tokens**  
5. Click **Generate new token**  

Direct link (same screen): [github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new)

Do **not** use **Tokens (classic)** for this — that is a different, broader token type.

That permission set is enough: `repository_dispatch` only needs **Contents: Read and write**. Leave **Organizations** at 0. Do not add Administration, Workflows, or other repository permissions.

#### User-owned repository

Use when the repo lives under your personal account (resource owner = you).

1. Open the create form via the UI path above  
2. **Token name:** e.g. `amcm-dispatch-<repo>`  
3. **Expiration:** choose a rotation period (e.g. 90 days)  
4. **Resource owner:** your personal account  
5. **Repository access:** Only select repositories → the AMCM repo  
6. Under **Permissions**, open the **Repositories** tab  
7. If **Contents** is not listed yet, click **+ Add permissions** → add **Contents**  
8. Set **Contents** → **Access: Read and write**  
9. Leave **Metadata** as **Access: Read-only** (required; you cannot remove it)  
10. Leave the **Organizations** tab at **(0)**  
11. **Generate token** → copy it once → paste into the installer  

#### Organization-owned repository

Use when the repo lives under an org (e.g. `emea-tes-team/…`).

1. Open the create form via the UI path above (still under **your** user Settings → Developer settings — tokens are always created as you, even for org repos)  
2. **Token name** / **Expiration** as above  
3. **Resource owner:** select the **organization** (not your personal account)  
4. **Repository access:** Only select repositories → the AMCM repo  
5. Same **Permissions** as the user case: **Repositories** tab → **Contents: Read and write**, **Metadata: Read-only**, **Organizations (0)**  
6. **Generate token** → copy it once → paste into the installer  

Org caveats:

- An org owner must allow fine-grained PATs: open the org page → **Settings** → **Personal access tokens** (under Third-party Access / similar) and permit fine-grained tokens. If the org is missing from Resource owner, that policy is blocking you.  
- Some orgs require an owner to **approve** the token before it works. Create it, then ask an owner to approve (org → Settings → Personal access tokens → Pending requests).  
- Prefill URLs can show the wrong owner visually — always confirm Resource owner is the org before generating.  

#### Convenience fallback (installer only)

The installer can reuse `gh auth token` for a quick install. That token is convenient but **broader than needed**. Rotate to a fine-grained PAT afterward by editing the ISC workflow Configuration step (or re-running the installer with `--dispatch-token`).

### Secrets written to the target repo

| Secret | Use |
|--------|-----|
| `ISC_TENANT_URL` | API base |
| `ISC_CLIENT_ID` / `ISC_CLIENT_SECRET` | Service identity client credentials |
| `AMCM_APP_ID` / `AMCM_APP_PRIVATE_KEY` | GitHub App for bot commits |
| `ISC_TRIGGER_URL` | External trigger URL of the single `AMCM Approval` workflow (handles change, restore and drift requests; see [`isc/README.md`](isc/README.md)) |
| `ISC_TRIGGER_CLIENT_ID` / `ISC_TRIGGER_CLIENT_SECRET` | OAuth client the Actions exchange for a token at `{ISC_TENANT_URL}/oauth/token` before calling the trigger |

## Operating model

```mermaid
flowchart LR
  Author -->|PR| Repo
  Repo -->|validate| CI
  CI -->|external trigger, kind=change| ApprovalWF
  Restore -->|external trigger, kind=restore| ApprovalWF
  Backup -->|external trigger, kind=drift| ApprovalWF
  ApprovalWF -->|change: gov group then item owners<br/>restore/drift: gov group only| Approvals
  Approvals -->|repository_dispatch| Callback
  Callback -->|isc-approval + auto-merge<br/>or drift sync to main| Repo
  Repo -->|apply REST| ISC
  Apply -->|known-good tag + ledger| Repo
```

### Changing an access item

1. Branch from `main`, edit JSON under `access/`.  
2. Open a PR. CI validates schemas and name references.  
3. GitHub calls the **AMCM Approval** workflow with `kind: "change"`. The **governance group** decides first; if `approval.ownerApproval` is enabled, every changed item's **owner** is then asked in parallel and any single rejection fails the change. Approvers see the GitHub author, PR title, link and change summary in their ISC **Approvals** inbox.  
4. On approve, GitHub sets the `isc-approval` status (bound to a **diff content hash**, not the commit SHA) and enables auto-merge.  
5. On merge, Actions apply create/update/delete via REST, write new ids back, create a `known-good/…` tag, and append the ledger.  
6. Reject closes the PR. Approvals nobody acts on expire after `approval.timeoutDays` and get the `approval-expired` label; comment `/request-approval` to retry.

Entitlements are **update-only** (name, description, privileged, requestable, owner). Creates/deletes of entitlements are skipped.

### Daily backup and drift

The Backup Action snapshots allowlisted entitlements, all access profiles and all roles. If ISC was edited outside git, nothing is committed automatically: GitHub calls the **AMCM Approval** workflow with `kind: "drift"`, which routes straight to the **governance group only** (item owners are never contacted — nobody "owns" an out-of-band ISC edit). The approval text names the ISC audit actor associated with each drifted item, searched from the events index since the last time git and ISC matched (or the last 14 days when the ledger has no such point). On approve, the decision callback re-detects drift against live ISC (to make sure it hasn't moved again), syncs it to `main`, and records a drift ledger entry whose Who column is those actors. On reject, the callback restores ISC to match git and records that. On expiry, ISC is left unchanged and the next scheduled backup asks again. Entitlements this repo cannot create or delete are skipped, so a rejected entitlement-only drift can remain and will be asked about again. Audit search is best-effort: a missing Search user level, or no matching event, leaves the actor unknown and does not block the approval.

### Full restore

1. Actions → **Restore** → pick a `known-good/*` tag. Tags created before this rename (`isc-applied/*`) are still accepted.  
2. A full reconciliation plan is built against live ISC.  
3. GitHub calls the same **AMCM Approval** workflow with `kind: "restore"`, which routes straight to the governance group (item owners are never contacted for restores).  
4. On approve, the plan is applied; `main` is reconciled from ISC; a restore ledger entry is written.

### History

`changes/YYYY-MM/*.json` is the append-only ledger. `README.md` in the target repo is generated from it and lists recent changes, approvals, tags and drift.

### Init

**Actions → Init** starts the repository over. Type `RESET` to confirm. The run stops if any other workflow is still queued or running.

It replaces `main` with one commit: a fresh backup of the current ISC access model (allowlisted entitlements, all access profiles, all roles), a baseline ledger entry, and a new `known-good/…` tag. Scripts, workflows, `config.yaml`, and secrets stay. ISC is not modified. The snapshot is the new baseline, so the next backup should report no drift.

After that commit is on `main`, Init deletes tags, releases, other branches, and previous workflow runs, and closes open pull requests. Issues are deleted when the GitHub App is allowed to; otherwise open issues are closed. GitHub keeps closed and merged pull requests. Git history from before the new commit is gone and cannot be restored from this repository.

Deleting previous workflow runs needs the GitHub App repository permission **Actions: Read and write**. The installer asks for that on a new App. An App created before this permission was listed must get it under the App's **Permissions & events**, then the installation must accept the updated permissions. Without it, Init still replaces `main` and the run fails only on that cleanup step.

## Target repo layout

```
access/
  entitlements/<source-slug>/<name-slug>.json
  access-profiles/<name-slug>.json
  roles/<name-slug>.json
changes/YYYY-MM/
config.yaml
scripts/
schemas/
.github/workflows/
```

Files are keyed by **name slug**; the ISC `id` lives inside the JSON. Cross-references use **names**; apply resolves them to ids in dependency order (entitlements → access profiles → roles). An entitlement name that a caller cannot resolve to exactly one entitlement fails the apply rather than being guessed.

ISC allows several entitlements in one source to share a name (AWS policy entitlements commonly do). Those files get a suffix from the entitlement's native value — `<name-slug>__<value-slug>.json` — so each one is backed up instead of overwriting the others. Names that are unique in their source keep the plain `<name-slug>.json`. Entitlement identity itself is source plus native value, not the file name, so renaming an entitlement in ISC reads as an update.

## Local commands (inside the target repo)

```bash
npm install
npm run validate
npm run plan
npm run backup          # needs ISC_* env
npm run restore -- --dry-run
npm run readme
npm test
```

## Admins: changing the governance group

Edit the **Configuration** step of the `AMCM Approval` ISC workflow (`governanceGroupId`), or update `config.yaml` in the GitHub repo via PR (used when building approval payloads). Keep them aligned.

## Tests

```bash
cd "ISC/Access Model Change Management"
npm install
npm test
# also:
cd template && npm test
```
