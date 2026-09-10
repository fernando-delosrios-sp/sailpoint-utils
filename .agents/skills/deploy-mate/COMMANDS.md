# deploy-mate — commands

Load this file for the invoked command only. Shared lexicon, artifacts, and gates: [SKILL.md](SKILL.md).

## help [cmd]

**Use when:** discovering available commands, recipes, or details for one command. Does not read project state unless `help <cmd>` needs no artifacts.

### help (no argument)

Present concisely in chat:

1. **Purpose** — deployment readiness for one environment: architecture, env vars, CI/CD artifacts, runtime visibility, secret injection, deploy.
2. **Phase order** — Recon → Survey → Catalog → Arm → Arm-ready → Scaffold → Document → Harvest → Forge proposal → **arm visibility** → Forge artifacts → Inject → Deploy → Verify.
3. **Command table** — copy from [SKILL.md § Invocation](SKILL.md).
4. **Recipes:**

| Goal | Commands |
|------|----------|
| Guided end-to-end | `/deploy-mate` or `/deploy-mate run` — chain until a gate; re-invoke after unblocking |
| First time (manual) | `recon` → `survey` → `catalog` → `arm` → `arm-ready` → `scaffold` → `document` → `harvest` (repeat) → `harvest finish` → `forge proposal` → `arm visibility` → `forge artifacts` → `inject ci` → `inject runtime` → `deploy` → `verify` |
| Fix tools only | `arm` → `arm-ready` |
| Collect secrets | `harvest` (repeat rounds) → `harvest finish` |
| Ship it | `forge proposal` → `arm visibility` → `forge artifacts` → `inject ci` → `inject runtime` → `deploy` → `verify` |
| One step only | `continue` |

5. **Gates** — compact table from [SKILL.md § Gates](SKILL.md).
6. **Subcommands** — `run` (default, chains phases); `continue` (one phase); `harvest finish`; `forge proposal` / `forge artifacts`; `arm visibility`; `inject ci` vs `inject runtime`.

**Invalid command** — if the user typed an unknown command, suggest the closest match and `/deploy-mate help`.

**Done when:** user knows what to run. No artifact mutations.

### help `<cmd>`

For the named command, report only:

- Prerequisites (gates)
- Done-when (one sentence)
- Forbidden (bullets)
- Example: `/deploy-mate <cmd> staging`

Do **not** paste the full protocol — point to the matching section in this file.

**Done when:** user has enough to invoke the command correctly.

## status

**Use when:** resuming work, checking blockers, or choosing the next command.

1. Resolve `<env>` from the argument or ask if ambiguous and multiple env folders exist.
2. Read `.deploy-mate/<env>/progress.md` and skim sibling artifacts.
3. Report: current phase checklist, open gates, Harvest round count, tooling rows still `pending`, deploy-critical vars not Collected/Validated, Forge sign-off state, **runtime visibility plan and tooling readiness**, Inject CI/runtime status, Deploy/Verify state.
4. Read `deployment.md` → Env injection / CI/CD flow to determine which **inject** targets apply (CI-only, runtime-only, or both).
5. Suggest the next command (usually `run` or the specific phase blocking progress).

**Done when:** user has a clear picture of state and a recommended next command. No artifact mutations required.

## run

**Use when:** guided end-to-end — same as bare `/deploy-mate`. Chain consecutive phases in **one invocation** until a gate requires user input or the pipeline is complete.

1. Run **status** (inline — stop only if `<env>` is ambiguous).
2. **Loop** — while a next incomplete phase exists:
   1. Execute that phase's protocol from this file (Recon → Survey → Catalog → Arm → Arm-ready → Scaffold → Document → Harvest → Forge proposal → **arm visibility** → Forge artifacts → Inject → Deploy → Verify).
   2. **Stop the loop** when any applies:
      - **Gate needs user** — Survey sign-off, Arm-ready audit ack, Scaffold ack, Forge proposal sign-off, inject CHECKPOINT, deploy CHECKPOINT (resolved Ship policy **`on-request`** — default when section missing; see [SHIP-POLICY.md](SHIP-POLICY.md) § Policy resolution)
      - **Harvest** — always stop after **one round** (report table; prompt continue or `harvest finish`)
      - **Pipeline complete** — Verify passed or nothing left
      - **Blocker** — prerequisites unmet for next phase
      - **Mid-phase user need** — interactive auth, ambiguous env, overwrite confirmation
   3. If none applied, immediately continue to the next phase **without ending the turn**.
