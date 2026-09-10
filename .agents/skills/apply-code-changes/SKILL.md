---
name: apply-code-changes
description: Apply tasks.md through verify last gate and handoff.
---

# Apply Code Changes

Orchestrate **apply**: execute `tasks.md` in order (Changelog group last), run the **verify** last gate, then hand off per **venue**.

**Core** = steps 0–6. **Change adapter** = pre-flight path resolution — [change-adapters.md](references/change-adapters.md).

**Verification ref** — branch where verify runs: `ORIGINAL_BRANCH` (local/worktree); `FEATURE_BRANCH` (remote).

**Never in apply:** archive, spec sync (merging deltas into `openspec/specs/**`), archive commit, `/opsx:archive`. The change's own `specs/**` deltas **are** apply-editable — see step 3.

## Invariant

**`ORIGINAL_BRANCH` is the durable branch for local and worktree apply** — no `openspec/<name>` feature branch on those venues. **`FEATURE_BRANCH` exists only for remote** (PR head). Worktree isolation uses ephemeral **`apply-<name>`** (`APPLY_REF`), squash-merged onto `ORIGINAL_BRANCH` at handoff then deleted.

## Session variables

| Variable | When set | Meaning |
|---|---|---|
| `CHANGE_ROOT` | Pre-flight (adapter) | Adapter `changeRoot` / user path — **planning read only** after bind |
| `CHANGE_ROOT_REL` | Pre-flight | Repo-relative path from `CHANGE_ROOT` — used to compute `ACTIVE_CHANGE_ROOT` |
| `NAME` | Pre-flight | Basename of the change — used in `apply-<name>` |
| `TRACKING_HINT` | Pre-flight (optional) | Non-authoritative adapter-path seed; may be from the wrong checkout |
| `TRACKING` | Setup + pre-bind merge | Authoritative fields (Issue, Change, Branch, PR, Presets). **Branch resolution reads merged `TRACKING` only** |
| `TRACKING_SETUP` | End of setup | Snapshot after setup — restore before store-adoption restart in pre-bind merge |
| `STORE_SOURCE` | Pre-flight (OpenSpec) | `explicit` for user/command `--store`, `hint` for `TRACKING_HINT` → store |
| `PRESET_OVERRIDES` | Setup | Current-run `venue`, `parallelism`, and explicit `STORE` — override Presets keys during every merge |
| `ORIGINAL_BRANCH` | Bind (step 2) | Base branch — local/worktree commits integrate here |
| `FEATURE_BRANCH` | Bind (step 2) | **Remote only** — PR head (`openspec/<name>` or `feature/<name>` default) |
| `APPLY_REF` | Bind (step 2) | **Worktree only** — ephemeral `apply-<name>` |
| `WORK_CHECKOUT` | Bind (step 2) | Git directory where the orchestrator runs |
| `ACTIVE_CHANGE_ROOT` | Bind (step 2) | `WORK_CHECKOUT` + `CHANGE_ROOT_REL` — **all artifact I/O after bind** |

## Venue matrix (single source of truth)

After bind, follow the row for `venue` × `parallelism`. Step 2 implements bind; step 6 implements handoff — do not contradict this table elsewhere.

| Venue | Parallelism | Main repo branch | `WORK_CHECKOUT` | Work ref | Handoff |
|---|---|---|---|---|---|
| `local` | `single` | `ORIGINAL_BRANCH` | main repo | — | Return control on `ORIGINAL_BRANCH` |
| `local` | `subagent-per-group` | `ORIGINAL_BRANCH` | main repo | group temps optional | Squash merge → `ORIGINAL_BRANCH` |
| `worktree` | `single` | `ORIGINAL_BRANCH` | worktree on `APPLY_REF` | `apply-<name>` | Squash merge → `ORIGINAL_BRANCH`; remove worktree; delete `APPLY_REF` |
| `worktree` | `subagent-per-group` | `ORIGINAL_BRANCH` | worktree on `APPLY_REF` | `apply-<name>` (+ group temps) | Squash merge → `ORIGINAL_BRANCH`; cleanup |
| `remote` | agent picks | `ORIGINAL_BRANCH` (idle) | runner on `FEATURE_BRANCH` | `FEATURE_BRANCH` | Push; PR `--base ORIGINAL_BRANCH`; link issue |

