# Change adapters

Adapters resolve **where** the change lives and **which validators** run at the completion gate. Pre-flight outputs are inputs to apply skill **bind** — not the post-bind artifact surface.

## Selection (precedence)

When multiple adapters match, use the **highest-precedence signal**:

| Precedence | Adapter | When |
|---|---|---|
| 1 (highest) | **Direct** | User supplies an explicit directory path that contains `tasks.md` |
| 2 | **OpenSpec** | `/opsx:apply`, change **name** without explicit path, or `openspec status --change "<name>"` succeeds |

**Tie-break:** explicit folder path → **Direct**; `/opsx:apply` or registered name without path → **OpenSpec**.

## Shared outputs

Every adapter sets:

| Variable | Meaning |
|---|---|
| `CHANGE_ROOT` | Adapter `changeRoot` / user path — pre-flight planning reads only |
| `CHANGE_ROOT_REL` | Repo-relative path from `CHANGE_ROOT` — skill computes `ACTIVE_CHANGE_ROOT` at bind |
| `NAME` | Basename of the change — used in ephemeral `apply-<name>` |

Post-bind artifact I/O uses **`ACTIVE_CHANGE_ROOT`** from the apply skill **venue matrix** — never the pre-bind absolute `CHANGE_ROOT` when work runs on another checkout.

Optional under the change folder:

| Path | Purpose |
|---|---|
| `specs/**/*.md` | Scenario → test coverage gate |
| `design.md` | Design/spec coherence gate |
| `proposal.md` | Changelog scope |
| `tracking.md` | Loaded into `TRACKING_HINT` at pre-flight; merged pre-bind (on-disk + remote-branch when venue is `remote`) |

## OpenSpec adapter

Match `/opsx-apply`: paths from CLI, not repo guesses.

1. Resolve a source value from `/opsx:apply`, session context, or a **preloaded** `TRACKING_HINT` → Change. Set `NAME` to that value's canonical filesystem **basename** (strip trailing separators first); STOP if it is empty, `.` or `..`. `Change` is `CHANGE_ROOT_REL` (repo-relative); a legacy absolute `CHANGE_ROOT` is accepted when reading. Never a branch or worktree-name input.
2. Resolve `--store` from user input or command hints first, else a **preloaded** `TRACKING_HINT` Presets → `store`. Set `STORE_SOURCE` to `explicit` for user/command input, otherwise `hint`; a hint-derived store is a probe only, not a merge override. When no preloaded hint exists, leave `STORE` unset for the first probe.
3. Run `openspec status --change "<name>" --json` (append `--store` when set). Read `planningHome`, `changeRoot`, `artifactPaths`, `actionContext`.
4. Run `openspec instructions apply --change "<name>" --json` (append `--store`). Read `contextFiles`.
5. Set `CHANGE_ROOT = changeRoot`; compute `CHANGE_ROOT_REL` from repo root.
6. If `tracking.md` exists at `CHANGE_ROOT`, load it into non-authoritative **`TRACKING_HINT`**. When `STORE_SOURCE` is not `explicit` and its Presets → `store` is non-empty and differs from `STORE`, set `STORE_SOURCE = hint`, rerun steps 3–5 with that store, then reload `TRACKING_HINT` from the resulting `CHANGE_ROOT`. If the reloaded hint names a different store, **STOP** and require an explicit `--store`.
7. When invoked without prior `/opsx:apply` context, steps 3–6 are mandatory before other reads. A store that is only reachable through an as-yet-unresolved change tree cannot select itself; require `--store` or an OpenSpec declared/default store in that case.

**Also sets:** `PLANNING_HOME`, `STORE`, `STORE_SOURCE` (when a store is used).

**Default feature branch (remote venue only):** `TRACKING` → Branch at bind, else `openspec/<name>`.

**Gate validator:** `openspec validate --all --json` from `PLANNING_HOME` with `--store` when set (step 5 row 4).

**Verify-fix:** invoke **openspec-verify-change** or `/opsx:verify` on the verification ref until ✅ PASS (step 6). Structural validate alone is insufficient.

**Never:** hardcode `openspec/changes/<name>/`; create on-disk `tracking.md`.

## Direct adapter

1. Set `CHANGE_ROOT` to user path; confirm `tasks.md` exists.
2. Set `NAME` to the canonical filesystem **basename** of `CHANGE_ROOT` (strip trailing separators first); STOP if it is empty, `.` or `..`. Do not derive it from `TRACKING_HINT`, which may be from another checkout.
3. Compute `CHANGE_ROOT_REL`. Read standard layout from `CHANGE_ROOT`. Load `tracking.md` into **`TRACKING_HINT` only** when present.

**Does not set:** `PLANNING_HOME`, `STORE`, `artifactPaths`, `contextFiles`.

**Default feature branch (remote venue only):** `TRACKING` → Branch at bind, else `feature/<name>`.

**Gate validator:** skip OpenSpec validate unless user explicitly requests.

## superpowers-bridge contrast

| | ferspec + apply-code-changes | superpowers-bridge |
|---|---|---|
| Apply skill | **apply-code-changes** | Schema-embedded executor |
| Isolation | Venue matrix (`local` / `worktree` / `remote`) | User choice at apply step 1 |

Use **apply-code-changes** for ferspec and Direct apply. Do not mix apply paths on one change.
