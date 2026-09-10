# Update-skills report templates

## Change summary

For every skill processed during update or apply-only, record what changed and **why** — not just file lists.

### Sources

| Source | Lock / audit field | Use |
|--------|-------------------|-----|
| Last blend | `blended_ref` | Prior customized tree the maintainer shipped |
| Last upstream at blend | `applied_upstream_sha` | Upstream base used for the last blend |
| Current upstream | `sha` (after sync) | Fresh upstream canonical |
| Final tree | working tree after apply | New blend |
| Overlay intent | `overlays/<skill>/OVERLAY.yaml` | What local customization must preserve |

Use `git diff` between these refs on the skill dir (`skills/<category>/<skill>/`). Read audit flags (`upstream_changed`, `overlay_changed`, `route`) from manifest or `npm run overlay -- audit`.

### Per-skill delta classes

| Class | Meaning | Example phrasing |
|-------|---------|------------------|
| **Upstream** | New upstream content adopted as-is or integrated | "Upstream added HITL loop step; kept verbatim" |
| **Overlay** | Local intent applied on top of new upstream | "Overlay requires Spanish examples; added under Examples" |
| **Adaptation** | Intent preserved but target moved because upstream structure shifted | "Intent was 'require tests'; mapped to new Verification section" |
| **Generator** | Derived file created/updated from generator instructions | "Regenerated agents/openai.yaml from frontmatter" |
| **Unchanged** | Route `restore` or remerge with no material diff | "Inputs unchanged — restored from blended_ref" |

For route `fresh`, treat the delta as overlay + generator applied onto current upstream — no prior blend to diff.

For skills synced without overlay (no remerge), note upstream-only changes when `git diff` shows material edits under `skills/`.

### Per-skill capture (during apply)

Before moving to the next skill, draft:

- **Upstream delta** — what changed upstream since last blend (`applied_upstream_sha` → `sha`), in plain language
- **Overlay delta** — what overlay intent added, removed, or altered vs post-sync upstream
- **Adaptations** — any instruction that no longer mapped cleanly; how intent was satisfied instead
- **Files touched** — paths changed in the final blend vs `blended_ref` (or vs post-sync tree for `fresh`)

## Update report

```markdown
## update-skills

**Update:** npm run update completed
**Pending applied:** <count> skills (remerge/fresh)
**Restored (npm):** <count> skills
**Validated:** pass

### Skills processed
| Skill | Route | One-line |
|-------|-------|----------|
| <name> | remerge \| fresh \| restore \| none | <headline delta> |

### Change summary

#### <skill-name>

**Route:** <route> · **Upstream changed:** <bool> · **Overlay changed:** <bool>
**SHAs:** `<applied_upstream_sha>` → `<sha>` · **Prior blend:** `<blended_ref>`

**Upstream delta**
- <what upstream changed since last blend — behavior, sections, constraints>

**Overlay delta**
- <what local intent added or changed vs new upstream>

**Adaptations** _(omit section when none)_
- <intent → how it was mapped when structure shifted>

**Files touched**
- `<path>` — <upstream \| overlay \| generator \| adaptation>

_(Repeat per skill with remerge/fresh, or per skill with material upstream-only sync changes.)_

### Commit
<committed SHA | skipped — restore will fail next cycle without blend commit>
```

## Examples

**User:** "update skills"

1. `npm run update`
2. Apply all remerge/fresh manifests; capture change summary per skill
3. Validate
4. Report with semantic deltas
5. Commit gate

**User:** "apply pending overlays" (update already ran)

1. Audit — collect remerge/fresh skills
2. Apply each manifest; capture change summary per skill
3. Validate, report, commit gate

**User:** "update-skills apply domain-modeling" (single-skill scope)

1. Audit — route must be remerge/fresh
2. Read manifest + OVERLAY.yaml, merge semantic instructions, apply generators, capture change summary
3. Validate, report, commit gate

**User:** "extract overlay for domain-modeling"

1. Run extract-overlay, refine instructions, hand off to update path after review
