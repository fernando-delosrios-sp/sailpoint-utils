# deploy-mate — Ship policy

Per-environment rule for **when** the agent runs deploy and verify outside an explicit `/deploy-mate deploy` invocation — e.g. after fixing a reported issue during regular session work.

**Source of truth:** `.deploy-mate/<env>/deployment.md` → **Ship policy** (written at Forge proposal sign-off).

## Policy resolution

Before deploy (pipeline or ambient), resolve the effective policy:

1. Read `deployment.md` → **Ship policy** → Policy value.
2. **Missing section, empty table, or no explicit `auto`** → treat as **`on-request`** (CHECKPOINT required).
3. Only when Policy is explicitly **`auto`** → skip deploy CHECKPOINT when all gates pass.

Pre-Forge `deployment.md` files without **Ship policy** always resolve to **`on-request`**.

## Policy values

| Policy | Ambient (session work) | `/deploy-mate deploy` |
|--------|------------------------|------------------------|
| **`on-request`** (default) | Finish the fix; cite deploy command from `deployment.md` → Steps; **do not** run deploy or verify until the user asks | **CHECKPOINT** — confirm environment, target, rollback; wait for approval |
| **`auto`** | After deployable code changes, when pipeline gates pass, run Steps deploy then `/deploy-mate verify` (or inline verify protocol) **without asking** | Skip CHECKPOINT when all gates pass; execute deploy; record outcome |

## When Ship policy applies

Apply when **all** hold:

1. `.deploy-mate/<env>/` exists with Forge artifacts generated (`deployment.md` → Steps populated)
2. Session work changed **deployable** code or config cited in `deployment.md` → Generated files
3. The user's goal implies shipping the fix (bug report, "fix and deploy", production issue) — not local-only dev

Do **not** apply during Harvest, Scaffold, or initial pipeline setup — those phases use command protocols in [COMMANDS.md](COMMANDS.md), not Ship policy.

## Gate check (both policies)

Before any deploy — ambient or pipeline — verify:

- Harvest finished; deploy-critical `.env` complete
- Inject complete per `deployment.md` strategy
- Tier-1 runtime visibility tooling terminal; Steps documented
- No open Blockers on deploy-critical vars

If a gate fails: report blockers and the unlocking command; **do not** deploy.

## Ambient protocol

1. Resolve `<env>` — argument, session context, or sole folder under `.deploy-mate/*/`
2. Resolve Ship policy (see **Policy resolution**); read **Steps**
3. **`on-request`** (including missing policy): summarize fix; quote deploy command; end turn
4. **`auto`:** run gate check → execute Steps deploy → run verify protocol from [COMMANDS.md](COMMANDS.md) § verify → report outcome + rollback path on failure

## Project AGENTS.md pointer

Ship policy is only reliable in ambient work when the **project** `AGENTS.md` includes the pointer from [ARTIFACTS.md](ARTIFACTS.md) § AGENTS.md fragment. deploy-mate is user-invoked — the skill body is not loaded during regular session work without that pointer.

`forge artifacts` merges the fragment when `AGENTS.md` exists (confirm before overwrite). User may add it manually after Recon if Forge is not yet complete.
