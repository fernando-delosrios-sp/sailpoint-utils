# deploy-mate — artifact templates

Copy sections into `.deploy-mate/<env>/` files. Replace placeholders; delete unused sections.

## progress.md (per environment)

Path: `.deploy-mate/<env>/progress.md` — one file per environment, not shared at repo root.

```markdown
# deploy-mate progress — <env>

Started: <date>
Status: in-progress | complete

## Phase checklist
- [ ] Recon — environment selected
- [ ] Survey — sign-off: pending | approved <date>
- [ ] Catalog — var name inventory
- [ ] Arm — tooling map (deploy + collection)
- [ ] Arm-ready — tooling verified — `<ready>/<total> ready`, `<opt-out> opt-out`, `<manual-only> manual-only` — **0 pending**
- [ ] Scaffold — placeholder resources staged — acknowledged <date>
- [ ] Document — obtain playbooks (hard gate)
- [ ] Harvest — .env collection — in-progress | finished <date>
- [ ] Forge — strategy sign-off: pending | approved <date>
- [ ] Runtime visibility — planned (Forge sign-off) <date>
- [ ] Runtime visibility tooling — ready <date>
- [ ] Forge — deployment artifacts generated
- [ ] Inject CI — pending | done <date>
- [ ] Inject runtime — pending | done <date>
- [ ] Deploy — pending | <date> outcome: …
- [ ] Verify — pending | passed | failed <date>

## Harvest rounds
| Round | Date | Collected | Validated | Blocked | User action |
|-------|------|-----------|-----------|---------|-------------|
| 1 | | | | | |

## Re-run delta (<date>)
| Section | Status |
|---------|--------|
| architecture.md | unchanged \| updated \| new \| removed |
| configuration.md | … |
| deployment.md | … |
| generated files | … |

## Generated files
| File | Purpose | Created |
|------|---------|---------|
```

## architecture.md

```markdown
# Architecture — <env>

## Summary
<one paragraph>

## Diagram

<!-- Mandatory. Do not sign off without this section. -->

### Deploy topology

```mermaid
flowchart TB
  subgraph deploy["Deploy target — <platform>"]
    app["<app>"]
  end
  db[("<db>")]
  ext["<external service>"]
  app --> db
  app --> ext
```

### Container view

<!-- When 3+ containers: invoke c4-diagram, link file here -->
<!-- [architecture-<env>.drawio](./architecture-<env>.drawio) -->

## Components

| Component | Role | Confidence | Evidence | Visibility |
|-----------|------|------------|----------|------------|
| <name> | <runtime role> | confirmed \| inferred \| unknown | <file:line or config path> | T1: GET /health, `fly status`; T2: `fly logs`; chain: runtime → CI |
| worker | queue consumer | confirmed | … | T1: `fly machine list`; T2: deferred — no log drain yet |

## Deploy targets
| Target | Platform | Notes |
|--------|----------|-------|

## Data & external services
| Service | Purpose | Env vars (names only) |
|---------|---------|----------------------|

## Sign-off
- [ ] User approved — <date or pending>
```

## configuration.md

```markdown
# Configuration — <env>

## Tooling

### Deploy tooling

| Deploy target | MCP / skill | Local CLI | Status | Verify evidence |
|---------------|-------------|-----------|--------|-----------------|
| | | | pending \| ready \| opt-out \| manual-only | setup notes § |

### Collection tooling

| Source service | Vars | MCP / skill | Local CLI | Primary chain | Status | Verify evidence |
|----------------|------|-------------|-----------|---------------|--------|-----------------|
| | | | `flyctl` | cli → manual | pending \| ready \| opt-out \| manual-only | setup notes § |

### Runtime visibility tooling

<!-- Mapped during arm visibility — after Forge proposal sign-off. Platform-access verify only before deploy. -->

| Component | Tier | MCP / skill | Local CLI | Read path | Status | Verify evidence |
|-----------|------|-------------|-----------|-----------|--------|-----------------|
| api | tier-1 | — | `flyctl` | `fly status`, GET /health | pending \| ready \| opt-out \| manual-only | setup notes § |
| api | tier-2 | — | `flyctl`, `gh` | `fly logs`, `gh run watch` | pending \| ready \| opt-out \| manual-only | setup notes § |

## Scaffold registry

<!-- Resources created in Scaffold phase — IDs/names referenced in Document and Harvest -->

| Resource | Platform | ID / name | Created | Unblocks vars |
|----------|----------|-----------|---------|---------------|
| | | | | |

## CLI setup notes

### `<cli-name>`
- Path: `<which output>` (version) — or `not-installed`
- Auth: `<login command>` — profile/account — or `n/a (manual-only)`
- Verified: `<read-only command>` → `<result summary>` — **required before Status → ready**
- Status: `ready | opt-out | manual-only | needs-auth | not-installed`

## Environment variables

<!-- One ### block per var — full template in CONFIG-GUIDE.md. Summary index: -->

| Name | Class | Deploy scope | Required | Source service | Document | Harvest |
|------|-------|--------------|----------|----------------|----------|---------|
| `VAR_NAME` | secret | deploy-critical | yes | Stripe | done | pending |
| `SLACK_BOT_TOKEN` | secret | local-dev | no | Slack | done | excluded |

---

### `VAR_NAME`

(Full per-variable block per CONFIG-GUIDE.md — include How to obtain steps, Format & validation, Deploy mapping, Harvest status)

## MCP setup notes

### `<server-id>`
- Installed: `<path or npx package>`
- Auth: `<mcp_auth / env var names>` — or `needs-auth`
- Verified: `<read-only tool call>` → `<result summary>` — **required before Status → ready**
- Status: `ready | opt-out | needs-auth | install-failed`
```

