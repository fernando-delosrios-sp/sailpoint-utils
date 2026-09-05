## Scope

In: every file a Connect run persists — Connect log, Temporary script copy, and Secret sink — lives under one `entro-connect` folder on the current working path. Out: moving Skill catalog trees, changing Connect log contents or secret-handling rules, and migrating leftover root `entro-*.md` files.

## Language

**Connect run folder** (`promote`):
The directory `entro-connect` under the current working directory that holds every file a Connect run writes. It is not a Skill catalog tree.
_Avoid_: skill folder, temp dir, session directory, workspace root dump

**Connect log** (`conflicts-with-canonical`):
The gitignored markdown file a Connect run writes for one Lock. Canonical requirement still names it; the Term entry that placed it at repository root `entro-*.md` is missing from today's glossary and the automation spec still says repo root.
_Avoid_: session file, run dump

**Secret sink** (`conflicts-with-canonical`):
The disposable file that an agent-run secret-producing command writes instead of the terminal. Canonical definition places it outside the repository; this change places it in the Connect run folder, still never in agent context, chat, or the Connect log.
_Avoid_: vault, Temporary script copy

**Temporary script copy** (`conflicts-with-canonical`):
A disposable copy of a pinned Skill-held onboarding artifact used to bind names or skip a menu for one run. Canonical notes omit a home; skill prose says outside both skill trees. This change homes it in the Connect run folder.
_Avoid_: Local onboarding fork, skill-path edit

## Decisions

**Context.** Connect logs land at repository root (`entro-*.md`, gitignored). Temporary script copies go "outside both skill trees." Secret sinks go "outside the repository and both skill trees" (operator temp directory). Three homes for one run.

**Q1 — Where is the folder?** Child of the current working directory, named `entro-connect`. Assumed: operators run Connect from the workspace. The two Skill catalog trees stay at `.agents/skills/entro-connect` and `skills/entro-connect`.

**Q2 — Do Secret sinks move into that folder too?** Yes. The operator asked for temp files as well. Gitignore `/entro-connect/` at repository root so a Secret sink is never commit-eligible. The sink still must not enter agent context, chat, or the Connect log; its path is still disclosed in chat only and deleted after vault confirmation.

**Q3 — Root gitignore pattern?** `/entro-connect/` (leading slash) so `skills/entro-connect` stays tracked. Keep `entro-*.md` for leftover root logs; do not migrate them.

**Q4 — Collision with a Skill catalog tree?** If resolving `entro-connect` under the current directory would write into either Skill catalog tree, use repository-root `/entro-connect/` instead. Never write run files over catalog bytes.

**Direction.** One Connect run folder. Same Connect log file names inside it. Same secret rules except the sink's parent directory.

## Open questions

None blocking. Layout of files inside the folder (flat vs `tmp/`) is a design detail; impact is skill docs and gitignore only.

## Scenarios discussed

- After Lock, Connect creates `entro-okta.md` under the Connect run folder, not at repository root.
- Re-run of the same Lock appends that file in the Connect run folder.
- Automated secret-producing script writes a Secret sink under the Connect run folder; Connect log records identifiers only and omits the sink path.
- Temporary script copy is created under the Connect run folder, disclosed, run, discarded; `script.skillPath` is never overwritten.
- `.gitignore` `/entro-connect/` does not ignore `skills/entro-connect`.
- Current directory is `.agents/skills`: run files go to repository-root `/entro-connect/`, not into the Skill catalog tree.
- Leftover repository-root `entro-*.md` is left in place; new runs do not append it.
