# Test Mode Config Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement task-by-task.

**Goal:** Gate test mode ISC skip on config absence, not token absence; fail when config is provided but invalid.

**Architecture:** `resolveInvocationConfig` tracks `configProvided`; test mode offline path only when false; config-present path uses full validation + read-only ISC.

**Tech Stack:** TypeScript, Vitest, existing test-mode framework.

**Canonical test command:** `npm test`

---

### Task 1: Config resolution helper

**Files:**
- Modify: `src/framework/test-mode.ts`
- Create: extend `src/framework/test-mode.spec.ts`

- [ ] **Step 1:** Write failing tests for `configProvided` true/false cases
- [ ] **Step 2:** Implement `resolveInvocationConfig`
- [ ] **Step 3:** Run `npm test -- src/framework/test-mode.spec.ts`

---

### Task 2: Wire customOperation gate

**Files:**
- Modify: `src/framework/with-custom-operation.ts`
- Modify: `src/framework/with-custom-operation.spec.ts`

- [ ] **Step 1:** Replace `hasAccessToken` branch with `configProvided`
- [ ] **Step 2:** Update offline log message; add failing-config tests
- [ ] **Step 3:** Remove obsolete token-offline tests
- [ ] **Step 4:** Run full test suite

---

### Task 3: Fixture runner + offline fixture

**Files:**
- Modify: `scripts/run-operation-fixture.ts`
- Modify: `fixtures/custom-example-offline.json`
- Modify: `scripts/run-operation-fixture.spec.ts`
- Modify: `README.md`

- [ ] **Step 1:** Omit context.config when fixture.config undefined
- [ ] **Step 2:** Update offline fixture and docs for SPCX_TEST_MODE
- [ ] **Step 3:** Update tests; smoke `SPCX_TEST_MODE=1 npm run test:operation -- fixtures/custom-example-offline.json`

---

### Task 4: Changelog and version

- [ ] **Step 1:** CHANGELOG breaking note + patch bump
- [ ] **Step 2:** Final `npm test`

## Scenario map

| Scenario | Test file |
|---|---|
| No config skips ISC | `with-custom-operation.spec.ts` |
| Config provided validates | `with-custom-operation.spec.ts` |
| Missing token fails | `with-custom-operation.spec.ts` |
| Offline fixture no config | `run-operation-fixture.spec.ts` |
| Config fixture | `run-operation-fixture.spec.ts` |