Legacy Presets key `workspace` → treat as `venue` when `venue` is absent.

## Inputs

After bind, paths are under `ACTIVE_CHANGE_ROOT`. Prefer OpenSpec `artifactPaths` / `contextFiles` when set.

| Priority | Source | Purpose |
|---|---|---|
| HIGH | `tasks.md` | Checkbox progress |
| HIGH | `specs/**/*.md` | Scenario → test coverage gate; reconciled in place when shipped behavior diverges (step 3) |
| HIGH | `design.md` | Design/spec coherence gate |
| MED | `proposal.md` | Changelog scope |
| MED | `TRACKING` / `tracking.md` | Issue/PR linkage + resume Presets |
| LOW | `docs/agents/issue-tracker.md` | Issue workflow when present |

**Trusted hint:** `TRACKING_HINT` loaded and its Change equals `CHANGE_ROOT_REL` (legacy: equals `CHANGE_ROOT`). Branch, Issue, PR, and Presets from an untrusted hint are ignored for merge overlay.

## Steps

### 0. Pre-flight (adapter — planning reads only)

1. Run a **change adapter** per [change-adapters.md](references/change-adapters.md); set `CHANGE_ROOT`, `CHANGE_ROOT_REL`, and `NAME`. Adapters **never create** on-disk `tracking.md`.
2. Read `tasks.md`, specs, `design.md`, `proposal.md` from `CHANGE_ROOT` for planning context.
3. Load `tracking.md` at `CHANGE_ROOT` into **`TRACKING_HINT`** when present; re-probe OpenSpec once when the hint selects a store. Do **not** treat it as final `TRACKING`.

### 1. Setup

**Interactive host** — **structured-choices** venue gate (one message; **must run** — a trusted Issue or filled Presets does not skip it):

1. Initialize **`TRACKING`**: copy non-empty `TRACKING_HINT` fields **field-by-field**, **except Branch, Issue, PR, and Presets keys** — copy those only on a **trusted hint**; set **Change** = `CHANGE_ROOT_REL`. Initialize empty **`PRESET_OVERRIDES`**. **Do not write to disk.**
2. **Venue:** `local` | `worktree` | `remote` → set `TRACKING` Presets → `venue` **and** `PRESET_OVERRIDES` → `venue`.
3. When the OpenSpec adapter set `STORE`, set Presets → `store`; add to `PRESET_OVERRIDES` **only** when `STORE_SOURCE` is `explicit`.
4. **Parallelism** (agent — not a user gate): choose `single` | `subagent-per-group` using the criteria below; set Presets → `parallelism` and `PRESET_OVERRIDES` → `parallelism`; note one-line rationale in session.
5. Snapshot **`TRACKING_SETUP`** = copy of `TRACKING`.

**Done when:** `PRESET_OVERRIDES` contains `venue` and `parallelism`; interactive hosts completed step 2 via structured-choices.

**Non-interactive host** (CI — no user present to answer; not merely a tool you cannot see): skip step 2 gate; set `venue` from merged Presets → `venue` (legacy `workspace`), else **`remote`** when shipping intent is clear, else **`local`**; choose `parallelism` per same criteria; lock both in `PRESET_OVERRIDES`; snapshot `TRACKING_SETUP`.

#### Parallelism criteria (all venues, including remote)

Choose **`subagent-per-group`** when every row holds; else **`single`**:

| Require | Rationale |
|---|---|
| Two or more numbered implementation `##` groups in `tasks.md` | Enough isolation to earn subagents |
| Platform supports Task/subagents | No fake parallelism |
| Venue supports git isolation | `local`: orchestrator commits on `ORIGINAL_BRANCH`; `worktree`: group temps under `apply-<name>-<slug>`; `remote`: runner uses `FEATURE_BRANCH` |