3. **End turn** with summary: phases completed this run, open gate if any, exact re-invoke hint (`/deploy-mate run` after unblocking).

**Forbidden:** auto-approving sign-offs; skipping gates; marking Harvest finished without user; inject without CHECKPOINT approval; deploy without CHECKPOINT unless resolved Ship policy is explicitly **`auto`**; chaining past a Harvest round in the same run.

**Done when:** loop stopped at gate/blocker/completion; user knows what to do next.

## continue

**Use when:** advancing **one phase** only — explicit step-by-step control.

1. Run **status** (inline — do not stop for user unless `<env>` is ambiguous).
2. Execute the **single next incomplete phase** in order: Recon → Survey → Catalog → Arm → Arm-ready → Scaffold → Document → Harvest (**one round only**) → Forge proposal → **arm visibility** → Forge artifacts → Inject (if next) → Deploy → Verify.
3. **Stop at every gate** — Survey sign-off, Arm-ready audit ack, Scaffold ack, Harvest round end, Forge proposal sign-off, inject checkpoint, deploy CHECKPOINT (resolved Ship policy **`on-request`** — default when section missing). Do not auto-skip holds.
4. After a Harvest round or any gate, **end the turn** and wait for the user.

**Done when:** the current phase (or one Harvest round) completes or a gate blocks further progress.

## reconcile

**Use when:** re-running after repo or infra changes; often paired with `recon`.

1. Run **Recon** for `<env>`.
2. Diff existing artifacts against current repo state.
3. In `<env>/progress.md`, mark each section: `unchanged | updated | new | removed`.
4. Diff `architecture.md` → Components Visibility column and `deployment.md` → Runtime visibility when present.
5. Never overwrite `.env` values or generated deployment files without confirmation.
6. Recommend which phase commands to re-run based on deltas — when visibility plan changed, recommend **`arm visibility`** and **`forge artifacts`** refresh.

**Done when:** re-run delta recorded and user knows what to refresh.

## recon [env]

**Phase 0.** Argument `[env]` sets the target when provided.

1. Ask which environment (e.g. `staging`, `production`) unless already stated.
2. If `.deploy-mate/<env>/` exists, read `progress.md` and sibling artifacts — treat as a **re-run** (see **reconcile** when drift is likely).
3. Create missing dirs and seed `<env>/progress.md` from [ARTIFACTS.md](ARTIFACTS.md) if new.

**Done when:** target `<env>` is named and prior artifacts are loaded or scaffolded.

## survey

**Phase 1.** Requires Recon complete.

Read manifests, infra configs, specs, and README. Draft `.deploy-mate/<env>/architecture.md` with **evidence** per component:

| Confidence | Meaning |
|------------|---------|
| `confirmed` | Explicit config or code reference cited |
| `inferred` | Reasonable deduction; cite what you read |
| `unknown` | Not determined — blocks sign-off for prod components |

### Diagram (mandatory)

Every `architecture.md` **must** include a `## Diagram` section — text-only architecture is incomplete.

1. **Deploy topology** — embedded Mermaid in `architecture.md` showing runtime components, deploy targets, and external services (always).
2. **Container view** — invoke `c4-diagram` when the system has 3+ containers; link the generated `.drawio` file from `architecture.md`. Use `design-doc-mermaid` or platform diagram skills when Mermaid layout is insufficient.

Diagram labels must match component names in the tables below.

**Legwork first** for evidence gaps. Invoke `search`, `find-skills` (niche stack) only when:

- Any production component is `inferred` with no strong evidence
- Stack or platform is ambiguous after file scan
- User asks for deeper analysis

