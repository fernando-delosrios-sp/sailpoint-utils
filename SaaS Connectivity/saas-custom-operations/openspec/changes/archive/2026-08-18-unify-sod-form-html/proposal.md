## Why

The two SoD remediation forms (`custom:sod-remediation` and `custom:access-sod-remediation`) render conflicting access differently — one uses emoji text labels on plain lists, the other uses colored panels and type pills on nested trees. Recipients must learn two visual dialects for the same decision (pick a side to remove). Unifying styling through a shared content library makes keep/remove intent obvious via selection-gated green/red panels, adopts consistent type tags, and simplifies sod-remediation lines to icon-only markers with a single legend in the top context panel.

## What Changes

**Shared HTML library**
- Add `src/lib/sod-form-html/` with type tags, outcome panels, emoji helpers, flat access-path and entitlement-tree renderers, and side-variant builders (`plain`, `asKept`, `asRemoved`).

**Form input and seed (both operations)**
- From: two group HTML fields (`groupAContentsHtml`, `groupBContentsHtml`).
- To: six fields per seed — plain plus `AsKept` and `AsRemoved` variants for each side.
- Reason: ISC forms cannot re-style HTML on select; pre-rendered variants swap via `formConditions`.
- Impact: breaking for existing form definition seeds (fingerprint change); tenants get new layout only when a new form definition is created.

**sod-remediation styling**
- From: inline emoji + text labels (`✅ Revocable`, `⭐ Recommended to keep`); plain `<ul>` columns.
- To: type tags on lines; space-separated icon suffixes only; emoji legend footer in `situationSummaryHtml` only; flat horizontal list topology unchanged; green/red panels appear only after `remediationSide` selection.
- Impact: non-breaking for persist keys and workflow `formData`; HTML appearance change only.

**access-sod-remediation styling**
- From: blue/purple side-identity panels always visible; no emojis.
- To: plain lists until selection; green/red outcome panels after selection; unified type tags; nested AP tree and side-by-side COLUMN_SET unchanged; no emojis or legend.
- Impact: HTML appearance change only.

## Capabilities

### New Capabilities

- `sod-form-html`: Shared SoD remediation form HTML builders under `src/lib/sod-form-html/` — type tags, outcome panels, icon suffix formatting, emoji legend, flat access-path lists, entitlement-tree lists, and side HTML variant assembly.

### Modified Capabilities

- `connector-operations/sod-remediation`: Revocability HTML display, situation summary format, group column HTML variants, and form seed formInput/conditions.
- `connector-operations/access-sod-remediation`: Group column HTML variants, type tags, outcome panels, and form seed formInput/conditions.
- `ubiquitous-language`: Promote SoD form HTML vocabulary terms from discovery.

## Impact

- New: `src/lib/sod-form-html/` with unit tests
- Modify: `src/operations/sod-remediation/context.ts`, `revocability-labels.ts` (absorb or delegate to lib), seed JSON, form-service types, specs/tests
- Modify: `src/operations/access-sod-remediation/group-html.ts`, seed JSON, form-service types, specs/tests
- Remove or thin: operation-local HTML duplication once lib is wired
- No change: connector-spec.json commands, persist output keys, workflow JSONPaths, ISC forms client module
- Tests: lib unit tests; update `context.spec.ts`, `group-html.spec.ts`, seed specs; `npm test`
- Docs: both operation READMEs (form HTML behavior); CHANGELOG entry noting form appearance change and new formInput keys
