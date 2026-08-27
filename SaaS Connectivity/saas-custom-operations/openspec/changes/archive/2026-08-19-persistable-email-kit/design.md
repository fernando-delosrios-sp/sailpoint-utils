## Context

Form-launch and approval operations duplicate compact HTML email construction (escape, truncate, fit into `ISC_STRING_ATTRIBUTE_MAX_LENGTH`). `src/lib/sod-form-html/` owns in-form DESCRIPTION HTML and already exports `escapeHtml`. This change extracts a dedicated kit for workflow-oriented persistable email snippets and migrates callers without changing persist keys or workflow JSON.

## Goals / Non-Goals

**Goals:**
- One shared module for escape, truncation, unquoted CTA links, and fit-to-budget rendering
- Preserve existing email body/subject outputs (golden tests stay green)
- Clear boundary vs `sod-form-html` (form DESCRIPTION vs persistable email)

**Non-Goals:**
- Form notification envelope / persist key mapper
- Form launch facade
- Changing STRING max length or workflow contracts
- Rewriting domain email copy

## Decisions

### D1: Module path
- **Choice**: `src/lib/persistable-email/`
- **Reason**: Matches capability name; keeps content libs under `src/lib/` alongside `sod-form-html`
- **Considered alternatives**: Fold into `sod-form-html` (rejected — different audience); put under `src/framework/` (rejected — not framework runtime)

### D2: escapeHtml ownership
- **Choice**: Implement `escapeHtml` in `persistable-email`; have `sod-form-html/escape.ts` re-export from there (or thin wrapper) so one implementation
- **Reason**: Avoid two escape tables drifting
- **Considered alternatives**: Keep escape only in sod-form-html and import from callers (works but couples email kit to SoD form lib)

### D3: Fit API shape
- **Choice**: Export `fitPersistableHtml({ render, slots, optionalSuffixes?, maxLength? })` (or equivalent) where `render(slotValues)` returns full HTML and slots are pre-escaped strings shortened proportionally; optional suffixes tried then dropped
- **Reason**: Covers name-budget and sod controls-note pattern without baking domain copy into the kit
- **Considered alternatives**: Only export truncate helpers (insufficient — fit logic still duplicated)

### D4: Unquoted href
- **Choice**: `renderUnquotedHrefCta(url, label)` producing `<a href=${escapedUrl}>${escapedLabel}</a>`
- **Reason**: Preserve DelimitedFile/CSV-safe convention already used by form-email modules
- **Considered alternatives**: Quoted href (rejected — would change persisted strings and risk CSV issues)

### D5: C4 diagram
- **Choice**: Omit — single library module, no multi-container structural change

## Risks / Trade-offs

- [Risk] Behavioral drift during migration → Mitigation: keep existing unit tests; assert length ≤ 256 and CTA presence; prefer byte-identical bodies where practical
- [Trade-off] Generic fit API is slightly abstract → Reason: avoids kit knowing every operation’s copy
- [Risk] Re-export cycle if sod-form-html and persistable-email cross-import → Mitigation: escape lives in persistable-email only; sod-form-html imports it

## Migration Plan

1. Add kit + tests
2. Migrate four call sites to kit; delete local duplicates
3. Point `sod-form-html` escape at kit
4. `npm test` + `npm run typecheck`
5. Rollback: revert commits; no tenant/deploy migration (no persist key or seed changes)

## Open Questions

None.