**Excluded:** `graphify`, `improve-codebase-architecture`.

Present draft; **gate** — do not proceed until user sign-off on architecture.

**Done when:** `architecture.md` exists with a populated `## Diagram` section (Mermaid + linked C4 when applicable), every prod component is `confirmed` or explicitly accepted by user, and sign-off is recorded in `<env>/progress.md`.

## catalog

**Phase 2.** Requires Survey sign-off.

From architecture and code (`process.env`, `.env.example`, deploy configs, README), list every env var **name**. For each, record in `configuration.md`:

- **Class:** `secret` | `config` | `derived`
- **Deploy scope:** `deploy-critical` | `local-dev` | `runtime-derived` — see [CONFIG-GUIDE.md](CONFIG-GUIDE.md) § Deploy scope
- **Required** for this `<env>` (yes/no + default if optional) — **only** for `deploy-critical` vars does Required: yes block Harvest
- **Consumed by** (service + evidence path — cite deploy config vs local dev script)
- **Source service** (Stripe, Neon, Fly, etc.)

Names only — no values. When the same name appears in both deploy and local dev paths, split into separate Catalog entries or document both consumers with scope per path.

**Done when:** every runtime dependency in `architecture.md` maps to a named var with class, deploy scope, and source service, or an explicit "none needed" note; every var in `.env.example` is classified — none left `unknown` scope.

## arm

**Phase 3.** Requires Catalog complete.

Map **two** tool layers in `configuration.md` — see [TOOLING.md](TOOLING.md):

1. **Deploy tooling** — MCPs/skills for each deploy target (Fly, Vercel, Terraform, …)
2. **Collection tooling** — MCP, skill, **local CLI**, and fallback method per **source service** from Catalog

Every var must have at least one automated path (`mcp`, `skill`, or `cli`) before `manual`. Use `search` for CLI install/auth commands; `find-skills` when no tool exists.

**Done when:** deploy targets and source services each have tooling rows with MCP, CLI, install path, primary method, and intended collection chain.

## arm-ready

**Phase 3b.** Gate before Scaffold and Harvest. Requires Arm complete.

**Collaborate with the user** on every auth step; do not assume credentials exist.

Execute the Arm-ready protocol in [TOOLING.md](TOOLING.md) — **one tooling row at a time**:

1. **Discover** → **install** (if needed) → **authenticate** → **verify** with a read-only command or MCP call
2. **Update** the row's **Status** in `configuration.md` → Collection tooling (and Deploy tooling) **immediately** after each attempt — never leave rows at `pending` once Arm-ready has started
3. **Record** verify output in MCP setup notes or CLI setup notes (redact secrets)
4. Repeat for **every** mapped row — MCP, skill, and CLI

Terminal statuses only: `ready | opt-out | manual-only`. Intermediate: `needs-auth | not-installed | install-failed`. **`pending` is forbidden when marking Arm-ready complete.**

| Status | When |
|--------|------|
| `ready` | Verify command/call succeeded; evidence in setup notes |
| `opt-out` | User declined this tool; affected vars downgraded to next method |
| `manual-only` | No MCP/CLI mapped — manual is the only path; set explicitly after confirming no tool exists |

User may **opt out** per service — record `opt-out` and downgrade affected vars to the next method.

**Hold** — after processing all rows, present the tooling audit table (see TOOLING.md). Ask user to confirm. **Wait for reply** before Scaffold or Harvest.

**Forbidden:** marking Arm-ready complete while Collection or Deploy tooling rows are still `pending`; skipping verify because values already exist in `.env`; updating `progress.md` without updating tooling table Status columns.

**Done when:** every Collection tooling **and** Deploy tooling row has terminal status; each `ready` row has verify evidence in setup notes; tooling audit table presented; user confirms tooling is usable; `<env>/progress.md` cites `N/N tooling rows terminal`.

## arm visibility

**Arm subcommand.** Runs after **Forge proposal sign-off**, before **`forge artifacts`**. Maps **Runtime visibility tooling** — the third tooling table in `configuration.md`. Does **not** re-run full Arm-ready for Deploy or Collection rows.

