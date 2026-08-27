# Inline Spec Test Fixtures Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Enforce inline Vitest fixtures in `*.spec.ts`, remove `sod-remediation/offline-data.ts`, and split identity-access into orchestration (`fetch-identity-access-items.ts`) plus runtime offline lookup (`offline-data.ts`).

**Architecture:** SDK orchestration in `fetch-identity-access-items.ts`; runtime offline lookup stays in `offline-data.ts`; SOD `OFFLINE_VIOLATION` co-located in `sod-remediation/index.ts`. Specs keep inline mocks — no Vitest fixture sibling modules.

**Tech Stack:** TypeScript, Vitest, OpenSpec delta specs

**Canonical test command:** `npm test`

**Smoke command:** `npm run call:op -- payloads/sod-remediation-offline.json`

**Refs:** `openspec/changes/inline-spec-test-fixtures/{design.md, specs/**/spec.md}`

---

## Task 1: Identity access module split

**Files:**
- Create/rename: `src/isc/identity-access/fetch-identity-access-items.ts`
- Retain: `src/isc/identity-access/offline-data.ts`
- Modify: `src/isc/identity-access/index.ts`, `src/isc/identity-access/identity-access.spec.ts`
- Delete: `src/isc/identity-access/fetch-from-sdk.ts`

- [x] **Step 1:** Move SDK orchestration to `fetch-identity-access-items.ts`
- [x] **Step 2:** Keep offline lookup map private in `offline-data.ts`; export only `fetchIdentityAccessItemsOffline`
- [x] **Step 3:** Update `index.ts` barrel exports
- [x] **Step 4:** Run `npm test -- src/isc/identity-access/identity-access.spec.ts`

## Task 2: SOD remediation offline violation co-location

**Files:**
- Modify: `src/operations/sod-remediation/index.ts`
- Delete: `src/operations/sod-remediation/offline-data.ts`

- [x] **Step 1:** Move `OFFLINE_VIOLATION` into `index.ts` as module-private constant
- [x] **Step 2:** Delete `sod-remediation/offline-data.ts`
- [x] **Step 3:** Run `npm test -- src/operations/sod-remediation/index.spec.ts`

## Task 3: Convention enforcement sweep

- [x] **Step 1:** Confirm no `fixtures.ts` or Vitest-only test-data modules under `src/`
- [x] **Step 2:** Confirm specs import production APIs via barrel/index, not fixture siblings
- [x] **Step 3:** Run full `npm test`

## Task 4: Offline invoke smoke

- [x] **Step 1:** Run `npm run call:op -- payloads/sod-remediation-offline.json`
- [x] **Step 2:** Verify exit 0 and response includes `formUrl` / `situationSummary`

## Task 5: Documentation and changelog

- [x] **Step 1:** JSDoc on offline constants
- [x] **Step 2:** Update CHANGELOG Unreleased entry
- [x] **Step 3:** Mark README/API doc tasks N/A

---

## Scenario traceability

| Spec scenario | Verification |
|---|---|
| custom-operation-framework: Spec file contains its own mock data | Inline mocks in `*.spec.ts` |
| custom-operation-framework: No new test-fixture sibling files | No `fixtures.ts` under `src/` |
| target-client/identity-access: SDK loopback listing | `identity-access.spec.ts` |
| target-client/identity-access: Offline data listing | `identity-access.spec.ts` |
| target-client/identity-access: Offline stub in dedicated module | `offline-data.ts` + `fetch-identity-access-items.ts` |
