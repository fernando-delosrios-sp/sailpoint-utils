# deploy-mate

End-to-end deployment readiness for **one environment at a time** — architecture discovery, env-var cataloging, secret harvesting, CI/runtime injection, deploy, and post-deploy verification.

Greenfield or brownfield. The agent drives discovery; you sign off at gates. Generated repo files reference variable **names** only — secrets live in a gitignored `.env`.

## Install

From this skills repo:

```bash
npx skills add fernando-delosrios-sp/skills --skill deploy-mate
```

Or install everything and pick interactively:

```bash
git clone https://github.com/fernando-delosrios-sp/skills.git
cd skills && npm install && npm run install
```

deploy-mate is **user-invoked** (`disable-model-invocation: true`). In Cursor, type `/deploy-mate` to start.

## Quick start

| Goal | Command |
|------|---------|
| Guided end-to-end | `/deploy-mate` or `/deploy-mate run [env]` |
| Where am I? | `/deploy-mate status [env]` |
| Command catalog | `/deploy-mate help` |
| One phase at a time | `/deploy-mate continue [env]` |

Re-invoke `/deploy-mate run` after you unblock a gate (sign-off, Harvest round, tooling install, etc.).

**First-time manual path:**

```
recon → survey → catalog → arm → arm-ready → scaffold → document
→ harvest (repeat) → harvest finish → forge proposal → arm visibility
→ forge artifacts → inject ci → inject runtime → deploy → verify
```

Arguments: `[command] [env]` — e.g. `/deploy-mate arm-ready staging`. Omit `[env]` when only one `.deploy-mate/*/` folder exists or was named earlier in the session.

## What you get

Per environment, the skill maintains artifacts under `.deploy-mate/<env>/`:

```
.deploy-mate/
└── <env>/
    ├── progress.md          # phase checklist, Harvest rounds, blockers
    ├── architecture.md      # components, deploy topology, diagram
    ├── configuration.md     # var inventory, obtain playbooks, tooling tables
    ├── deployment.md        # strategy, Steps, ship policy, generated files
    └── .env                 # collected secrets — gitignored, chmod 600
```

Primary deliverable: **actionable secret and env-var guidance** — every deploy-critical variable documented with step-by-step obtain instructions, then collected and validated into `.env`.

## Pipeline phases

Each phase has a distinct name. Do not collapse them (e.g. Catalog ≠ Harvest).

| Phase | Command | Purpose |
|-------|---------|---------|
| **Recon** | `recon [env]` | Select environment; load or scaffold artifacts |
| **Survey** | `survey` | Architecture discovery + diagram + sign-off |
| **Catalog** | `catalog` | Inventory var names, scope, source services |
| **Arm** | `arm` · `arm visibility` | Map deploy, collection, and runtime visibility tooling |
| **Arm-ready** | `arm-ready` | Install, auth, verify every tooling row — zero `pending` |
| **Scaffold** | `scaffold` | Create placeholder platform resources |
| **Document** | `document` | Write per-var obtain playbooks |
| **Harvest** | `harvest` · `harvest finish` | Collect values into `.env` (one round per `run` segment) |
| **Forge** | `forge` · `forge proposal` · `forge artifacts` | Strategy dialog, then generate workflows/Dockerfile/platform config |
| **Inject** | `inject ci` · `inject runtime` · `inject` | Push `.env` to CI orchestrator and/or runtime platform |
| **Deploy** | `deploy` | Execute deploy after inject + prerequisites |
| **Verify** | `verify` | Post-deploy runtime visibility — tier-1 then tier-2 |

**Scope tags:** every Catalog variable is `deploy-critical`, `local-dev`, or `runtime-derived`. Harvest collects **deploy-critical** only.

**Runtime visibility:** tier-1 (health/status, runtime first) and tier-2 (logs, CI second) read paths. Planned at Forge sign-off; tooling mapped via `arm visibility`; executed at Verify. Tier-1 blocks Deploy; Inject is not blocked.

## Common recipes

| Goal | Commands |
|------|----------|
| Fix tooling only | `arm` → `arm-ready` |
| Collect secrets | `harvest` (repeat) → `harvest finish` |
| Ship it | `forge proposal` → `arm visibility` → `forge artifacts` → `inject ci` → `inject runtime` → `deploy` → `verify` |
| After infra/repo drift | `reconcile [env]` |

## Ship policy

Per-environment rule in `deployment.md` for when the agent deploys **outside** an explicit `/deploy-mate deploy`:

| Policy | Behavior |
|--------|----------|
| **`on-request`** (default) | Agent finishes fixes and cites the deploy command; waits for you to ask |
| **`auto`** | After deployable changes, when gates pass, agent runs deploy + verify without asking |

Pre-Forge `deployment.md` files without a **Ship policy** section resolve to **`on-request`** — deploy always requires CHECKPOINT unless Policy is explicitly **`auto`**.

For ambient session work (bug fixes, “fix and deploy”), the project `AGENTS.md` must include the pointer from [ARTIFACTS.md](ARTIFACTS.md) § AGENTS.md fragment — the skill body is not loaded during regular work without it. `forge artifacts` can merge this fragment when `AGENTS.md` exists.

Details: [SHIP-POLICY.md](SHIP-POLICY.md).

## Gates (summary)

Gates fail fast — the agent reports blockers and the command that unlocks the next step.

| Gate | Blocks |
|------|--------|
| Survey sign-off | Catalog through Harvest |
| Arm-ready complete | Scaffold, Harvest |
| Scaffold acknowledged | Harvest (first pass) |
| Harvest round end | Next round, Forge — hold for your reply |
| Harvest finished | Forge, Inject |
| Document complete | Forge |
| Forge strategy sign-off | `arm visibility`, `forge artifacts` |
| Runtime visibility tooling ready | `deploy` |
| `.env` deploy-critical complete | `inject`, `deploy` |
| Forge artifacts generated | `inject runtime` (when needed), `deploy` |
| Inject complete | `deploy` |
| Deploy recorded | `verify` |

Use `/deploy-mate status [env]` for a dynamic view of what should run next.

## Reference docs

| File | Contents |
|------|----------|
| [SKILL.md](SKILL.md) | Skill entry point — lexicon, invocation, gates |
| [COMMANDS.md](COMMANDS.md) | Per-command protocols (loaded by the agent at runtime) |
| [ARTIFACTS.md](ARTIFACTS.md) | Artifact templates and AGENTS.md fragment |
| [CONFIG-GUIDE.md](CONFIG-GUIDE.md) | Obtain playbook and Harvest guidance |
| [TOOLING.md](TOOLING.md) | MCP, skill, and CLI tooling map |
| [DELEGATION.md](DELEGATION.md) | When to delegate to other skills |
| [SHIP-POLICY.md](SHIP-POLICY.md) | Ambient deploy rules |

## Security

- Never commit `.deploy-mate/**/.env` — add to `.gitignore`.
- Generated files use `${VAR_NAME}` or platform secret references, not literal values.
- Harvest and Inject never echo secret values in chat.