Sequential dispatch only — never concurrent subagents on shared git state.

Optional: invoke a **git worktree skill** when present for naming/cleanup conventions — never required.

### 2. Pre-bind merge, branch resolution, and bind

**Pre-bind tracking merge** — before branch resolution or bind:

1. Merge on-disk `tracking.md` at adapter `CHANGE_ROOT` when present (field-by-field; trusted-hint rules for Issue/PR/Branch).
2. When Presets → `venue` is **`remote`**: candidate `FEATURE_BRANCH` = `TRACKING` → Branch, else adapter default. When that branch exists locally or on `origin`, read `CHANGE_ROOT_REL/tracking.md` from it (prefer local, else `origin/<branch>`). When `STORE_SOURCE` is `hint` and path absent, search branch tree for `.../NAME/tracking.md`. Non-empty on-disk Branch ≠ candidate: **STOP**. Change mismatch: defer per store-adoption rules below.
3. **Merge** remote-branch tracking (**Pre-bind tracking merge** step 2 only): non-empty Issue, Branch, PR win; Presets keys merge individually. Overlay `PRESET_OVERRIDES`; set **Change** = `CHANGE_ROOT_REL`. Never replace `Presets` wholesale.
4. **Store adoption** (unchanged intent): when `STORE_SOURCE` is `hint` and Change mismatch deferred or branch Presets → `store` differs, adopt store, rerun adapter, **restore `TRACKING` from `TRACKING_SETUP`**, restart merge once.
5. Map legacy Presets → `workspace` to `venue` when `venue` empty.

**Branch resolution** — from merged `TRACKING` and Presets → `venue`:

1. **`ORIGINAL_BRANCH`:** `TRACKING` Presets → `base-branch`; else current branch; else repo default (`main` / `origin/HEAD`). Note assumption when inferred.
2. **`FEATURE_BRANCH`** — **remote only:** `TRACKING` → Branch, else adapter default. When exists on `origin` only, `git checkout -b FEATURE_BRANCH origin/FEATURE_BRANCH` — never recreate from `ORIGINAL_BRANCH`. When exists nowhere, `git checkout -b FEATURE_BRANCH ORIGINAL_BRANCH`.
3. **`APPLY_REF`** — **worktree only:** `apply-<NAME>`. Create from `ORIGINAL_BRANCH` if missing; never reuse a stale `apply-<NAME>` with unrelated commits — delete and recreate when Change differs.
4. Persist empty `base-branch` in `TRACKING` when inferred.

**Bind** — requires Presets → `venue` and `parallelism`. Set `WORK_CHECKOUT`, then `ACTIVE_CHANGE_ROOT = WORK_CHECKOUT + "/" + CHANGE_ROOT_REL`:

| Venue | Bind |
|---|---|
| **`local`** | Checkout `ORIGINAL_BRANCH` on main → `WORK_CHECKOUT` = main repo |
| **`worktree`** | Main on `ORIGINAL_BRANCH`. `git worktree add <path> -b APPLY_REF ORIGINAL_BRANCH` (or attach existing clean `APPLY_REF`) → `WORK_CHECKOUT` = worktree path |
| **`remote`** | Main on `ORIGINAL_BRANCH`. Resolve `FEATURE_BRANCH` per **Branch resolution** step 2. Checkout `FEATURE_BRANCH` in worktree or runner checkout; push `-u origin FEATURE_BRANCH` when new. Create **Issue** when empty and `docs/agents/issue-tracker.md` exists. Dispatch cloud/CI runner when platform supports; else orchestrate on `FEATURE_BRANCH` locally |

1. **Persist `tracking.md`** at `ACTIVE_CHANGE_ROOT` (reconcile; never wholesale Presets replace).
2. **Re-read** planning artifacts from `ACTIVE_CHANGE_ROOT`.

### 3. Execute tasks

**Prerequisite:** `ACTIVE_CHANGE_ROOT` bound. All artifact reads/writes use `ACTIVE_CHANGE_ROOT` only.

Work through `tasks.md` in order — numbered `##` groups, then Verification, Documentation, Changelog last.

