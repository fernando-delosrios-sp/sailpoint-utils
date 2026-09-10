# Install structured-choices

Run when the user asks to **install** or **set up** structured-choices for this repo — including right after `npx skills add`. Do not gate; write agent config.

## 1. Explore

- `AGENTS.md` and `CLAUDE.md` at repo root — which exists? Is `## User gates` or `### User gates` already present?
- `## Agent skills` section — if present, prefer the subsection block (see [references/agents-block.md](./references/agents-block.md)).

## 2. Pick target file

- If `CLAUDE.md` exists, edit it.
- Else if `AGENTS.md` exists, edit it.
- If neither exists, create `AGENTS.md` unless the user names another file.

Never create `AGENTS.md` when `CLAUDE.md` already exists (or vice versa).

## 3. Choose block

From [references/agents-block.md](./references/agents-block.md):

- **`## Agent skills` present** → add or update **`### User gates`** (short block).
- **Otherwise** → add or update **`## User gates`** (full block).

Update in place when a User gates section already exists; do not append a duplicate.

## 4. Confirm and write

Show the section draft. After confirmation, write to the target file. Report which file was updated.

**Done when:** User gates section is present and matches the chosen block from agents-block.md.
