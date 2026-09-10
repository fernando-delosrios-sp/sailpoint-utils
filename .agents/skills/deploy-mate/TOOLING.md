# deploy-mate — MCP, skill & CLI tooling

Install, configure, and **use** mapped tools during **Arm-ready** and **Harvest**. Manual console paste is the last resort.

## Arm — map tools to source services

For **each source service** from Catalog, add a row to `configuration.md` → **Collection tooling** with up to three layers:

| Source service | Vars | MCP / skill | Local CLI | Primary method |
|----------------|------|-------------|-----------|----------------|
| Fly.io | `FLY_API_TOKEN` | — | `flyctl` | cli |
| Stripe | `STRIPE_*` | Stripe MCP | `stripe` | mcp → cli |
| Neon | `DATABASE_URL` | Neon MCP | `neonctl` | cli → mcp |
| AWS | `AWS_*` | — | `aws` | cli |
| GitHub | `GITHUB_TOKEN` | — | `gh` | cli |

Also map **deploy tooling** per deploy target. Every var must trace to at least one automated path (`mcp`, `skill`, or `cli`) before `manual`.

Use `search` for current CLI install/auth commands when unsure. Use `find-skills` when no MCP/skill exists.

## Arm-ready — install & configure (required before Scaffold and Harvest)

**Independent preliminary process.** **Collaborate with the user** — auth often requires their browser, credentials, or approval. Do not enter Scaffold or Harvest until complete.

**Default: do not skip.** Proceed only when **every** Collection tooling **and** Deploy tooling row has a terminal status — zero rows remain `pending`.

### Status state machine

| Status | Meaning | Blocks Arm-ready complete? |
|--------|---------|---------------------------|
| `pending` | Not yet attempted | **Yes** — must resolve |
| `needs-auth` | Installed but auth incomplete | **Yes** — finish auth or opt-out |
| `not-installed` | CLI/MCP missing | **Yes** — install or opt-out |
| `install-failed` | Install failed | **Yes** — retry or opt-out |
| `ready` | Verify succeeded; evidence in setup notes | No |
| `opt-out` | User declined; vars downgraded | No |
| `manual-only` | No tool mapped; manual is sole path | No |

**`pending` after Arm-ready starts is a failure mode** — update the row or the phase is not done.

### Per-row protocol

Process **every row** in Collection tooling and Deploy tooling tables, in order:

1. **Detect** — `which <cli>`, `GetMcpTools`, or read skill `SKILL.md`
2. **Install** — if missing and mapped; guide user when agent cannot install
3. **Authenticate** — `mcp_auth`, `fly auth login`, etc.; wait for user on interactive flows
4. **Verify** — run read-only command or MCP tool call; **agent runs the command**, does not assume success from existing `.env` values
5. **Update row** — set Status + Verify evidence pointer in `configuration.md` tooling table
6. **Update setup notes** — record path, version, auth profile, verify command + result summary (redact secrets)

If no MCP/CLI exists for a row and primary chain is `manual`, set Status → `manual-only` after confirming with `find-skills` / `search`.

If user opts out, set Status → `opt-out` with reason in setup notes; downgrade affected var blocks.

### A. MCP & skills

For each mapped MCP or skill:

1. **Discover** — `GetMcpTools` (MCP) or read skill `SKILL.md`
2. **Install** — skill: `npx skills add …`; MCP: `.cursor/mcp.json` or Cursor Settings → MCP
3. **Configure** — document auth env vars (names only)
4. **Authenticate** — `mcp_auth` when status is `needsAuth`; **wait for user** if browser flow required
5. **Verify** — read-only tool call; record command + result in MCP setup notes
6. **Update Status** — `ready | needs-auth | install-failed | opt-out` in tooling table

### B. Local CLIs (required when mapped)

For each mapped CLI:

1. **Detect** — run `which <cli>` and `<cli> --version` (or equivalent)
2. **Install** — if missing, guide user and run install when approved:

   | CLI | Typical install (macOS) | Verify |
   |-----|-------------------------|--------|
   | `flyctl` | `brew install flyctl` | `fly version` |
   | `vercel` | `npm i -g vercel` | `vercel --version` |
   | `aws` | `brew install awscli` | `aws --version` |
   | `gh` | `brew install gh` | `gh --version` |
   | `stripe` | `brew install stripe/stripe-cli/stripe` | `stripe --version` |
   | `neonctl` | `npm i -g neonctl` | `neonctl --version` |
   | `terraform` | `brew install terraform` | `terraform version` |
   | `kubectl` | `brew install kubectl` | `kubectl version --client` |
   | `docker` | Docker Desktop / `brew install docker` | `docker --version` |

   Prefer official install docs via `search` when the table doesn't cover the platform (Linux, Windows).

