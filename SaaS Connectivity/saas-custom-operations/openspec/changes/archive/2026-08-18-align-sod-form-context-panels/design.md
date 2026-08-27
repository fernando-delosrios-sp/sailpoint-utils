## Context

Both SoD remediation operations already share group-column HTML via `src/lib/sod-form-html/`. Upper panels diverge: sod-remediation builds rich `situationSummaryHtml` programmatically but duplicates metadata in the seed; access-model relies on static seed interpolation with no situation narrative or admin links. Handlers always have loopback `apiUrl` when online; ISC admin UI lives on the same hostname without the `.api.` segment.

Stakeholders: ISC form recipients (identity owners, policy owners) and workflow operators who configure `formName`.

## Goals / Non-Goals

**Goals**
- Unified “What we found / What we need from you” context panel on both forms
- ISC admin deep links on entity display names when `apiUrl` is present
- Consistent user-facing wording and ⚠️ signposting in upper panels
- Offline-safe degradation (plain text, no broken links)
- Preserve compact persisted email bodies and access-model column emoji rules

**Non-Goals**
- Workflow JSON or persist output key changes
- Revocability emojis on access-model group columns
- Per-violation admin deep link (list page only)
- Compensating-control admin links
- Requiring a new `formName` for seed updates (watermark patch on same name is sufficient)

## Decisions

### D1 — UI origin from apiUrl

Derive UI base URL by parsing `apiUrl` and replacing `.api.` in the hostname with `.` (e.g. `https://tenant.api.identitynow.com` → `https://tenant.identitynow.com`). If hostname has no `.api.` segment, use as-is. Pass `uiOrigin` into HTML builders at launch; omit when offline.

### D2 — Link module location

Add `src/lib/sod-form-html/isc-ui-links.ts` with:
- `resolveUiOrigin(apiUrl: string): string`
- `renderIscUiLink(uiOrigin, kind, label, id?): string` — returns escaped plain label when offline or id missing (except `violationList` kind)
- Path templates per discovery Q8

Link attributes in form HTML: `href="..." target="_blank" rel="noopener noreferrer"`. Labels HTML-escaped; ids URL-encoded in paths.

### D3 — Context panel builder

Add `buildContextPanelHtml` (or operation-specific wrappers) producing:
1. `h2` with ⚠️ and operation-specific title tone
2. “What we found” — linked subject (identity or access item), linked policy, violation row (identity form only), optional path/entitlement summary or full lists per operation
3. “What we need from you” — Correct/Mitigate ask (identity) or side-selection ask (access model)

Both seeds: single `ctx-summary` DESCRIPTION with `{{$.form.input.situationSummaryHtml}}`; remove sod-remediation `ctx-identity` and access-model static-only `ctx-item`.

### D4 — Renderer link integration

Extend `renderFlatAccessPathList` and `renderEntitlementTree` with optional `{ uiOrigin?: string }`. Wrap `<strong>{name}</strong>` in links when `line.id` / entitlement id present. Grantor “via …” phrases link grantor when `grantedVia.id` known.

### D5 — Violation row (identity form)

Render: `<strong>Violation:</strong> {escaped id} · <a …>View SOD violations</a>`. No link on the id itself.

### D6 — Email persist body

`buildPersistedSituationSummary` / `buildFormEmailBody` unchanged — no entity deep links, keep 256-char compact format and unquoted form link.

### D7 — Tests

Split CSV-safe constraints: persisted email body tests keep no-quotes rule; in-form `situationSummaryHtml` tests assert quoted links allowed.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| ISC UI routes change across releases | Centralize paths in one module; document in README |
| Custom tenant hostnames without `.api.` | `resolveUiOrigin` fallback uses hostname as-is |
| Link-heavy HTML increases formInput size | Acceptable; DESCRIPTION supports HTML; monitor if issues arise |
| Tenants miss update before re-invoke | Document re-invoke with same `formName` in README/CHANGELOG |

## Migration Plan

1. Implement lib + operation changes
2. Update bundled seeds (context section layout)
3. Deploy connector; operators re-invoke with the **same** `formName` so ensure-by-name patches stale definitions
4. New form instances receive updated layout; already-assigned instances unchanged until recreated

Rollback: revert code; patched definitions retain last-applied seed until next patch or manual ISC admin edit.

## Open Questions

None.
