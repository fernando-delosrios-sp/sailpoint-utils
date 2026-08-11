# Plan: sod-remediation-access-search

**Goal:** Replace hidden stringified revoke JSON payloads with plain ISC access search filters per violation side for workflow consumption.

**Architecture:** `buildAccessSearchString()` projects resolved `accessPaths` ids into `id:x OR id:y` strings. `assembleFormInput()` emits `groupAAccessSearch` / `groupBAccessSearch`. Seed hidden fields pass values through to submitted formData. Internal `revokePayload` remains for resolver/logging only.

**Tech Stack:** TypeScript, Vitest, ISC Custom Forms seed JSON

**Test command:** `npm test`

---

## Task 1: Search string builder

- [x] **Step 1:** Write failing test — `buildAccessSearchString` joins ids with ` OR `
- [x] **Step 2:** Implement in `access-path-resolver.ts`
- [x] **Step 3:** Run `npm test -- access-path-resolver` — green

## Task 2: Form contract swap

- [x] **Step 1:** Write failing test — `assembleFormInput` emits search strings, not revoke payloads
- [x] **Step 2:** Update `context.ts` and `form-service.ts`
- [x] **Step 3:** Update seed JSON hidden keys and conditions
- [x] **Step 4:** Update `seed.spec.ts` — green

## Task 3: Docs and spec

- [x] **Step 1:** Update README and CHANGELOG
- [x] **Step 2:** Sync main sod-remediation spec (hidden keys + search scenarios)
- [x] **Step 3:** Run full `npm test` — green

## Spec coverage map

| Scenario | Test evidence |
|---|---|
| Hidden access search string per side | `context.spec.ts` — `assembleFormInput includes hidden access search strings` |
| Single-item side search string | `access-path-resolver.spec.ts` — `buildAccessSearchString` single item |
| Multi-item OR join | `access-path-resolver.spec.ts` — `buildAccessSearchString joins item ids with OR` |
| Seed hidden keys | `seed.spec.ts` — workflow-friendly form keys |
| No revoke payloads in formData contract | `seed.spec.ts` + delta spec REMOVED requirement |
