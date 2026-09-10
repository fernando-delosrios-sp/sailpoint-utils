---
name: deploy-mate
description: End-to-end deployment readiness for one environment — architecture, env vars, CI/CD artifacts, runtime visibility, secret injection, deploy. Invoke with `/deploy-mate [command] [env]`.
disable-model-invocation: true
argument-hint: "[command] [env] — help | run | status | continue | recon | survey | catalog | arm | arm-ready | arm visibility | scaffold | document | harvest | forge | inject | deploy | verify"
---

# deploy-mate

Greenfield or brownfield deployment readiness for **one environment at a time**. **Agent-first** discovery; delegate to skills only when confidence is low or the user asks. Primary deliverable: **actionable secret and env-var guidance** — every variable documented with step-by-step obtain instructions, then collected and validated into `.deploy-mate/<env>/.env`. Generated repo files reference var **names** only — never embed secrets.

Run **one command per invocation** unless using `run` (guided end-to-end) or `continue` (single phase). Load the command protocol from [COMMANDS.md](COMMANDS.md) before executing. Unknown command → `/deploy-mate help`.

## Process lexicon

Each **leading word** names one phase. Use it in chat, artifacts, and `progress.md` — never collapse distinct phases under "configuration."

| Word | Phase | Command |
|------|-------|---------|
| **Recon** | 0 | `recon [env]` |
| **Survey** | 1 | `survey` |
| **Catalog** | 2 | `catalog` |
| **Arm** | 3 | `arm` · `arm visibility` |
| **Arm-ready** | 3b | `arm-ready` |
| **Scaffold** | 3c | `scaffold` |
| **Document** | 4a | `document` |
| **Harvest** | 4b | `harvest` · `harvest finish` |
| **Forge** | 5 | `forge` · `forge proposal` · `forge artifacts` |
| **Inject** | 5a / 5b | `inject ci` · `inject runtime` · `inject` |
| **Deploy** | 6 | `deploy` |
| **Verify** | 7 | `verify` |

**Catalog ≠ Harvest.** Catalog names vars; Harvest collects values. **Arm-ready ≠ Harvest.** Arm-ready makes tools work; Harvest uses them. **Arm visibility ≠ Arm-ready.** Arm visibility maps runtime read paths after Forge sign-off; Arm-ready covers Deploy + Collection tooling only. **Scaffold ≠ Forge.** Scaffold stages empty platform shells; Forge generates repo deploy files. **Inject ≠ Harvest** — Inject pushes local `.env` to CI orchestrator and runtime platform. **Deploy ≠ Harvest/Scaffold** — Deploy ships the app; never deploy to obtain config.

**Runtime visibility** — per-component tier-1 (health/status, runtime first) and tier-2 (logs, CI second) read paths. Planned at Forge proposal sign-off; tooling mapped via **`arm visibility`** (after sign-off, before `forge artifacts`); executed at Verify. Tier-1 blocks Deploy; Inject is not blocked. See `configuration.md` → **Runtime visibility tooling** (third tooling table).

**Deploy scope** — every Catalog var is tagged `deploy-critical`, `local-dev`, or `runtime-derived`. Harvest collects **deploy-critical** only.

**Ship policy** — per-environment rule in `deployment.md` for when the agent deploys after session work (`on-request` | `auto`; missing section → **`on-request`**). Pipeline and ambient behavior: [SHIP-POLICY.md](SHIP-POLICY.md). Requires project `AGENTS.md` pointer (see [ARTIFACTS.md](ARTIFACTS.md) § AGENTS.md fragment) for ambient work — skill presence alone does not load these rules.

## Artifacts

```
.deploy-mate/
└── <env>/
    ├── progress.md
    ├── architecture.md
    ├── configuration.md
    ├── deployment.md
    └── .env               ← gitignored, chmod 600
```

