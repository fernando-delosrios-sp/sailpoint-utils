## 1. Shared sod-form-html library

- [x] 1.1 Create `src/lib/sod-form-html/` with escape helper, color tokens, and `iconSuffix(...icons)` (space-separated)
- [x] 1.2 Implement `renderTypeTag(kind)` for role, access profile, and entitlement pills
- [x] 1.3 Implement `wrapOutcomePanel(content, 'keep' | 'remove')` and `buildSideVariants(bodyHtml)` returning plain, asKept, asRemoved
- [x] 1.4 Implement `renderEmojiLegend()` footer block
- [x] 1.5 Implement `renderFlatAccessPathList(lines, options)` delegating from sod-remediation access path model
- [x] 1.6 Implement `renderEntitlementTree(ids, expanded, options)` delegating from access-sod expansion model
- [x] 1.7 Add unit tests for tags, panels, icon spacing, legend, and variant assembly

## 2. sod-remediation integration

- [x] 2.1 Wire `context.ts` / replace `revocability-labels.ts` usage to sod-form-html flat list renderer
- [x] 2.2 Emit six group HTML formInput fields from `assembleFormInput`
- [x] 2.3 Append emoji legend to `situationSummaryHtml` only; keep email summary parity without legend in persist link variant as spec defines
- [x] 2.4 Update `sod-violation-remediation.seed.json`: six formInput fields, three conditional DESCRIPTION elements per column, formConditions SHOW/HIDE on `remediationSide` selection (live visual swap)
- [x] 2.5 Update `form-service.ts` types and `pickDeclaredFormInputValues` call path
- [x] 2.6 Update `context.spec.ts`, `seed.spec.ts`, and related tests for icon-only lines and six-field contract

## 3. access-sod-remediation integration

- [x] 3.1 Refactor `group-html.ts` to use sod-form-html entitlement tree and side variants
- [x] 3.2 Emit six group HTML formInput fields from operation index/form assembly
- [x] 3.3 Update `access-sod-remediation.seed.json`: six formInput fields, conditional DESCRIPTION elements, formConditions SHOW/HIDE on `remediationSide` selection (live visual swap)
- [x] 3.4 Update `form-service.ts` types and tests in `group-html.spec.ts`, `form-service.spec.ts`, `index.spec.ts`

## 4. Verification

- [x] 4.1 Confirm canonical test command: `npm test`
- [x] 4.2 All delta spec scenarios covered by named automated tests in lib and operation specs

## 5. Documentation

- [x] 5.1 Update `src/operations/sod-remediation/README.md` — formInput HTML fields, outcome panels on selection, legend placement
- [x] 5.2 Update `src/operations/access-sod-remediation/README.md` — six HTML fields, outcome panels on selection, no emojis
- [x] 5.3 Note form definition migration (new `formName` required for updated seed layout) in both READMEs

## 6. Changelog

- [x] 6.1 Create or update CHANGELOG entry via changelog-generator during apply
- [x] 6.2 Confirm entry covers unified form HTML styling and new formInput keys for both operations
