## Scope

Restructure the Skill catalog so a Connect run loads a thin index until Lock, then one Add New Account target's full row JSON and artifacts; ingest `documentation/integrations.json` stays one file; no per-integration skills.

## Language

**Skill catalog** (`promote`):
The generated Connect-run data tree in both `entro-connect` skill folders: thin index, Tool install file, and one row folder per Add New Account target.
_Avoid_: documentation/integrations.json, per-tile skill, vendor/ as the catalog

**Skill catalog index** (`promote`):
The thin root `integrations.json` in a skill tree: tile, targetSelection, summary, Setup and Authentication method names, Coverage names, catalogPath. Not the full row object.
_Avoid_: fat skill integrations.json, ingest Integration index

**Row catalog** (`promote`):
The `catalog.json` in a row folder: today's complete Skill catalog row object (identity fields, fields, steps, tools, Coverages nested).
_Avoid_: method-sliced JSON, Coverage-as-folder

**catalogPath** (`promote`):
The skill-root-relative path on the Skill catalog index that names that target's `catalog.json`.
_Avoid_: derived-only slug with no field

**Tool install file** (`promote`):
The sibling JSON of `toolInstall` keyed by CLI binary or MCP id, not embedded in the Skill catalog index.
_Avoid_: copying toolInstall onto every row

**Row folder** (`draft` — describe layout, do not glossary unless specs need it):
`integrations/<kebab-tile>[-<kebab-targetSelection>]/` holding `catalog.json` and Skill-held artifacts at the same level.

Canonical **Skill-held onboarding artifact** (`conflicts-with-canonical`): notes say stored under `vendor/`. After this change they live in the row folder; path remains skill-root-relative. Specs phase MUST update that Notes line.

Canonical **Add New Account target** Notes say "one row in integrations.json". Ingest index stays that way; Skill catalog splits. Specs MUST disambiguate ingest JSON vs Skill catalog index vs Row catalog.

**Skill catalog** as a single JSON file was in change `entro-connect-skill` but is not in canonical ubiquitous-language today — promote the tree definition here.

## Decisions

Context → grill rounds (2026-09-02) → confirm.

- Architecture bar: after Lock, context holds one target's Row catalog, not the other tiles.
- Disclosure: thin index + folders; not one JSON with read-rules-only; not per-tile skills; not vendor-only move.
- Grain: one folder per Add New Account target. Coverages stay nested in the Row catalog.
- Index: tile, targetSelection, summary, method and Coverage names, catalogPath.
- Ingest: `documentation/integrations.json` stays one file; Skill catalog only splits.
- toolInstall: sibling file, opened after Lock (tools.md).
- After Lock: whole Row catalog (all methods and Coverages on that object).
- Pointer: explicit catalogPath.
- Open folder only after Lock (Orientation uses index `summary`).
- Folder layout: flat (`catalog.json` + artifacts).
- Retire skill-side `vendor/<gitbook-slug>/` including AWS duplicate trees.
- Payload: complete current row object in catalog.json; index is a projection.
- Root filename stays `integrations.json`.
- Folder slugs from Entro identity: kebab(tile) plus kebab(targetSelection) when set.
- skillPath stays skill-root-relative.
- Inner file name: `catalog.json`.
- One `entro-connect` skill; both generated skill trees stay copies; writer overwrites hand-edits.

## Open questions

None blocking. Assumed at propose: sibling file name `tool-install.json`; directory name `integrations/` under the skill folder; tools.md reads only the locked binaries' `toolInstall` entries from the sibling file; `skills/entro-connect` mirrors `.agents/skills/entro-connect`.

## Scenarios discussed

- Operator names a Coverage (Copilot Studio): Lock parent from index Coverage names; open Microsoft Ecosystem Row catalog only after Lock.
- GitHub Cloud - New vs Legacy vs Enterprise Server: three row folders.
- Orientation wrong-guess: must not open a Row catalog before Lock.
- Lock reading the index must not load `toolInstall` (sibling file).
- AWS CloudFormation vs Manual: both stay in one `catalog.json`.
- Shared or duplicate GitBook artifacts: collapse into the owning row folder; checksum pins follow new skillPath.
- Connect without `documentation/` pages still works from the Skill catalog tree.
