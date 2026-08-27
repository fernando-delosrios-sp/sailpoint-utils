## Scope

Align the upper context panels of `custom:sod-remediation` and `custom:access-model-sod-remediation` so ISC end users see a consistent “what we found / what we need from you” experience, with shared emoji signposting in the top panel, ISC admin deep links on referenced entities, and user-facing wording. In scope: shared context-panel and ISC UI link builders under `src/lib/sod-form-html/`, updated `situationSummaryHtml` assembly for both operations, seed layout changes (remove sod-remediation duplicate ctx block; add access-model programmatic summary), and link integration in access-path and entitlement-tree line renderers when `uiOrigin` is available. Out of scope: workflow JSON updates, persist output key changes, Mitigate-section restyling beyond wording, preventive-sod-check forms, revocability emojis on access-model group columns, and compensating-control admin links.

## Language

**Context panel** (`promote`):
The upper form section that explains the SoD conflict and the action required from the recipient, structured as “What we found” and “What we need from you”.
_Avoid_: detection panel, ctx-section (in user-facing copy)

**ISC UI link** (`promote`):
An HTML anchor to an ISC admin UI route for a referenced identity, policy, role, access profile, entitlement, or violations list, built from the invoke `apiUrl` hostname — never a hardcoded domain.
_Avoid_: deep link (generic), external link

**UI origin** (`promote`):
The tenant UI base URL (`protocol//host`) derived from loopback `apiUrl` by removing the `.api.` subdomain segment when present.
_Avoid_: tenant URL, console URL

**Emoji legend** (`draft`):
Footer block decoding icon suffix meanings; remains in identity-form context panel when path lists use revocability icons. Access-model context panel MAY use header emojis (⚠️, ℹ️) but SHALL NOT add a revocability legend to catalog column HTML.
_Avoid_: per-column legend

**Icon suffix** (`draft`):
Space-separated UTF-8 emoji markers on sod-remediation access-path lines; unchanged from unify-sod-form-html.
_Avoid_: inline text labels on every line

## Decisions

**Context** — Exploration session (2026-08-18): group columns are already unified via sod-form-html; upper panels diverge in structure, emoji use, wording, and lack admin links.

**Q1 — Shared upper-panel structure?**
→ Both forms use the same two-block pattern: “What we found” (subject, policy, conflict detail) and “What we need from you” (operation-specific call to action). Section titles SHALL NOT use internal phrases like “policy violation detection”.

**Q2 — sod-remediation deduplication?**
→ Remove the static `ctx-identity` DESCRIPTION; single `ctx-summary` interpolates full `situationSummaryHtml`.

**Q3 — access-model context panel?**
→ Add programmatic `situationSummaryHtml` formInput (parity with sod-remediation) instead of static seed-only metadata in `ctx-item`.

**Q4 — Emoji scope?**
→ Upper panel: ⚠️ heading, ℹ️ notes, emoji legend when sod-remediation path lists appear in summary. Access-model context panel gets header/signpost emojis; group columns remain without revocability emojis or legend (unchanged from unify-sod-form-html).

**Q5 — ISC admin links?**
→ Link display names for identity, SoD policy, role, access profile, entitlement when id and `uiOrigin` are available. Domain derived from `apiUrl`; never hardcode `identitynow.com`. Offline invoke (`apiUrl` absent): plain escaped text, no links.

**Q6 — Violation presentation?**
→ Violation id as plain text; separate “View SOD violations” link to `/ui/sod/violations` (list page — no per-violation deep link).

**Q7 — Link HTML in form vs persist?**
→ In-form `situationSummaryHtml` and column HTML use quoted `href` with `target="_blank" rel="noopener noreferrer"`. Persisted compact email bodies keep existing unquoted form link pattern and 256-char budget; no entity deep links in persist body.

**Q8 — URL path templates (user-provided)?**
→ Identity: `/ui/a/admin/identities/{id}/details/attributes`
→ SoD policy: `/ui/sod/policy-management/{id}/details`
→ Role: `/ui/a/admin/access/roles/landing-page/details/{id}`
→ Access profile: `/ui/a/admin/access/access-profiles/landing-page/details/{id}`
→ Entitlement: `/ui/a/admin/access/entitlements/landing-page/details/{id}`
→ Violations list: `/ui/sod/violations`

**Q9 — Form definition migration?**
→ Seed fingerprint changes are applied on the **same** `formName`: `ensureFormDefinitionByName` patches the existing definition when the watermark is stale. New instances get the updated layout; already-assigned instances keep launch-time HTML until recreated. A new `formName` is optional (parallel rollout only).

## Open questions

None — all forks resolved during exploration.

## Scenarios discussed

- Recipient opens identity form → context panel states conflict, links identity and policy, violation id plain + violations list link, path lines linked, legend at bottom, clear “choose Correct or Mitigate” ask.
- Recipient opens access-model form → context panel links access item and policy, explains catalog remediation ask, no revocability legend; column entitlement/AP names are linked when online.
- Offline invoke → no `uiOrigin`; all names render as plain escaped text; forms remain usable.
- sod-remediation Mitigate unavailable → ℹ️ note in context panel when no compensating controls.
- Malicious display names → link label escaped; URL path segments use encoded ids.
- Existing tenants → definition patched on next invoke with same `formName`; open form instances unchanged until recreated.