## deployment.md

Write **strategy sections first** (Forge proposal). Repo files only after Sign-off.

```markdown
# Deployment — <env>

## Ship policy

<!-- Forge proposal — user picks policy for this environment -->

| Policy | `on-request` \| `auto` |
| Default | `on-request` |

**`on-request`** — finish session work; cite deploy command from Steps; wait for user to request deploy or `/deploy-mate deploy`.

**`auto`** — after deployable code changes, when pipeline gates pass, run Steps deploy then verify without asking.

Full rules: skill `SHIP-POLICY.md` (or `.deploy-mate/SHIP-POLICY.md` if copied at Forge). **Resolution:** missing section → **`on-request`** (see SHIP-POLICY § Policy resolution).

## Prerequisites
- [ ] Document complete (obtain playbooks)
- [ ] Harvest finished — `.env` complete (deploy blocked until done)

## Proposed strategy

<!-- Forge proposal — draft and revise with user before any repo file generation -->

### Platform & runtime
<target platform, region, scaling notes>

### CI/CD flow
<trigger → build → test → deploy stages; branch/tag policy>

### Build & containers
<Dockerfile vs buildpack, multi-stage, compose if local>

### Env injection
<how `.env` vars reach runtime — platform secrets, GitHub Actions, …>

### Rollback
<how to revert a bad deploy>

### Runtime visibility

<!-- Required — every deploy-critical component needs tier-1; tier-2 may defer with ack -->

Per component (mirror `architecture.md` → Components Visibility column):

| Component | Tier-1 (hard) | Tier-2 (soft) | Read chain | Boot time | Tier-2 deferral |
|-----------|---------------|---------------|------------|-----------|-----------------|
| api | GET /health, `fly status` | `fly logs`, `gh run watch` | runtime → CI | 30s optional | — |
| worker | `fly machine list` | `fly logs` | runtime only | — | deferred <date> — no log drain yet |

- **Tier-1** — health URL and/or platform status CLI (**runtime first**); blocks Deploy until documented in Steps and tooling ready
- **Tier-2** — log tail/stream; CI workflow conclusion when CI deploys (**CI second**); deferrable with user ack at Forge sign-off
- **Non-HTTP components** — tier-1 uses platform process/container status minimum (`fly machine list`, `kubectl get pods`)

### Optional scope
- DNS: … | deferred
- Migrations: … | deferred

## Sign-off
- [ ] User approved strategy — <date or pending>
- Open questions resolved: …

## Steps
<!-- Fill after sign-off -->
1. …

## Generated files
<!-- Fill after sign-off — list every repo file created -->
| File | Purpose |
|------|---------|

## Env var references
Names only — values in `.deploy-mate/<env>/.env`:
- `VAR_NAME` — used by …
```

## .env (gitignore)

```bash
# .deploy-mate/<env>/.env — chmod 600, never commit
# KEY=value
```

Add to project `.gitignore` if missing:

```
.deploy-mate/**/.env
```

## AGENTS.md fragment

Merge into the **project** root `AGENTS.md` during **`forge artifacts`** (confirm before overwrite). One pointer — ambient Ship policy is not reliable without it; deploy-mate is user-invoked and its body does not load during regular session work.

```markdown
## Ship (deploy-mate)

When `.deploy-mate/` exists and session work touches deployable code, read `.deploy-mate/<env>/deployment.md` → **Ship policy** before deploy or verify.
```

Replace `<env>` with the target environment name when the project has a single env; list both when multiple env folders exist.




