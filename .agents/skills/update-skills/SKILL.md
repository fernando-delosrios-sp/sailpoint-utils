---
name: update-skills
description: Update this skills repo from upstream and apply pending overlays.
disable-model-invocation: true
---

# Update Skills

Sync upstream skills, apply pending overlays, validate, and optionally commit.

Overlays encode **behavioral intent** on upstream-canonical skill trees. Never paste previous blended output when upstream or overlay inputs changed.

Overlay reference: [README.md#skill-overlays](../../../README.md#skill-overlays)

## Mode routing

| Trigger | Mode | Executor |
|---------|------|----------|
| Default — update skills / sync upstream | update | agent (this path) |
| User already ran update, or names apply without sync | apply-only | agent |
| User asks to draft/refine overlay from local diffs | extract | agent guides `npm run extract-overlay` |
| Remerge with stale or unmapped instructions | reconcile | agent |
| User asks what changed / routing state | audit | agent reads `npm run overlay -- audit` |
| Audit route = `restore` | restore | npm (`overlay restore`) — skill documents only |

**Pipeline order:** sync → static → audit → restore (unchanged) → prepare remerge manifests → apply/reconcile (agent)

---

## Default: update

Run the full maintainer pipeline unless the user scoped to apply-only (see below).

### 1. Update from upstream

Run `npm run update` — sync, static, audit, restore unchanged inputs, prepare remerge manifests.

**Done when:** command exits. Skills routed `restore` are already blended.

### 2. Classify pending overlays

Run or read `npm run overlay -- audit` and list `.tmp/overlay-apply/` manifests.

**Done when:** every customized skill is classified `restore` / `none` vs `remerge` / `fresh`.

### 3. Apply pending overlays

For each skill with route `remerge` or `fresh`:

1. Confirm routing — if route = `restore`, stop and direct user to `npm run overlay -- restore --skill <name>`
2. Load context: `overlays/<skill>/OVERLAY.yaml`, universal generators, post-static files in `skills/<category>/<skill>/`. **Ignore** previous blended content from git except as intent reference in OVERLAY.yaml
3. Apply semantic changes — read current file, satisfy instruction **intent**, document adaptations
4. Apply generators — skip pinned static paths unless instructions require regeneration
5. Capture **change summary** for this skill — see [references/report-templates.md](references/report-templates.md) §Change summary — done before moving to the next skill
6. Remove manifest: `npm run clean -- --skill <skill>` after blend recorded

Apply each skill in manifest order — semantic changes, then generators per skill. Use single-skill scope only when the user names one skill or passed `--skill <name>`.

**Done when:** every pending skill is blended.

### 4. Validate

Run `npm run validate`; fix and re-run until pass. Do not `recordBlend` until validation passes.

**Done when:** validate exits clean.

### 5. Commit gate

One structured-choices gate:

- **Commit** — two git-commits: blended trees, then `.locks/upstream.json` after `recordBlend`
- **Commit and push** — the same two commits, then one push of HEAD after the lock commit
- **Do nothing** — warn that restore will fail next cycle without a blend commit

When the user chose Commit or Commit and push, run this sequence:

1. Invoke **git-commit** for blended skill trees so `blended_ref` can be that commit
2. `recordBlend` for **each** blended skill with current `sha`, hashes, and shared `blended_ref` = HEAD (the tree commit)
3. Invoke **git-commit** again for `.locks/upstream.json` only — required so overlay locks land; missing `overlay_applied_at` makes `getOverlayRoute` treat the blend as `fresh`
4. **Commit and push only:** push after step 3 so the remote includes the lock commit
5. Clean remaining manifests: `npm run clean -- --manifests`

Set in `.locks/upstream.json` via `recordBlend` fields:
- `applied_upstream_sha` = current `sha`
- `overlay_hash` = per-skill overlay fingerprint (when overlay exists)
- `universal_overlay_hash` = universal overlay fingerprint (when generators exist)
- `overlay_applied_at` = now
- `blended_ref` = HEAD after the tree commit

**Done when:** user chose an option and any commit/push requested is complete.

### 6. Report

Present the [update report](references/report-templates.md#update-report) to the user — routing table plus per-skill change summaries and semantic deltas. Do not skip remerge/fresh skills with empty deltas when `upstream_changed` is true.

**Done when:** user has a readable summary of what changed and why.

---

## Apply-only

When the user already ran `npm run update`, references `.tmp/overlay-apply/<skill>.md`, or asks to apply pending overlays without syncing — skip step 1; run steps 2–6 of the default path.

---

## Shared rules

1. **Never literal-restore on changed inputs.** If `upstream_changed` or `overlay_changed`, do not copy prior blended files from git history, manifests, or extract drafts.
2. **Upstream post-sync + static is the merge base** for apply/reconcile.
3. **Overlay instructions = intent**, not exact final text.

## Preconditions

Verify before apply/reconcile. Stop with remediation — do not partially apply.

| Check | Remediation |
|-------|-------------|
| Audit route = `restore` | Stop — run `npm run overlay -- restore --skill <name>` |
| Per-skill overlay expected but missing | Create overlay or use `prepare-generators` for generators-only |
| `skills/<category>/<skill>/SKILL.md` missing | Run `npm run sync` |
| Static `add` target missing | Run `npm run overlay -- static --skill <name>` |
| Manifest missing for remerge skill | Run `npm run overlay -- prepare --skill <name>` |

## Inputs

| Input | Resolution |
|-------|------------|
| Skill name | Category from `skills/<category>/skills.json`; overlay in `overlays/<name>/` when present |
| Audit | `npm run overlay -- audit [--skill <name>]` |
| Manifest | `.tmp/overlay-apply/<skill>.md` from prepare |
| Lock | `.locks/upstream.json`: `sha`, `applied_upstream_sha`, `overlay_hash`, `universal_overlay_hash`, `blended_ref`, `overlay_applied_at` |

---

## Mode: audit

Explain overlay routing for one or all skills.

1. Run `npm run overlay -- audit [--skill <name>]`
2. Summarize per skill: route, upstream_changed, overlay_changed, reason, blended_ref
3. Recommend next step: `restore` (npm), apply via update-skills, or no action

**Done when:** user understands routing and next command.

---

## Mode: restore

npm executes restore; the skill documents outcomes.

When `npm run overlay -- restore` runs successfully:
- Blended tree checked out from `blended_ref`
- Lock updated via `recordBlend` (applied_upstream_sha, hashes, overlay_applied_at, blended_ref)

Tell the user restore means **inputs were identical** — no agent merge was needed.

---

## Mode: extract

Draft or refine `OVERLAY.yaml` from local customizations.

1. Run `npm run extract-overlay -- --skill <name>` (add `--force` to overwrite draft)
2. Refine drafted `instructions`:
   - Remove literal file content blobs
   - Express behavioral intent only
   - Move local-only files to static `add` ops
3. Do **not** apply — hand off to default update path after user review

Optional: `npm run extract-overlay -- --from-commit HEAD` for batch inference.

---

## Mode: reconcile

When remerge reveals overlay instructions no longer map to upstream:

1. Best-effort apply per instruction intent
2. Document adaptations in the per-skill change summary (Adaptations section)
3. Propose `OVERLAY.yaml` edits aligning instructions with new upstream structure
4. Ask user to approve overlay updates before `recordBlend`

Use when user explicitly asks to reconcile, or apply surfaces structural conflicts.

Merge principles, error handling, and invocation examples: [references/report-templates.md](references/report-templates.md).
