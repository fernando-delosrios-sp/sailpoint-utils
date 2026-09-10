# deploy-mate — delegation map

Command entry points: [COMMANDS.md](COMMANDS.md). Fallbacks when mapped MCPs/skills cannot cover a source service. **Default path is Arm-ready install + use per [TOOLING.md](TOOLING.md)** — not manual-first.

## By phase

| Phase | Word            | Always                                                                                 | Fallback only                                                              |
| ----- | --------------- | -------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| 1     | Survey          | Agent file analysis; Mermaid deploy topology; `c4-diagram` when 3+ containers          | `search`, `find-skills` (niche stack), `design-doc-mermaid`                |
| 3     | Arm             | Collection + deploy tooling map; `find-skills` for unmapped services                   | MCP catalog search                                                         |
| 3     | Arm visibility  | Runtime visibility tooling map; platform-access CLI verify                             | `search` for platform status/log commands                                  |
| 3b    | Arm-ready       | Install, verify **each Deploy + Collection tooling row**; tooling audit                | User opt-out → row Status `opt-out`                                        |
| 3c    | Scaffold        | Create placeholder resources via ready CLIs                                            | User creates manually; record in registry                                  |
| 4a    | Document        | Per-var obtain playbooks; `search` for vendor steps                                    | —                                                                          |
| 4b    | Harvest         | Tool-first loop for **deploy-critical** vars only: MCP → skill → **CLI** → manual      | `search` for manual fallback steps                                         |
| 5     | Forge proposal  | `deployment-pipeline-design` — strategy dialog; required Runtime visibility section      | `cicd-pipeline-generator`, stack-specific deployment skills (options only) |
| 5     | Arm visibility  | Map Runtime visibility tooling; platform-access verify per [TOOLING.md](TOOLING.md)      | `search` for niche platform CLIs                                           |
| 5     | Forge artifacts | After arm visibility — generate repo files + verify Steps                              | `cicd-pipeline-generator`, stack-specific deployment skills                |
| 5a    | Inject CI       | `gh secret set`, GitHub API, GitLab CLI per Deploy mapping                             | `env-secrets-manager`, `search` for vendor syntax                          |
| 5b    | Inject runtime  | `fly secrets set`, `vercel env add`, `aws ssm put-parameter`, …                        | `search`, platform MCPs when mapped                                        |
| 6     | Deploy          | Deploy tooling CLI/MCP/workflow dispatch                                               | Stack-specific deployment skills                                           |
| 7     | Verify          | Commands from `deployment.md` → Steps                                                  | `search` for platform health checks                                        |

## When to delegate (Survey)

Diagrams are **not** optional — see SKILL.md Survey. Additional delegation when:

- Production component remains `inferred` after file scan
- Stack or platform ambiguous after reading manifests and README
- User requests deeper analysis or alternate diagram formats

## When to delegate (Arm)

`find-skills` when a source service has no obvious MCP/skill in the Arm map.

## When to delegate (Harvest)

Only **after** tool-first attempt fails or user opted out:

- `search` — current vendor console/CLI steps for manual fallback
- Manual collection — CONFIG-GUIDE Document steps verbatim

Do **not** skip MCP, skill, or **CLI** invocation when mapped and status is `ready`. Do **not** print CLI commands without running them unless the user must complete an interactive login in their terminal. Do **not** deploy application code or run dev runners (`slack run`, `fly deploy`, …) to obtain env vars — classify scope in Catalog instead.

## Harvest scope (Phase 4b)

Before collecting, check each var's **Deploy scope** in `configuration.md`. Only `deploy-critical` vars enter the collection loop. `local-dev` → excluded (placeholder optional). `runtime-derived` → excluded (document only). See CONFIG-GUIDE § Deploy scope.

## MCP setup (Arm-ready)

Execute per-row protocol for each mapped MCP/skill — see [TOOLING.md](TOOLING.md) § A. Update tooling table Status after verify. Do not mark Arm-ready complete while rows remain `pending`.

## CLI setup (Arm-ready)

Detect, install, authenticate, and verify each mapped CLI — see [TOOLING.md](TOOLING.md) § B. **Run verify commands**; record output in setup notes before Status → `ready`. Present tooling audit table; get user ack before Scaffold/Harvest.

## Scaffold delegation

Prefer CLI scaffold commands when Arm-ready status is `ready`. When CLI cannot create (permissions, billing), guide user through console steps from CONFIG-GUIDE § Scaffold and record result in Scaffold registry.

## Forge delegation

**Proposal first** — invoke `deployment-pipeline-design` to draft strategy; present trade-offs and ask for feedback. Do **not** generate `.github/workflows/*`, `Dockerfile`, `fly.toml`, or other repo deploy files until strategy sign-off is recorded.

After sign-off, invoke `cicd-pipeline-generator` and stack-specific deployment skills to produce artifacts aligned with the approved strategy.

## Inject delegation

**CI orchestrator** — prefer ready CLIs from Deploy tooling:

- GitHub: `gh secret set`, `gh api repos/…/environments/…/secrets`
- GitLab: `glab variable set` or API per Deploy mapping

**Runtime platform** — prefer ready CLIs:

- Fly: `fly secrets set`
- Vercel: `vercel env add`
- AWS: `aws ssm put-parameter` / Secrets Manager

When user prefers vault over direct push: `env-secrets-manager`. When CLI syntax unclear: `search`. **Never** echo values; **never** skip CHECKPOINT approval.

## Verify delegation

Run runtime visibility checks from `deployment.md` → Steps and Runtime visibility plan. **Tier-1 first** (runtime health/status, 3×10s retry), then **tier-2** (logs, `gh run watch` when CI deploys). Use Deploy tooling and Runtime visibility tooling CLIs. On tier-1 failure, point user to Rollback section — do not auto-rollback.

## Arm visibility delegation

After Forge proposal sign-off, map rows in `configuration.md` → Runtime visibility tooling. Reuse ready CLIs from Deploy tooling when same platform. Platform-access verify only — see [TOOLING.md](TOOLING.md) § Runtime visibility tooling. Do **not** re-run full Arm-ready.