3. **Authenticate** — run or guide login; **user completes interactive flows**:

   | CLI | Auth command | Notes |
   |-----|--------------|-------|
   | `flyctl` | `fly auth login` | Opens browser |
   | `vercel` | `vercel login` | Opens browser |
   | `aws` | `aws configure` / `aws sso login` | Access key or SSO profile |
   | `gh` | `gh auth login` | Scopes: `repo`, `read:org` as needed |
   | `stripe` | `stripe login` | Pairs CLI to account |
   | `neonctl` | `neonctl auth` | Opens browser |

4. **Verify** — read-only command proving access:

   ```bash
   fly apps list
   vercel whoami
   aws sts get-caller-identity
   gh auth status
   stripe config --list
   neonctl projects list
   ```

5. **Record** — CLI path, version, auth profile, verify output (redact secrets) in `configuration.md` → CLI setup notes
6. **Update Status** — `ready | needs-auth | not-installed | opt-out` in tooling table

### Tooling audit (mandatory before Scaffold/Harvest)

After all rows processed, present this table in chat — must match `configuration.md`:

| Source / target | Tool | Status | Verify command | Result |
|-----------------|------|--------|----------------|--------|
| Render | Render MCP | ready | `list_services` | 1 service |
| Slack | slack CLI | opt-out | — | user declined; manual fallback |
| OpenAI LLM | — | manual-only | — | no tool mapped |

**Completion check:** count rows — `pending` must be **0**. Ask user: "Arm-ready audit complete — proceed to Scaffold/Harvest?" **Wait for reply.**

Updating `progress.md` Arm-ready without zero pending rows in `configuration.md` **fails the gate**.

### Anti-rush rules (Arm-ready)

| Forbidden | Why |
|-----------|-----|
| Mark Arm-ready complete with `pending` tooling rows | Status table is the source of truth, not progress narrative |
| Skip verify because `.env` already has values | Verify proves tool access, not file contents |
| Set `ready` without verify evidence in setup notes | Status must be auditable |
| Narrative opt-out in progress.md without row Status → `opt-out` | Every row must be terminal in configuration.md |
| Batch-skip rows "not needed for CI/CD" | Use `opt-out` or `manual-only` per row with reason |

### When user opts out

Record `opt-out` with reason in setup notes. Set row Status → `opt-out`. Downgrade affected vars to the next available method (`cli` → `manual`). Update each var block.

### MCP config template (project-local)

```json
{
  "mcpServers": {
    "<server-id>": {
      "command": "npx",
      "args": ["-y", "<package>"],
      "env": {
        "API_KEY": "${env:VAR_NAME}"
      }
    }
  }
}
```

## Scaffold — platform resource staging

Uses Arm-ready CLIs. See [CONFIG-GUIDE.md](CONFIG-GUIDE.md) § Scaffold for platform table and rules.

Agent **runs** scaffold commands when CLI status is `ready`. Record results in **Scaffold registry**.

```bash
# Fly — app shell only
fly apps create <app-name> --org <org>

# Neon — project + branch
neonctl projects create --name <env>-<app>

# Vercel — link or create
vercel link --yes

# AWS — bucket
aws s3 mb s3://<env>-<app>-assets --region <region>
```

Re-run Scaffold during Harvest when blockers reference missing resources. **Never** run deploy commands (`fly deploy`, `vercel deploy`, `slack run`, …) — see [CONFIG-GUIDE.md](CONFIG-GUIDE.md) § Deploy scope.

## Harvest — tool-first collection

Collect **deploy-critical** vars only. Skip `local-dev` and `runtime-derived` — mark excluded per [CONFIG-GUIDE.md](CONFIG-GUIDE.md) § Deploy scope.

For each deploy-critical var, attempt methods in order until value retrieved. **Skip none that are mapped and `ready`.**

| Priority | Method | Action |
|----------|--------|--------|
| 1 | `mcp` | Call mapped MCP tool. `GetMcpTools` first if schema unknown. |
| 2 | `skill` | Invoke mapped skill (`search`, `env-secrets-manager`, …). |
| 3 | `cli` | Run mapped CLI commands — prefer structured output (`--json`, `-o json`). |
| 4 | `manual` | Document steps from CONFIG-GUIDE; user pastes value. |

When Primary method is `cli` and no MCP/skill mapped, start at priority 3.

### CLI collection examples

