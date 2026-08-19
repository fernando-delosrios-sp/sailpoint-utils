## Why

The two SoD remediation forms share group-column styling but their upper panels still read like separate internal tools — different section titles, sod-remediation duplicates identity metadata, access-model shows only two static lines, and neither links to the ISC admin records they reference. ISC end users (violation owners and policy owners) must infer what happened and what to do. Aligning context panels, wording, emoji signposting, and admin deep links makes both forms feel like one solution and reduces time spent hunting for related records in the admin UI.

## What Changes

**Shared ISC UI link layer**
- Add `resolveUiOrigin(apiUrl)` and `renderIscUiLink` under `src/lib/sod-form-html/` with path templates for identity, SoD policy, role, access profile, entitlement, and violations list.
- Domain derived from invoke `apiUrl`; never hardcoded. Offline: plain text only.

**Unified context panel structure (both forms)**
- From: sod-remediation uses “Identity policy violation detection” with duplicate static + dynamic blocks; access-model uses “Access model policy violation detection” with static item/policy lines only.
- To: single `situationSummaryHtml` DESCRIPTION per form with “What we found” / “What we need from you” blocks, ⚠️ heading, user-facing copy, and operation-specific calls to action.
- Reason: ISC recipients need situation + required action upfront.
- Impact: seed layout change; existing definitions patched in place on re-invoke when fingerprint is stale (same `formName`).

**sod-remediation context panel**
- Remove redundant `ctx-identity` seed element.
- Extend `buildSituationSummary` to link identity, policy, path lines, and grantor references; violation id plain text + “View SOD violations” link.
- Persisted email body unchanged (compact, no entity deep links).

**access-model context panel**
- Add `situationSummaryHtml` formInput assembled at launch (replacing static-only `ctx-item` content).
- Context panel uses ⚠️/ℹ️ signposting; group columns still omit revocability emojis and legend.
- Link access item, policy, and column line names when online.

**Line renderers**
- `renderFlatAccessPathList` and `renderEntitlementTree` accept optional `uiOrigin` and wrap display names in ISC UI links when id is known.

## Capabilities

### New Capabilities

_None — extends existing `sod-form-html` library._

### Modified Capabilities

- `sod-form-html`: ISC UI origin resolution, admin link rendering, optional linked line names in shared renderers.
- `connector-operations/sod-remediation`: Situation summary HTML format, context panel seed layout, linked entity names in summary and path lists.
- `connector-operations/access-model-sod-remediation`: Form launch `situationSummaryHtml`, context panel seed layout, linked entity names in summary and column lists.
- `ubiquitous-language`: Promote context panel, ISC UI link, and UI origin terms.

## Impact

- New/modify: `src/lib/sod-form-html/` (`isc-ui-links.ts`, context panel helper, renderer options)
- Modify: `src/operations/sod-remediation/context.ts`, seed JSON, tests
- Modify: `src/operations/access-model-sod-remediation/index.ts`, form-service types, seed JSON, tests
- No change: connector-spec.json commands, persist output keys, workflow JSONPaths
- Tests: lib unit tests for ui origin + links; update context, seed, and index specs
- Docs: both operation READMEs (context panel + links); CHANGELOG noting form appearance and watermark patch migration