**Prerequisites:** Forge strategy sign-off recorded; runtime visibility plan in `deployment.md` → Runtime visibility and `architecture.md` → Components Visibility column.

### INPUT (load in order)

| Priority | Source | Use for |
|----------|--------|---------|
| P1 (HIGH) | `deployment.md` → Runtime visibility | Per-component tier-1/tier-2, read chain, deferrals |
| P1 (HIGH) | `architecture.md` → Components Visibility | Component names and summary |
| P2 (MED) | `configuration.md` → Deploy tooling | Platform CLIs already mapped for deploy |
| P3 (LOW) | [TOOLING.md](TOOLING.md) § Runtime visibility tooling | Verify command patterns |

### Protocol

1. Read runtime visibility plan — every deploy-critical component must have tier-1 defined.
2. Add or update **Runtime visibility tooling** rows in `configuration.md` — one row per component × tier (tier-2 rows optional when deferred).
3. For each row: detect CLI/MCP → authenticate if needed → **platform-access verify only** (read-only list/status/auth — NOT live app logs or health HTTP before deploy). See [TOOLING.md](TOOLING.md) § Runtime visibility tooling.
4. Set terminal status per row: `ready | opt-out | manual-only`. **`pending` forbidden** when marking complete.
5. Present audit table; mark `progress.md` → **Runtime visibility tooling — ready** with date when all tier-1 rows are terminal.
6. Tier-2 rows: verify when not deferred; deferred tier-2 rows need not be `ready` for Deploy.

**Forbidden:** re-running full Arm-ready; verifying live health URLs or log output before deploy; skipping tier-1 rows for deploy-critical components.

**Done when:** all tier-1 Runtime visibility tooling rows terminal; audit evidence in setup notes; `progress.md` marks tooling ready.

## scaffold

**Phase 3c.** Requires Arm-ready complete and audit ack. Run before first Harvest pass; re-enter during Harvest when blockers require new resources.

Create **placeholder platform resources** the deployment will need — not the app deploy itself. Use Arm-ready tools (CLIs first). See [CONFIG-GUIDE.md](CONFIG-GUIDE.md) § Scaffold.

Examples: Fly app shell, Neon project + database, Vercel project link, S3 bucket, Stripe restricted key scaffold, GitHub repo/environment, empty K8s namespace.

**Forbidden:** deploying application code (`fly deploy`, `vercel deploy`, `slack run`, `npm run deploy`, uploading bundles) to obtain env vars.

For each resource:

1. Check whether it already exists (CLI list/describe)
2. If missing and user approves, create with minimal config — record name, ID, region in `configuration.md` → **Scaffold registry**
3. Update affected Catalog vars — newly available IDs/names become obtainable in Document/Harvest
4. Present the **Scaffold registry** summary; ask user to confirm resources are correct.
5. On confirmation, mark Scaffold in `<env>/progress.md` → `acknowledged <date>`. **Hold** until confirmed.

**Done when:** every **deploy-critical** Catalog var whose obtain path requires a platform resource either has that resource scaffolded and recorded, or has an explicit defer/blocker with user acknowledgment; **and** user acknowledged the Scaffold registry in `progress.md`.

## document

**Phase 4a.** Hard gate before Forge. Requires Catalog complete; Scaffold vars referenced where applicable.

For **every** var from Catalog, write a full per-variable block in `configuration.md` following [CONFIG-GUIDE.md](CONFIG-GUIDE.md).

Each block **must** include: purpose, class, required/default, consumed-by evidence; **How to obtain** (numbered steps); **Format & validation**; **Deploy mapping**.

Reference scaffolded resources by name/ID from the Scaffold registry. Use `search` when vendor obtain steps are unclear. Reject placeholder or one-line obtain instructions.

**Done when:** every var has a CONFIG-GUIDE block with no rejected obtain patterns; `<env>/progress.md` marks Document complete.

## harvest

