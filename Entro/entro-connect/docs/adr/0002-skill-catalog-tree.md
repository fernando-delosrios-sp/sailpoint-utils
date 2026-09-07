# ADR-0002: Skill catalog tree (index, Tool install file, row folders)

## Status

Accepted

Supersedes the “single skill JSON file” layout in [ADR-0001](0001-entro-connect-catalog-and-skill.md). Keeps ADR-0001’s one-skill rule and the rule that Connect must not open `documentation/` pages.

## Context

The Skill catalog was one ~152KB JSON plus Skill-held files under `vendor/` keyed by GitBook slugs. Opening that file at Lock loaded every tile’s Prep steps. entro-connect is still one skill; catalog data is still generated. The disclosure boundary must match the procedure files: thin index until Lock, then one Add New Account target.

## Decision Drivers

- After Lock, context holds one target’s Row catalog, not the other tiles
- One skill; catalog remains generated data
- Ingest `documentation/integrations.json` stays one full-row file
- Skill-held artifacts live in the owning row folder; skill-side `vendor/` is retired

## Considered Options

### Option 1: Keep one JSON and instruct Grep/jq

- **Pros**: No layout change
- **Cons**: Agents still Read the fat file

### Option 2: Per-tile skills

- **Pros**: Hard disclosure boundary
- **Cons**: Breaks ADR-0001 one-skill rule

### Option 3: Move `vendor/` only

- **Pros**: Smaller path change
- **Cons**: Instructions stay in the fat JSON

### Option 4: Thin Skill catalog index plus row folders and a sibling Tool install file

- **Pros**: Lock cannot load other tiles or every CLI probe; Row catalog stays today’s full object
- **Cons**: Two on-disk shapes (ingest vs Skill catalog)

## Decision

`integration_catalog.py` writes `documentation/integrations.json` as one array of full rows (page paths allowed). In the same run it writes both `entro-connect` skill trees as:

- Skill catalog index at `integrations.json` (`tile`, `targetSelection`, `summary`, method names, Coverage names, `catalogPath`)
- Tool install file at `tool-install.json` (today’s `toolInstall` object)
- One row folder per Add New Account target: `integrations/<slug>/catalog.json` plus Skill-held artifacts beside it

Folder slugs come from Entro identity (`kebab(tile)` or `kebab(targetSelection)` when set). `skillPath` is skill-root-relative under the row folder. Orientation and Lock read only the index; Coverage names resolve the parent without opening a folder. After Lock the skill opens only that `catalogPath`. tools.md opens the Tool install file after Lock and reads only locked `binary`/`id` keys. Row folders must not contain `SKILL.md`.

## Consequences

### Positive

- A Connect run can Lock from a thin index
- AWS duplicate GitBook trees collapse into `integrations/aws/`
- Both skill trees stay generated copies

### Negative

- Ingest JSON and Skill catalog are different shapes
- Hand-edits of generated skill catalog files are overwritten