Document exact commands in each var's **How to obtain** block:

```bash
# Fly — create/read deploy token
fly tokens create deploy -a <app-name>

# Neon — connection string (use Scaffold registry project ID)
neonctl connection-string --project-id <id> --database-name <db> --pooled

# AWS — fetch SSM parameter
aws ssm get-parameter --name "/<env>/DATABASE_URL" --with-decryption --query Parameter.Value --output text

# GitHub — fine-grained token (guide user) or gh api for repo secrets metadata
gh auth token   # only when user explicitly approves; prefer creating named token

# Stripe — restricted key via API (stripe CLI)
stripe api_keys list
```

Agent **runs** these commands when CLI status is `ready` — do not only print them for the user.

After retrieval:

1. Confirm shape (prefix, length) — never echo full secret in chat
2. Run **Verify** command from var block
3. Write to `.deploy-mate/<env>/.env` (`chmod 600`); diff before overwrite
4. Update Harvest status + `Via:` (`flyctl`, `neon-mcp`, `manual`, …) + `Round:`

### Failure handling

| Failure | Action |
|---------|--------|
| MCP `needsAuth` | `mcp_auth`, retry |
| CLI not installed | Run Arm-ready install; retry |
| CLI auth failed | Re-run login with user; record blocker if stuck |
| Permission denied | Record blocker; fall back to next method |
| Resource missing | Scaffold mini-pass; retry |
| All automated failed | Manual Document steps; leave Blocker for next Harvest round |

## Skills install reference

```bash
npx skills add fernando-delosrios-sp/skills --skill search
npx skills search <keyword>
```

## Collection tooling section (configuration.md)

```markdown
## Collection tooling

| Source service | MCP / skill | Local CLI | Primary | Status |
|----------------|-------------|-----------|---------|--------|
| Neon | neon-mcp | `neonctl` | cli | ready |

## MCP setup notes
…

## CLI setup notes

### neonctl
- Installed: `/opt/homebrew/bin/neonctl` (v2.x)
- Auth: `neonctl auth` — profile `<user@email>`
- Verified: `neonctl projects list` → 3 projects
```

## Inject verify (post-inject, read-only)

After **inject ci** or **inject runtime**, confirm secrets landed without reading values:

| Platform | Verify command | Expected |
|----------|----------------|----------|
| GitHub Actions | `gh secret list` | Secret **names** present |
| Fly | `fly secrets list -a <app>` | Secret **names** present |
| Vercel | `vercel env ls` | Var **names** for target env |
| AWS SSM | `aws ssm describe-parameters --parameter-filters "Key=Name,Values=/<env>/…"` | Parameter names exist |

Redact any accidental value leakage in setup notes. Inject verify is metadata-only — never decrypt or print secret values.

## Runtime visibility tooling (arm visibility)

Mapped during **`arm visibility`** — after Forge proposal sign-off, before `forge artifacts`. Separate from Arm-ready (Deploy + Collection tooling).

**Scope:** platform-access verify only before deploy — prove CLI/MCP auth and read-only commands work. Do **not** expect live app logs or health HTTP 200 until **Verify** after Deploy.

### Per-row protocol

For each row in `configuration.md` → **Runtime visibility tooling**:

1. **Detect** — reuse CLI from Deploy tooling when same platform; add row if missing
2. **Authenticate** — same login flows as Arm-ready when status is not `ready`
3. **Verify** — read-only platform command (not app-specific output):

   | Platform | Tier | Verify command (pre-deploy) | Post-deploy (Verify phase) |
   |----------|------|----------------------------|----------------------------|
   | Fly | tier-1 | `fly auth whoami`, `fly apps list` | `fly status -a <app>`, `curl <health-url>` |
   | Fly | tier-2 | `fly logs --help` (syntax check) | `fly logs -a <app> --no-tail -n 50` |
   | GitHub Actions | tier-2 | `gh auth status` | `gh run watch`, `gh run view --log-failed` |
   | Kubernetes | tier-1 | `kubectl config current-context` | `kubectl get pods -n <ns>` |
   | Vercel | tier-1 | `vercel whoami` | `curl <deployment-url>/health` |

4. **Update row** — Status + verify evidence in setup notes (redact secrets)
5. **Tier-2 deferred** — row may stay `opt-out` or `manual-only` when user ack'd deferral at Forge sign-off

### Completion check

All **tier-1** rows for deploy-critical components must be terminal (`ready`, `opt-out`, or `manual-only`) before `progress.md` → Runtime visibility tooling — ready. Tier-2 rows required only when not deferred.