**Phase 4b — one round.** Requires Arm-ready complete, Scaffold **acknowledged** in `progress.md` (first pass), Document blocks exist for vars attempted this round.

**Tool-first** — run mapped MCPs, skills, **and CLIs** before manual paste. Agent executes CLI commands. See [TOOLING.md](TOOLING.md) and [CONFIG-GUIDE.md](CONFIG-GUIDE.md) Harvest protocol.

**Deploy scope filter** — collect **deploy-critical** vars only. `local-dev` → `excluded — local-dev`. `runtime-derived` → `excluded — runtime-derived`.

This command runs **one round** then **holds**:

1. **Scaffold** any newly unblocked resources (mini-pass) — platform shells only
2. **Collect** — attempt **every** pending **deploy-critical** var with Required: yes — MCP → skill → CLI → manual
3. **Validate** → write `.deploy-mate/<env>/.env` (`chmod 600`) → update Harvest status + `Via:` note
4. **Report** — full status table for **every** Catalog var
5. **Stop** — ask: "Continue Harvest (`/deploy-mate harvest`) or mark finished (`/deploy-mate harvest finish`)?" **Wait for reply.**

**Forbidden:** advancing to Forge in the same turn; deploying app code to obtain vars; marking Harvest finished without user saying so.

### harvest finish

User explicitly closes Harvest. Verify every **deploy-critical** Required: yes var is Collected + Validated or has an accepted Blocker. Record in `<env>/progress.md` → Harvest finished with date.

**Done when (round):** round logged in Harvest rounds table; user prompted for next action.

**Done when (finish):** user declared finished and deploy-critical Required: yes vars satisfied per CONFIG-GUIDE § Completion.

## forge

**Phase 5.** Requires Document complete **and** Harvest finished.

Without a subcommand, pick by state:

- No strategy sign-off → run **forge proposal**
- Sign-off recorded, runtime visibility tooling not ready → run **`arm visibility`**
- Tooling ready, artifacts not generated → run **forge artifacts**

### forge proposal

1. **Draft** — invoke `deployment-pipeline-design`. Write `.deploy-mate/<env>/deployment.md` **strategy sections only** (see [ARTIFACTS.md](ARTIFACTS.md)). Include required **Runtime visibility** section — per-component tier-1/tier-2, read chain (**runtime first, CI second**), boot time overrides, tier-2 deferrals with ack. Include **Ship policy** — ask user: **`on-request`** (default; user asks to deploy) or **`auto`** (agent deploys + verifies after deployable fixes when gates pass).
2. Update `architecture.md` → Components **Visibility** column to match the plan.
3. **Present** — summarize trade-offs and open questions.
4. **Dialog** — revise until user approves or accepts deferrals (tier-2 deferrals require explicit ack).
5. **Sign-off** — record in `deployment.md` → Sign-off and `<env>/progress.md` → Forge strategy sign-off **and** Runtime visibility — planned (Forge sign-off). **Hold** until recorded.

**Forbidden:** generating repo deploy files before sign-off; Forge sign-off without tier-1 for every deploy-critical component.

**Done when:** strategy sign-off recorded; runtime visibility plan written; progress rows updated.

### forge artifacts

Requires Forge strategy sign-off **and** **`arm visibility` complete** (tier-1 tooling ready).

Generate repo files per approved strategy:

| Output | Location |
|--------|----------|
| Process doc | `.deploy-mate/<env>/deployment.md` (complete Steps including tier-1/tier-2 verify commands + Generated files) |
| CI workflow | `.github/workflows/*.yml` when applicable |
| Container config | `Dockerfile`, `docker-compose.yml` |
| Platform config | `fly.toml`, `vercel.json`, `infra/*.tf`, etc. |

List every generated file in `deployment.md` and `<env>/progress.md`. Reference var **names** only. Confirm before overwrite.

Copy [SHIP-POLICY.md](SHIP-POLICY.md) to `.deploy-mate/SHIP-POLICY.md` for offline reference. Merge [ARTIFACTS.md](ARTIFACTS.md) § AGENTS.md fragment into project root `AGENTS.md` when present — confirm before overwrite.

