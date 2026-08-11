## 1. Fingerprint and description composition

- [x] 1.1 Add `computeFormSeedFingerprint` with canonical JSON stringify over structural seed fields
- [x] 1.2 Add watermark parse/format helpers (`@form-seed-sha256:<hex>` first-line convention)
- [x] 1.3 Update `buildCreateFormDefinitionPayload` to compose watermarked description (watermark + optional human text)
- [x] 1.4 Unit tests: fingerprint stability, structural change detection, payload description format, parser edge cases

## 2. Ensure-by-name refresh flow

- [x] 2.1 Extend `FormsApiLike` with `getFormDefinitionByKeyV1` and `patchFormDefinitionV1`
- [x] 2.2 Update `ensureFormDefinitionByName`: get-by-id + watermark compare; reuse on match
- [x] 2.3 Implement stale/missing watermark patch path with `ConnectorError` surfacing
- [x] 2.4 Unit tests: matching watermark skips patch; stale watermark patches; missing definition creates; get/patch/search error paths
- [x] 2.5 Update offline/mock `RequestContext` forms client stubs for new methods

## 3. Operation integration

- [x] 3.1 Confirm SOD `ensureSodFormDefinition` uses generic watermarked payload (adjust only if caller overrides block watermark)
- [x] 3.2 Update SOD/forms specs tests (`seed.spec.ts`, `forms.spec.ts`) for watermarked descriptions

## 4. Documentation

- [x] 4.1 Update CHANGELOG — auto-refresh replaces manual form recreate guidance for seed updates
- [x] 4.2 Update inline JSDoc on `ensureFormDefinitionByName` and fingerprint exports (N/A for README — no user-facing CLI change)

## 5. Changelog

- [x] 5.1 Create or update changelog entry covering form definition auto-refresh on seed change
- [x] 5.2 Confirm entry covers user-visible change: stale tenant forms refresh on launch without manual delete
