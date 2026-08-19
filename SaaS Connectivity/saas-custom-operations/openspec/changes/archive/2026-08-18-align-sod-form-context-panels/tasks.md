## 1. ISC UI link module

- [x] 1.1 Add `src/lib/sod-form-html/isc-ui-links.ts` with `resolveUiOrigin`, path templates, and `renderIscUiLink`
- [x] 1.2 Export new helpers from `src/lib/sod-form-html/index.ts`
- [x] 1.3 Add unit tests for ui origin derivation, each link kind, offline fallback, and HTML escaping

## 2. Shared context panel builder

- [x] 2.1 Add context panel HTML builder(s) under `src/lib/sod-form-html/` with “What we found / What we need from you” structure
- [x] 2.2 Add unit tests for identity-form and access-model panel variants

## 3. Line renderer link integration

- [x] 3.1 Extend `renderFlatAccessPathList` with optional `uiOrigin`; link names and grantor references when ids present
- [x] 3.2 Extend `renderEntitlementTree` with optional `uiOrigin`; link AP and entitlement names
- [x] 3.3 Update `sod-form-html.spec.ts` for linked and offline variants

## 4. sod-remediation operation

- [x] 4.1 Refactor `buildSituationSummary` to use context panel builder and ISC UI links; violation id plain + violations list link
- [x] 4.2 Pass `uiOrigin` into group column HTML assembly in `assembleFormInput`
- [x] 4.3 Keep `buildPersistedSituationSummary` compact without entity deep links
- [x] 4.4 Update seed: remove `ctx-identity`, user-facing context section label, single `ctx-summary`
- [x] 4.5 Update `context.spec.ts`, `seed.spec.ts`, and `index.spec.ts` for new HTML shape and quoted in-form links

## 5. access-model-sod-remediation operation

- [x] 5.1 Add `buildSituationSummaryHtml` (or equivalent) assembling context panel at launch
- [x] 5.2 Add `situationSummaryHtml` to form-service types and index launch `formInput`
- [x] 5.3 Pass `uiOrigin` into `buildGroupContentsHtml`
- [x] 5.4 Update seed: replace static `ctx-item` with `ctx-summary` interpolating `situationSummaryHtml`
- [x] 5.5 Update `form-service.spec.ts`, `index.spec.ts`, and `forms.spec.ts` seed assertions

## 6. Verification

- [x] 6.1 Confirm canonical test command: `npm test`
- [x] 6.2 Run `npm run typecheck`
- [x] 6.3 All delta spec scenarios covered by named automated tests

## 7. Documentation

- [x] 7.1 Update `src/operations/sod-remediation/README.md` for context panel, links, and watermark patch migration
- [x] 7.2 Update `src/operations/access-model-sod-remediation/README.md` for context panel, links, and watermark patch migration
- [x] 7.3 Document ISC admin path templates in sod-form-html module or README note

## 8. Changelog

- [x] 8.1 Create or update changelog entry for this change via changelog-generator
- [x] 8.2 Confirm entry covers unified context panels, admin links, and watermark patch migration note
