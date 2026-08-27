# Form definition version watermark Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Embed a seed fingerprint in form definition descriptions and auto-refresh stale tenant definitions during ensure-by-name.

**Architecture:** Generic helpers in `src/isc/forms/` compute SHA-256 over canonical structural seed JSON, format `@form-seed-sha256:<hex>` as the first description line, and extend `ensureFormDefinitionByName` to get-by-id, compare, patch on mismatch, or create when absent. Operations inherit via existing `buildCreateFormDefinitionPayload` calls.

**Tech Stack:** TypeScript, Node `crypto`, sailpoint-api-client CustomFormsApi, Vitest

**Test command:** `npm test`

---

## Task 1: Fingerprint and watermark helpers

- [ ] **Step 1:** Write failing tests in `src/isc/forms/forms.spec.ts` for `computeFormSeedFingerprint` stability and sensitivity to `formElements` changes
- [ ] **Step 2:** Implement `canonicalSeedStructuralJson(seed)` and `computeFormSeedFingerprint` in `seed-loader.ts` (or `seed-fingerprint.ts` if cleaner)
- [ ] **Step 3:** Write failing tests for `parseFormSeedWatermark` / `formatWatermarkedDescription`
- [ ] **Step 4:** Implement parse/format helpers; export from `index.ts`
- [ ] **Step 5:** Update `buildCreateFormDefinitionPayload` tests — description starts with `@form-seed-sha256:`
- [ ] **Step 6:** Implement watermarked description composition; run `npm test`

## Task 2: Ensure-by-name compare and patch

- [ ] **Step 1:** Write failing test — existing definition with matching watermark does not call patch/create
- [ ] **Step 2:** Write failing test — stale watermark triggers `patchFormDefinitionV1` with template body
- [ ] **Step 3:** Write failing test — legacy description (no watermark) triggers patch
- [ ] **Step 4:** Extend `FormsApiLike` and `ensure-definition.ts` with get + patch flow
- [ ] **Step 5:** Add error-path tests for get/patch failures → `ConnectorError`
- [ ] **Step 6:** Update `src/framework/request-context.ts` offline forms mocks with get/patch stubs
- [ ] **Step 7:** Run `npm test`

## Task 3: Integration and docs

- [ ] **Step 1:** Review `form-service.ts` — ensure human seed description still appears after watermark line
- [ ] **Step 2:** Update `seed.spec.ts` expectations for watermarked create payload
- [ ] **Step 3:** Update CHANGELOG (remove manual recreate note for seed updates where applicable)
- [ ] **Step 4:** Final `npm test` and `npm run build`

**Spec references:** `openspec/changes/form-definition-version-watermark/specs/target-client/forms/spec.md`

**Design references:** `openspec/changes/form-definition-version-watermark/design.md` §D1–D6
