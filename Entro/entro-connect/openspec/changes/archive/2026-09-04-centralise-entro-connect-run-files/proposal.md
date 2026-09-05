## Why

A Connect run writes three kinds of files in three places: the Connect log at repository root, Temporary script copies outside both skill trees, and Secret sinks in the operator temp directory. Operators then hunt for evidence and temps. One folder on the current path, named `entro-connect`, makes every persisted file findable without mixing run output into a Skill catalog tree.

## What Changes

**Connect run folder**
- From: Connect logs at repo root (`entro-*.md`); Temporary script copies outside both skill trees; Secret sinks outside the repository.
- To: all three live in the Connect run folder `entro-connect` under the current working directory (repository-root `/entro-connect/` when that would hit a Skill catalog tree). Gitignore `/entro-connect/` so the folder is never committed. Connect log names stay `entro-<tile-slug>[-<path-slug>].md`.
- Reason: one home for every file the run persists, including temps.
- Impact: non-breaking for Entro itself; operators look in `entro-connect/` instead of the repo root. Secret values still never enter chat, agent context, or the Connect log.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `integration-automation`: Connect log and Secret sink live in the Connect run folder, not at repository root or the operator temp directory.
- `integration-prep`: Temporary script copies and secret-producing output live in the Connect run folder, never in a Skill catalog tree.
- `ubiquitous-language`: promote Connect run folder; restore Connect log on that path; retarget Secret sink and Temporary script copy notes.

## Non-goals

- Moving or renaming Skill catalog trees.
- Changing Connect log contents, Operation modes, or which steps use a Secret sink.
- Letting secret values into agent context, chat, or the Connect log.
- Migrating leftover repository-root `entro-*.md` files.
- Secrets held in the agent runtime.

## Impact

Both `entro-connect` skill trees (`SKILL.md`, `session-log.md`, `prep.md`), `.gitignore`, README, skill-doc tests, glossary Term entries, and the changelog. No catalog generator, Entro API, or ingested documentation change.