Templates: [ARTIFACTS.md](ARTIFACTS.md). Obtain playbook: [CONFIG-GUIDE.md](CONFIG-GUIDE.md). Tooling: [TOOLING.md](TOOLING.md). Delegation: [DELEGATION.md](DELEGATION.md). Ship policy: [SHIP-POLICY.md](SHIP-POLICY.md). **Command protocols:** [COMMANDS.md](COMMANDS.md).

## Invocation

| Command | Use when |
|---------|----------|
| `help [cmd]` | Command catalog, recipes, phase order; optional detail for one command |
| `status [env]` | Where am I — progress, gates, blockers; recommend next command |
| *(bare)* / `run [env]` | **Guided end-to-end** — chain phases until a gate needs you; re-invoke after unblocking |
| `continue [env]` | Advance **one phase** (or one Harvest round) only |
| `reconcile [env]` | Re-run after repo/infra drift — delta in progress.md |
| `recon [env]` | Select env; load or scaffold artifacts |
| `survey` | Architecture discovery + diagram + sign-off |
| `catalog` | Inventory var names, scope, source services |
| `arm` | Map deploy + collection tooling |
| `arm visibility` | After Forge sign-off — map runtime visibility tooling + platform-access verify |
| `arm-ready` | Install, auth, verify every Deploy + Collection tooling row |
| `scaffold` | Create placeholder platform resources + user ack |
| `document` | Write per-var obtain playbooks |
| `harvest` | One collection round — then hold |
| `harvest finish` | User closes Harvest loop |
| `forge` | Proposal or artifacts — picks by sign-off state |
| `forge proposal` | Strategy dialog only — no repo files |
| `forge artifacts` | Generate workflows, Dockerfile, platform config |
| `inject ci [env]` | Push `.env` vars to CI/CD orchestrator (GitHub Actions, GitLab CI, …) |
| `inject runtime [env]` | Push `.env` vars to runtime platform (Fly, Vercel, AWS SSM, …) |
| `inject [env]` | Both inject targets — checkpoint between CI and runtime |
| `deploy [env]` | Execute deploy after inject + prerequisites |
| `verify [env]` | Post-deploy runtime visibility — tier-1 then tier-2 |

**Composition rules:**

- Arguments: `[command] [env]` — e.g. `/deploy-mate arm-ready staging`. Env may be omitted when only one `.deploy-mate/*/` exists or was named earlier in the session.
- **Gates apply to every command** — fail fast if prerequisites unmet; report blockers and the unlocking command.
- **`help` is static; `status` is dynamic** — help = what can run; status = what should run now.
- **`run` chains phases** — executes consecutive phases in one invocation until a gate requires user input, Harvest completes one round, or the pipeline is done. Re-invoke `/deploy-mate run` after unblocking.
- **`continue` advances one phase** — use when you want explicit step-by-step control.
- **`harvest` is one round per `run` segment** — repeat `/deploy-mate run` for the next Harvest round.

## Gates (summary)

| Gate | Blocks |
|------|--------|
| Survey sign-off | Catalog through Harvest |
| Arm-ready complete | Scaffold, Harvest — **zero `pending` tooling rows** |
| Arm-ready audit ack | Scaffold, Harvest |
| Scaffold acknowledged | Harvest (first pass) |
| Harvest round end | Next round, Forge — **hold until user replies** |
| Harvest finished (user declared) | Forge, Inject |
| Document complete | Forge |
| Forge strategy sign-off (includes runtime visibility plan) | `arm visibility`, `forge artifacts` |
| Runtime visibility tooling ready | `deploy` |
| `.env` deploy-critical complete | `inject`, `deploy` |
| Forge artifacts generated (tier-1 Steps documented) | `inject runtime` (when mapping depends on generated config); **`deploy`** |
| Inject CI complete | `deploy` (when CI runs deploy) |
| Inject runtime complete | `deploy` (when direct-to-platform) |
| Deploy recorded | `verify` |

Inject is **not** blocked by runtime visibility preparation.

`status` reads `deployment.md` to determine which inject targets apply for `<env>`.
