# Custom Operation Failed Account Details Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** On every terminal custom operation failure, upsert a result-source account with `status: failed` and mandatory `details` carrying the error message; add `details` to base schema and support optional informative details on success persists.

**Architecture:** Extend framework core schema (`id`, `status`, `date`, `details`). Centralize failure persist in `customOperation` wrapper (catch block + tracked `res.send`). Reuse existing persist pipeline with `verify: false` on failure path. Preserve invoke `{ status, error }` response. Test mode logs inhibited failed persists.

**Tech Stack:** TypeScript, Vitest, `@sailpoint/connector-sdk`, `sailpoint-api-client`

## Global Constraints

- Canonical test command: `npm test`
- Build command: `npm run build`
- Spec references: `openspec/changes/custom-operation-failed-account-details/specs/custom-operation-framework/spec.md`, `openspec/changes/custom-operation-failed-account-details/specs/operation-test-runner/spec.md`
- Design references: `openspec/changes/custom-operation-failed-account-details/design.md` §D1–D7

---

## Task 1: Base schema `details` attribute

**Files:**
- Modify: `src/framework/base-account-schema.ts`
- Modify: `src/framework/base-account-schema.spec.ts`

- [ ] **Step 1:** Write failing test — `buildBaseAccountSchema` includes `details` STRING after core attributes
- [ ] **Step 2:** Add `details` to `CORE_ATTRIBUTES` and `CORE_ATTRIBUTE_NAMES`
- [ ] **Step 3:** Run `npm test -- base-account-schema` — PASS

---

## Task 2: Persist pipeline accepts `details`

**Files:**
- Modify: `src/framework/persist-result.ts`
- Modify: `src/framework/persist-result.spec.ts`
- Modify: `src/framework/result-source.ts` (if core reconciliation list needs update)

- [ ] **Step 1:** Write failing test — success persist stores optional `details` from attributes
- [ ] **Step 2:** Write failing test — `details` truncated at 256 chars with warning
- [ ] **Step 3:** Implement `buildAccountAttributes` merge for `details` (framework core, handler-writable)
- [ ] **Step 4:** Run `npm test -- persist-result` — PASS

---

## Task 3: Automatic failure persist in wrapper

**Files:**
- Modify: `src/framework/with-custom-operation.ts`
- Modify: `src/framework/with-custom-operation.spec.ts`
- Optionally: `src/framework/failure-persist.ts` if extraction improves clarity

- [ ] **Step 1:** Write failing test — handler throw calls persist with `{ details: message }`, status `failed`, identity `requestId`
- [ ] **Step 2:** Write failing test — `ctx.res.send({ status: 'failed', error })` triggers same persist
- [ ] **Step 3:** Write failing test — persist verification failure writes failed account with details
- [ ] **Step 4:** Implement failure persist helper; wire catch block and `trackedRes.send`; use `verify: false`; swallow persist errors
- [ ] **Step 5:** Refactor `runCustomOperation` to expose requestId + persist to failure paths (init failures after partial context)
- [ ] **Step 6:** Run `npm test -- with-custom-operation` — PASS

---

## Task 4: Test mode inhibited failure persist

**Files:**
- Modify: `src/framework/test-mode-persist.ts`
- Modify: `src/framework/test-mode-persist.spec.ts`

- [ ] **Step 1:** Write failing test — inhibited failed persist log includes `details`
- [ ] **Step 2:** Ensure failure persist path uses same test-mode persist (no ISC calls)
- [ ] **Step 3:** Run `npm test -- test-mode-persist` — PASS

---

## Task 5: Local runner visibility (if needed)

**Files:**
- Modify: `scripts/payload-output.ts` or `scripts/call-op.ts` (only if summary omits failed inhibited persists)
- Modify: `scripts/call-op.spec.ts` or adjacent spec if present

- [ ] **Step 1:** Write failing test — failed operation in test mode shows inhibited persist with status failed and details
- [ ] **Step 2:** Implement summary formatting
- [ ] **Step 3:** Run targeted tests — PASS

---

## Task 6: Documentation and changelog

**Files:**
- Modify: `README.md` (framework / persist section)
- Modify: `CHANGELOG.md`
- Modify: JSDoc in `with-custom-operation.ts`

- [ ] **Step 1:** Document `details` attribute and failure account behavior in README
- [ ] **Step 2:** Add CHANGELOG Unreleased entry
- [ ] **Step 3:** Run full `npm test` — PASS

---

## Verification checklist (apply phase)

- [ ] All tasks.md checkboxes complete
- [ ] `npm test` exit 0
- [ ] `openspec validate --all` passes for this change
- [ ] No regression: success persist and existing `{ status, error }` invoke response behavior preserved
