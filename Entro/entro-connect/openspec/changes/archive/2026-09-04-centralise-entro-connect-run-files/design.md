## Context

entro-connect persists a Connect log, Temporary script copies, and Secret sinks. Today those files use three homes. Skill catalog trees at `.agents/skills/entro-connect` and `skills/entro-connect` stay generated catalog, not run output. This design homes every run-persisted file in one Connect run folder without weakening the secret boundary.

## Goals / Non-Goals

**Goals:**

- One directory named `entro-connect` holds every file a Connect run writes.
- Skill catalog trees stay untouched as write targets.
- Secret sink contents still never enter agent context, chat, or the Connect log; the sink path is still omitted from the Connect log.
- Repository gitignore excludes the Connect run folder at repo root only.

**Non-Goals:**

- Relocating Skill catalog trees.
- Changing Connect log sections or Operation mode behaviour.
- Auto-migrating leftover root `entro-*.md` files.
- A secrets-in-agent architecture.

## Decisions

### D1: Folder is `entro-connect` under the current working directory

- **Choice**: Resolve the Connect run folder as `<cwd>/entro-connect`. Create it on first persist after Lock.
- **Reason**: The operator asked for the current-path folder `entro-connect`. Connect already assumes a workspace cwd.
- **Considered alternatives**: Always repository root regardless of cwd — rejected as against the request. Write into the skill folder — rejected; that tree is generated catalog.

### D2: Skill-tree collision falls back to repository root

- **Choice**: If `<cwd>/entro-connect` would be either Skill catalog tree (cwd is `skills/` or `.agents/skills/`, or cwd already is a skill tree), write to `<repo-root>/entro-connect` instead.
- **Reason**: Run files must never overlay catalog bytes.
- **Considered alternatives**: Refuse the run — harsher than needed. A differently named folder — rejected; the operator named `entro-connect`.

### D3: Gitignore `/entro-connect/` and keep `entro-*.md`

- **Choice**: Add `/entro-connect/` (leading slash). Keep `entro-*.md` for leftover root logs. Do not migrate those files; new runs neither create nor append at repository root.
- **Reason**: `entro-connect/` without a leading slash would ignore `skills/entro-connect`.
- **Considered alternatives**: Ignore only `entro-connect/*.md` — would leave Secret sinks and Temporary script copies commit-eligible.

### D4: Flat layout, same Connect log names, prefixed temps

- **Choice**: Connect logs keep `entro-<tile-slug>[-<path-slug>].md`. Temporary script copies use a `tmp-` prefix plus a unique suffix. Secret sinks use a `sink-` prefix plus a unique suffix. No subdirectories.
- **Reason**: One folder is the request; prefixes stop temps colliding with Connect logs.
- **Considered alternatives**: `logs/` and `tmp/` subfolders — extra navigation for no safety gain once gitignore covers the parent.

### D5: Secret sink moves in; rules otherwise unchanged

- **Choice**: The Secret sink is a file in the Connect run folder. Chat still names the path so the operator can vault. Connect log still omits that path. Delete after vault confirmation. Never read the whole file back into agent context.
- **Reason**: Temp files were in scope. Gitignore keeps the sink off git. "Outside the repository" is replaced by "in the Connect run folder, never committed, never in agent context."
- **Considered alternatives**: Leave Secret sinks in the OS temp directory — rejected; the operator included temps.

## Risks / Trade-offs

- [Risk] Cwd is a Skill catalog parent → Mitigation: D2 fallback to repository-root `/entro-connect/`.
- [Risk] `/entro-connect/` gitignore pattern forgotten or written without the leading slash → Mitigation: test asserts `/entro-connect/` is present and `skills/entro-connect` is still tracked.
- [Risk] Operator commits despite gitignore → Mitigation: same as today's `entro-*.md`; skill still forbids writing secrets into the Connect log.
- [Trade-off] Secret sinks sit in a workspace-visible folder rather than OS temp → Reason for acceptance: findability; gitignore and existing read-back rules keep values out of git, chat, and the Connect log.

## Migration Plan

N/A as a deployment. Apply updates skill procedure files in both trees, `.gitignore`, README, tests, and changelog. Existing repository-root `entro-*.md` files stay; the next Connect run for that Lock creates or appends `entro-connect/entro-<slug>.md` instead. Rollback is reverting those docs and the gitignore line.

## Open Questions

None. In-folder layout (flat vs `tmp/`) is settled in D4.