**Done when:** `deployment.md` lists all generated files; overwrites confirmed; `<env>/progress.md` marks Forge artifacts generated; AGENTS.md pointer merged or user declined.

## inject

**Phase 5a+5b.** Push deploy-critical var **values** from `.deploy-mate/<env>/.env` to remote targets per Document → Deploy mapping. **Never echo values in chat.**

Without subcommand, run **inject ci** then **inject runtime** — **CHECKPOINT** between: present CI inject summary, wait for user approval before runtime inject.

Requires Harvest finished and every **deploy-critical** Required: yes var Collected + Validated in `.env`.

Runtime visibility tooling is **not** required for Inject — it gates **Deploy** only.

## inject ci

**Phase 5a.** Push vars to the **CI/CD orchestrator** — GitHub Actions secrets/environments, GitLab CI variables, etc.

**Prerequisites:** Harvest finished; `.env` deploy-critical complete; Document Deploy mapping lists CI targets. Runtime visibility prep **not** required.

### INPUT (load in order)

| Priority | Source | Use for |
|----------|--------|---------|
| P1 (HIGH) | `.deploy-mate/<env>/.env` | Values (read only — never paste in chat) |
| P1 (HIGH) | `configuration.md` → per-var **Deploy mapping** (CI path) | Which vars → which secret names / environments |
| P2 (MED) | `deployment.md` → Env injection, CI/CD flow | Orchestrator choice, environment names |
| P2 (MED) | `configuration.md` → Deploy tooling | `gh`, GitLab CLI, etc. — must be `ready` |
| P3 (LOW) | `search` | Vendor CLI syntax when unsure |

### Protocol

1. Build inject plan table: var name → remote target (repo secret, environment secret, CI variable) — **names only**.
2. **CHECKPOINT:** present plan; **wait for user approval** before any write.
3. For each var: read value from `.env`; push via ready CLI (`gh secret set`, `gh api …/environments/…/secrets`, GitLab API, …). Agent runs commands.
4. Record in `<env>/progress.md` → Inject CI: `done <date>` + table of var **names** pushed and targets (no values).
5. Optional verify: list secret **names** via read-only API (`gh secret list`, metadata only).

**Forbidden:** echoing secret values; injecting `local-dev` vars; injecting before Harvest finished.

**Done when:** all planned CI vars pushed or explicitly deferred with user ack; progress.md updated.

## inject runtime

**Phase 5b.** Push vars to the **runtime platform** — Fly secrets, Vercel env, AWS SSM/Parameter Store, K8s secrets, etc.

**Prerequisites:** Harvest finished; `.env` deploy-critical complete; Forge artifacts generated (injection mapping may reference platform config); Document Deploy mapping lists runtime targets. Runtime visibility prep **not** required.

### INPUT (load in order)

| Priority | Source | Use for |
|----------|--------|---------|
| P1 (HIGH) | `.deploy-mate/<env>/.env` | Values (read only) |
| P1 (HIGH) | `configuration.md` → per-var **Deploy mapping** (runtime path) | Platform secret names, regions |
| P2 (MED) | `deployment.md`, generated platform config (`fly.toml`, …) | App name, region, env scope |
| P2 (MED) | `configuration.md` → Deploy tooling | `flyctl`, Vercel CLI, `aws` — must be `ready` |
| P3 (LOW) | `search`, [TOOLING.md](TOOLING.md) § Inject verify | CLI syntax, post-inject verify |

### Protocol

1. Build inject plan table: var name → platform target — **names only**.
2. **CHECKPOINT:** present plan; **wait for user approval** before any write.
3. For each var: push via ready CLI (`fly secrets set`, `vercel env add`, `aws ssm put-parameter`, …). Agent runs commands.
4. Record in `<env>/progress.md` → Inject runtime: `done <date>` + var **names** and targets (no values).
5. Run inject verify command per platform when available (see TOOLING.md § Inject verify).

**Forbidden:** echoing values; injecting before Forge artifacts when mapping depends on generated config; deploy-for-config.