Per implementation task:

1. Map related `#### Scenario:` blocks; name tests after scenarios.
2. Invoke **tdd** when present (non-blocking if absent).
3. Implement; mark `- [ ]` → `- [x]` only when tests pass.
4. **Reconcile the delta spec** whenever shipped behavior differs from the scenario that drove it — see [Delta spec reconciliation](#delta-spec-reconciliation) below.
5. Invoke **git-commit** for logical units on the active work ref (`ORIGINAL_BRANCH`, `APPLY_REF`, or `FEATURE_BRANCH` per venue matrix). Commit this unit's in-scope paths; **changelog-generator** runs in the Changelog group.
6. After each `##` group (or end when `single`), invoke **code-review** when present — fixed point = `ORIGINAL_BRANCH`.

**Parallelism `subagent-per-group`:**

- **`local`:** subagents read `ACTIVE_CHANGE_ROOT`; no git; orchestrator commits on `ORIGINAL_BRANCH`.
- **`worktree`:** optional group worktrees on `apply-<name>-<slug>`; orchestrator merges into `APPLY_REF`; merge gate (step 4) squash-merges to `ORIGINAL_BRANCH` before verify.
- **`remote`:** subagents on runner checkout; orchestrator commits on `FEATURE_BRANCH`.

Documentation group: update files from proposal Impact and tasks. Changelog group: invoke **changelog-generator** with `ACTIVE_CHANGE_ROOT` as the change root.

#### Delta spec reconciliation

Delta specs under `ACTIVE_CHANGE_ROOT/specs/**` describe the behavior this change ships. When a design fork is re-resolved mid-apply, apply edits them in place — this is not spec sync, which stays archive-only.

| Divergence | Edit |
|---|---|
| Scenario body no longer matches shipped behavior | Rewrite the steps **and** rename the title to the behavior that shipped |
| New design supersedes an existing scenario | Delete the superseded scenario — never leave it beside its replacement |
| Two scenarios assert the same behavior | Keep one |
| Requirement wording contradicts its own scenarios | Rewrite the requirement |
| Promoted term no longer describes shipped behavior | Rename or remove the `specs/ubiquitous-language/spec.md` delta entry |

Superseded titles over rewritten bodies are the common failure — a title naming behavior the `THEN` clauses now forbid. Fix it when the divergence happens; deferring it to archive, to a later phase, or to the user fails the verify gate in step 5.

### 4. Merge gate (worktree only — blocking)

When `venue` is **`worktree`**, squash to **`ORIGINAL_BRANCH`** before step 5. Do not run verify on the worktree checkout.

1. Checkout main repo → **`ORIGINAL_BRANCH`**
2. Squash merge **`APPLY_REF`** → **`ORIGINAL_BRANCH`** (one commit preferred)
3. `git branch --show-current` equals **`ORIGINAL_BRANCH`**
4. `git status --porcelain` empty on main repo

**Done when:** implementation commits live on **`ORIGINAL_BRANCH`** and the session is on main repo — not the worktree path.

### 5. Verify (blocking last gate)

Run on the **verification ref** at `ACTIVE_CHANGE_ROOT`. Repeat until `/opsx:verify` reports empty **CRITICAL**, **WARNING**, and **SUGGESTION** tiers:

1. **PRECHECK** (fix before hunting if any row fails):
   - All `tasks.md` checkboxes `[x]` (including Documentation and Changelog)
   - Canonical test command from `tasks.md` — exit 0; every `#### Scenario:` has a passing named automated test
   - Lint/format when `tasks.md` or repo docs name commands — zero new warnings from this change
   - **Adapter validator** — OpenSpec: `openspec validate --all --json` from `PLANNING_HOME` with `--store` when set; Direct: skip unless user requests
   - Material `design.md` decisions reflected in specs — material drift = FAIL
   - **Delta specs self-consistent** — every `#### Scenario:` title describes its own GIVEN/WHEN/THEN; no superseded titles, no duplicate scenarios, no requirement contradicting its scenarios (see [Delta spec reconciliation](#delta-spec-reconciliation))
   - Ubiquitous-language delta entries name behavior this change actually ships
   - Documentation tasks reflect actual behavior
   - Changelog task complete
   - `git status --porcelain` empty on the **verification ref**
2. Run `/opsx:verify` on the verification ref.
3. On any CRITICAL, WARNING, or SUGGESTION: fix immediately; return to (1). A finding whose recommendation names a later phase ("before archive", "at archive", "the user should") is still apply's to fix when the fix lives in the working tree or under `ACTIVE_CHANGE_ROOT` — restating it is not fixing it.
4. **Confirmation scorecard** — run `/opsx:verify` again scorecard-only (no new hunting). All three tiers must stay empty.

**Done when:** a standalone `/opsx:verify` after this step has no CRITICAL, WARNING, or SUGGESTION issues. Interruption re-runs route failures back here.

### 6. Handoff

**Done when:** verify tiers empty and the venue handoff row below completes.

| Venue | Parallelism | Handoff |
|---|---|---|
| **`local`** | `single` | Report gate PASS. Main on **`ORIGINAL_BRANCH`**. Return control — no squash. PR only when user asks. Update **Issue** when linked. |
| **`local`** | `subagent-per-group` | Squash merge integrated commits onto **`ORIGINAL_BRANCH`**. Delete ephemeral group refs. Return control. |
| **`worktree`** | either | Merge gate (step 4) already squash-merged **`APPLY_REF`** → **`ORIGINAL_BRANCH`**. `git worktree remove`; `git branch -D APPLY_REF`. Return control on **`ORIGINAL_BRANCH`**. |
| **`remote`** | either | Push **`FEATURE_BRANCH`**. `gh pr create --base ORIGINAL_BRANCH --head FEATURE_BRANCH`. Set `TRACKING` → PR; write `tracking.md`; commit and push. Link PR on **Issue**. |

## Delegation

| Concern | Skill | Required |
|---|---|---|
| User gates | structured-choices | Venue gate (interactive) |
| Tests | tdd | Optional; gate requires green |
| Commits | git-commit | Preferred |
| Changelog | changelog-generator | Changelog group |
| Review | code-review | Optional |
| Verify | `/opsx:verify` | Blocking last gate before handoff |
| PR / issue | gh + issue-tracker doc | Remote handoff |
| Cloud dispatch | SDK / Task `environment: cloud` | Remote when available |

## Invariants

Venue-specific handoff and bind semantics live in the **Venue matrix** above. These apply on every apply run:

- Archive and spec sync run only via `/opsx:archive` — never inside apply. Editing this change's own delta specs is apply's job, not spec sync.
- Delta specs under `ACTIVE_CHANGE_ROOT` must match shipped behavior before verify passes — no superseded titles, no duplicate scenarios.
- Mark tasks `[x]` only after tests pass.
- Run verify to empty CRITICAL/WARNING/SUGGESTION tiers before handoff; remote PR creation waits on verify PASS.
- On **worktree**, complete merge gate (step 4) on `ORIGINAL_BRANCH` before verify.
- OpenSpec apply requires verify PASS — `openspec validate` alone is insufficient.
- Fix verify issues in-session — do not defer to the user or to a later phase.
- **Local** and **worktree** integrate on `ORIGINAL_BRANCH` (+ ephemeral `apply-<name>`); `FEATURE_BRANCH` exists only for **remote**.
- Interactive hosts run the venue gate via structured-choices even when Issue or Presets are prefilled.
- Changelog group runs; paths resolve via adapter `CHANGE_ROOT_REL`, not hardcoded `openspec/changes/<name>/`.
- Subagents run sequentially — never concurrent on shared git state.
- Adapters do not create on-disk `tracking.md`; bind requires Presets → `venue` and `parallelism`.
- Tracking merge is field-by-field; **Change** always equals current adapter `CHANGE_ROOT_REL`.
- Post-bind artifact I/O uses `ACTIVE_CHANGE_ROOT` only.
- Remote PRs use `--base ORIGINAL_BRANCH`.
