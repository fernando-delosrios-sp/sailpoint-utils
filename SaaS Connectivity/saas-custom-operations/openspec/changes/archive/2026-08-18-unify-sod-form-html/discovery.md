## Scope

Unify SoD remediation form HTML styling for `custom:sod-remediation` and `custom:access-sod-remediation` via a new `src/lib/sod-form-html/` content library. In scope: shared type tags and outcome panels, emoji-only line markers with legend (sod-remediation top panel only), selection-gated green/red panels, six group HTML formInput variants per form seed, and seed `formConditions` for SHOW/HIDE. Out of scope: ISC client/forms API changes, workflow JSON updates, persist output key changes, and Mitigate-section styling beyond existing behavior.

## Language

**SoD form HTML** (`promote`):
Shared HTML string builders for ISC form DESCRIPTION content used by both SoD remediation operations. Lives under `src/lib/sod-form-html/`, not `src/isc/`.
_Avoid_: form client, ISC HTML module

**Type tag** (`promote`):
Inline pill span denoting access object kind — role, access profile, or entitlement — on each list line.
_Avoid_: type prefix (`Role:`), type label in bold prefix

**Outcome panel** (`promote`):
Colored background wrapper around a group column list indicating keep (green) or remove (red) fate after the recipient selects a remediation side.
_Avoid_: side panel, neutral panel, blue/purple side identity panel

**Side HTML variant** (`promote`):
One of three pre-rendered HTML strings for a policy side at launch: `plain` (no panel), `asKept` (green outcome panel), `asRemoved` (red outcome panel).
_Avoid_: dynamic HTML, live re-render

**Icon suffix** (`draft`):
Space-separated UTF-8 emoji markers appended to a line without inline explanatory text (e.g. `🔐 ⭐ 🚫`).
_Avoid_: concatenated emojis (`⭐✅`), inline text labels on every line

**Emoji legend** (`draft`):
Footer block in sod-remediation `situationSummaryHtml` decoding icon suffix meanings once for the whole form.
_Avoid_: per-column legend, access-sod-remediation legend

## Decisions

**Context** — Exploration session (2026-08-17): two SoD form operations share remediation side selection but diverge in HTML styling (emojis vs colored panels vs type tags).

**Q1 — Where does shared code live?**
→ `src/lib/sod-form-html/`. Content assembly is not an ISC client concern.

**Q2 — Layout topology per operation?**
→ sod-remediation keeps flat horizontal access-path lines; access-sod-remediation keeps side-by-side COLUMN_SET with nested AP → entitlement tree.

**Q3 — When do colored panels appear?**
→ Only after `remediationSide` is selected. No selection → plain list, no panel wrapper. No pre-selection blue/purple side-identity panels.

**Q4 — How do green/red panels work?**
→ Pre-render three variants per side at launch; seed uses `formConditions` SHOW/HIDE to swap plain vs asKept vs asRemoved DESCRIPTION elements on `remediationSide` selection (live visual update, not submit-only).

**Q8 — ISC formConditions timing?**
→ Confirmed: outcome panel swap is visual content and updates on selection. No apply-phase spike or submit-only fallback required.

**Q5 — Emoji presentation?**
→ Icon-only suffixes on lines, space-separated (`⭐ ✅`). Legend footer only in sod-remediation `situationSummaryHtml` (top context panel). Column HTML and access-sod-remediation omit legend. access-sod-remediation omits emojis entirely.

**Q6 — Type tag format?**
→ Adopt access-sod-remediation pill pattern for both operations on every line (`role`, `access profile`, `entitlement`).

**Q7 — Granted-via context on non-revocable lines?**
→ Keep short `<em>(via …)</em>` phrase; not part of legend vocabulary.

## Open questions

- **situationSummaryHtml duplication** — Deferred: keep current duplicate A/B lists in summary for v1; columns use same renderers with legend appended only in summary.

## Scenarios discussed

- Recipient opens form before selecting side → plain lists in both columns, no green/red panels.
- Recipient selects Group A → Group A column shows red asRemoved panel; Group B shows green asKept panel.
- Recipient selects Group B → opposite coloring.
- sod-remediation line with privileged + keep + revocable → `🔐 ⭐ ✅` in order; legend at bottom of situation summary only.
- sod-remediation non-revocable entitlement via role → `🚫` plus `(via Role Name role)` em phrase.
- access-sod nested AP with matching entitlements → tree under AP label with type tags; no emojis.
- Existing tenants with old form definitions → seed fingerprint change triggers ensure-from-seed recreate on new definition name only (existing definitions not patched — unchanged ISC ensure behavior).
- Mitigate path selected (sod-remediation) → correct-section hidden; outcome panel conditions irrelevant.
