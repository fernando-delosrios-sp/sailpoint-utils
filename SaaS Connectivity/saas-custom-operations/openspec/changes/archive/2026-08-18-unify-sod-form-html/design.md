## Context

Both SoD remediation operations launch ISC standalone forms with Group A / Group B columns and a `remediationSide` select. HTML for DESCRIPTION elements is assembled at instance create time and injected via `formInput` STRING fields. ISC renders interpolated HTML and supports `formConditions` SHOW effects (already used in sod-remediation for Correct vs Mitigate). Styling logic is split across `sod-remediation/revocability-labels.ts` and `access-sod-remediation/group-html.ts` with no shared tokens.

Exploration (2026-08-17) locked scope: unify visual vocabulary without merging layout topologies or moving code into `src/isc/`.

## Goals / Non-Goals

**Goals:**
- Extract shared HTML builders to `src/lib/sod-form-html/`
- Unified type tags on all access lines in both forms
- Selection-gated green (keep) / red (remove) outcome panels via pre-rendered variants + seed `formConditions`
- sod-remediation: icon-only emoji suffixes (space-separated), legend footer in `situationSummaryHtml` only, flat horizontal lists preserved
- access-sod-remediation: nested AP tree and side-by-side columns preserved; no emojis or legend
- Unit tests covering renderers and variant assembly

**Non-Goals:**
- Changes to `src/isc/forms/` client helpers
- Persist output key or workflow contract changes
- Patching existing tenant form definitions (ensure-by-name unchanged)
- Live JavaScript or client-side re-render
- Mitigate-section visual redesign
- Trimming duplicate A/B lists from `situationSummaryHtml` in v1

## Decisions

### D1: Library location — `src/lib/sod-form-html/`
- **Choice:** New top-level lib folder, imported by both operations.
- **Reason:** HTML content assembly is operation/domain presentation, not ISC API integration.
- **Considered alternatives:** `src/isc/forms/sod-form-html` — rejected (client layer); operation-local duplicate helpers — rejected (drift).

### D2: Outcome panels gated on selection only
- **Choice:** Plain `<ul>` lists with type tags when `remediationSide` is unset; green/red panel wrappers only in `asKept` / `asRemoved` variants shown after selection.
- **Reason:** User requirement — no panel without a choice; avoids misleading pre-selection coloring.
- **Considered alternatives:** Always-on blue/purple side panels — rejected; always-on outcome preview — rejected.

### D3: Three pre-rendered variants per side
- **Choice:** Launch-time formInput carries six STRING keys: `groupAContentsHtml`, `groupAContentsHtmlAsKept`, `groupAContentsHtmlAsRemoved`, and B equivalents. Seed defines three DESCRIPTION elements per column with complementary `formConditions`.
- **Reason:** ISC cannot mutate HTML on select; SHOW/HIDE swap is the established pattern.
- **Considered alternatives:** Single HTML field with CSS classes toggled by JS — not available in ISC forms.

### D4: Emoji presentation — icon suffix + legend once
- **Choice:** Lines use space-separated icons only (`🔐 ⭐ ✅`); `renderEmojiLegend()` appended once to sod-remediation `situationSummaryHtml`. Column variants and access-sod HTML omit legend. Icon order: privileged → keep → revocability.
- **Reason:** Reduces line noise; legend scoped to top panel where recipient reads context first.
- **Considered alternatives:** Inline text labels (current) — rejected; legend in every column — rejected.

### D5: Layout topology stays operation-specific
- **Choice:** Lib exposes `renderFlatAccessPathList` (sod-remediation) and `renderEntitlementTree` (access-sod-remediation); shared wrappers for tags, panels, escape, icon suffix.
- **Reason:** Identity violations show roles/APs/entitlements flat; catalog violations show nested AP containment.
- **Considered alternatives:** Force nested tree everywhere — rejected.

### D6: access-sod-remediation — tags and panels only
- **Choice:** No emojis or legend on access catalog forms.
- **Reason:** No revocability/keep/privileged semantics at catalog scan time.
- **Considered alternatives:** Empty legend placeholder — rejected.

### D7: Form seed migration
- **Choice:** Update bundled seeds; fingerprint changes apply only when tenants create a new form definition name. Document that existing `{formName}` definitions retain old layout until replaced.
- **Reason:** Matches existing ensure-by-name no-patch behavior.
- **Considered alternatives:** Force patch existing definitions — out of scope / not supported.

### D8: Granted-via phrase retained
- **Choice:** Non-revocable lines keep `<em>(via …)</em>` after icon suffix; not in legend.
- **Reason:** Structural context, not icon vocabulary.

### D9: formConditions update on selection
- **Choice:** Wire `formConditions` to `remediationSide` with SHOW effects; ISC swaps plain vs outcome DESCRIPTION elements as soon as the recipient selects a side.
- **Reason:** Outcome panels are visual preview content; ISC form conditions apply on field change, not only at submit.
- **Considered alternatives:** Submit-only swap with helper copy — rejected; no dev-tenant spike required.

## Risks / Trade-offs

- [Risk] Six STRING formInput fields increase payload size → Mitigation: HTML is list markup only; acceptable vs ISC limits
- [Trade-off] Duplicate A/B content in sod-remediation situation summary and columns → Accepted for v1 readability
- [Trade-off] Existing form definitions unchanged until new name → Accepted; document in README

## Migration Plan

1. Ship connector with updated seeds and lib.
2. Tenants creating forms under a **new** `formName` get unified HTML automatically.
3. Tenants reusing an existing definition name keep old layout until they adopt a new form name (or manual ISC admin recreate).
4. No workflow JSONPath changes required.
5. Rollback: revert connector bundle; new instances only affected.

## Open Questions

None.
