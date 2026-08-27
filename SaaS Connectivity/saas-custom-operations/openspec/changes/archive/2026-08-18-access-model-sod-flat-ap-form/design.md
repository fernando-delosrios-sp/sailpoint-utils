## Context

`custom:access-model-sod-remediation` pre-renders group column HTML at form launch via `renderEntitlementTree` in `src/lib/sod-form-html/entitlement-tree.ts`. Nested access profiles currently render as a parent line with a child `<ul>` of offending entitlements. Policy owners will soon remediate role violations by detaching whole access profiles (`custom:access-model-sod-correct`, separate change); the form must show APs as single removable rows first.

## Goals / Non-Goals

**Goals:**
- Render each nested access profile on a policy side as one flat list row with an inline offending-entitlement mention
- Keep direct role entitlement rows unchanged
- Preserve plain / asKept / asRemoved outcome panel behavior at the row level
- Update specs, tests, README, and CHANGELOG

**Non-Goals:**
- `custom:access-model-sod-correct` or any Roles/Access Profiles PATCH APIs
- Changes to `groupAIds` / `groupBIds` formInput contract
- Form seed JSON or new `formName` watermark
- `custom:sod-remediation` flat access-path rendering

## Decisions

### D1: Change location

- **Choice:** Update `renderTreeBody` in `entitlement-tree.ts` only; `group-html.ts` unchanged
- **Reason:** Single renderer owns access-model column body markup
- **Considered alternatives:** Operation-local renderer — rejected (duplicates sod-form-html shared lib)

### D2: Flat AP line format

- **Choice:** `<li><strong>{apName}</strong> {access profile tag} — offending: {comma-separated entitlement names} {entitlement tag}</li>`
- **Reason:** AP is visually one unit; offending names explain why the AP appears on that side
- **Considered alternatives:** Nested tree (status quo) — rejected; AP-only line without offending mention — rejected (loses which entitlement triggered the side)

### D3: Multiple offending entitlements on one AP / one side

- **Choice:** Comma-separated strong names in one offending mention, single entitlement type tag at end
- **Reason:** One AP row maps to one detach action in the follow-on correct operation
- **Considered alternatives:** Separate AP line per entitlement — rejected (same AP would duplicate)

### D4: formInput field names and seed

- **Choice:** No seed or formName change; HTML built at instance create from updated builder
- **Reason:** Launch-time pre-render only; existing ASSIGNED instances retain prior HTML until recreated
- **Considered alternatives:** New formName watermark — rejected (unnecessary for builder-only change)

## Risks / Trade-offs

- [Risk] Owners with in-flight ASSIGNED forms still see nested tree → Mitigation: README note; recreate forms via rescan
- [Trade-off] Spec references legacy `groupAContentsHtml` field names while code uses `groupColumnsHtml*` → Accepted: out of scope for this HTML-shape change

## Migration Plan

1. Deploy connector with updated `renderEntitlementTree`
2. New scan launches pick up flat AP lines automatically
3. No workflow JSONPath changes required
4. Rollback: revert `entitlement-tree.ts` and spec deltas

## Open Questions

None.