**Done when:** all planned runtime vars pushed or deferred with user ack; progress.md updated.

## deploy

**Phase 6.** Execute deploy — not for obtaining config (that is Harvest/Scaffold).

**Prerequisites (all must pass):**

- Harvest finished
- Forge artifacts generated
- Forge strategy sign-off recorded
- **`arm visibility` complete** — tier-1 Runtime visibility tooling rows terminal
- Every **deploy-critical** Required: yes var Collected + Validated in `.env`
- **Tier-1 verify commands** documented in `deployment.md` → Steps (requires Forge artifacts)
- **Inject complete** per `deployment.md` strategy — CI deploy path requires Inject CI; direct-to-platform requires Inject runtime; both when strategy uses CI → platform

### INPUT (load in order)

| Priority | Source | Use for |
|----------|--------|---------|
| P1 (HIGH) | `deployment.md` → Steps, Runtime visibility, Generated files | Deploy command, verify commands, rollback |
| P1 (HIGH) | `<env>/progress.md` | Inject, visibility tooling, gate state |
| P2 (MED) | `configuration.md` → Deploy tooling, Runtime visibility tooling | CLI/MCP for deploy execution |
| P3 (LOW) | `search` | Platform-specific deploy flags |

### Protocol

1. Run **status** gate checks; stop and name blockers if any fail — including visibility:
   - Tier-1 commands missing from `deployment.md` → Steps → unlock with **`forge artifacts`**
   - Tier-1 Runtime visibility tooling rows not terminal → unlock with **`arm visibility`**
2. Resolve Ship policy per [SHIP-POLICY.md](SHIP-POLICY.md) § Policy resolution (missing → **`on-request`**). Read **Steps**; summarize deploy plan (names only for secrets).
3. Resolved **`on-request`:** **CHECKPOINT** — confirm environment, target, rollback path. **Wait for explicit approval.**
   Resolved **`auto`:** proceed when gates pass — no CHECKPOINT.
4. Execute via Deploy tooling (CLI/MCP/workflow dispatch). Pause for interactive auth when needed.
5. Record in `<env>/progress.md` → Deploy: date, command/workflow, outcome, link if CI.
6. On failure: surface rollback steps from `deployment.md` → Rollback; do **not** re-Harvest deploy outputs unless user re-runs **catalog**.

**Forbidden:** deploy during Harvest/Scaffold; deploy to obtain missing vars; deploy without CHECKPOINT unless resolved Ship policy is explicitly **`auto`**; deploy without required inject.

**Done when:** deploy executed or CI triggered; outcome recorded; suggest `/deploy-mate verify`.

## verify

**Phase 7.** Post-deploy **runtime visibility** checks from `deployment.md` → Steps and Runtime visibility plan.

**Prerequisites:** Deploy recorded in `<env>/progress.md`.

1. Read `deployment.md` → Runtime visibility and Steps for per-component read paths.
2. **Tier-1** (hard) — per deploy-critical component, **runtime first**:
   - Run health URL and/or platform status CLI (`curl /health`, `fly status`, `kubectl get pods`, …)
   - Default **3 attempts with 10s backoff** before tier-1 failure; override wait when Forge records expected boot time
   - Non-HTTP components: platform process/container status minimum
3. **Tier-2** (soft) — after tier-1 passes for a component:
   - Log tail/stream (`fly logs`, …)
   - CI confirmation when applicable (`gh run watch`) — **CI second** after runtime signals
   - Skip components with tier-2 `deferred` in `deployment.md`; report `deferred` in summary
4. Agent executes all commands — do not only print.
5. Record in `<env>/progress.md` → Verify: `passed | failed <date>` + **per-component tier summary** (URLs, status codes, deferred — no secrets).
6. Tier-1 failure → overall `failed`; point to Rollback section — do not auto-rollback without user approval. Tier-2 deferrals do not fail the run.

**Done when:** tier-1 and applicable tier-2 steps executed; outcome and per-component tier summary recorded in progress.md.

