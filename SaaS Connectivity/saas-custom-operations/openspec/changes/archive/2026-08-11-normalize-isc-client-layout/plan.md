# Normalize ISC Client Layout Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Restructure `src/isc/` into per-API subdirectories with separated identity-access and pre-SDK modules, aligned to target-client spec deltas.

**Architecture:** One folder per ISC API surface; `identity-access/` orchestrates only; `http/` holds shared pre-SDK GET transport; sod-remediation imports updated; flat legacy files removed.

**Tech Stack:** TypeScript, Vitest, `@sailpoint/connector-sdk`, `sailpoint-api-client`

**Spec references:** `openspec/changes/normalize-isc-client-layout/specs/target-client/**`

**Canonical test command:** `npm test`

---

## Task 1: Shared HTTP transport

- [ ] **Step 1:** Create `src/isc/http/isc-get.ts` — copy `IscClientConfig`, `EXPERIMENTAL_HEADER`, `iscGet` from legacy isc-client
- [ ] **Step 2:** Verify no direct consumers yet; transport tested via violations/controls specs

## Task 2: Violations module

- [ ] **Step 1:** Create `src/isc/violations/violations.ts` importing from `../http/isc-get`
- [ ] **Step 2:** Export public API via `src/isc/violations/index.ts`
- [ ] **Step 3:** Port tests to `src/isc/violations/violations.spec.ts`
- [ ] **Step 4:** Run `npm test -- violations` — PASS

## Task 3: Controls module

- [ ] **Step 1:** Create `src/isc/controls/controls.ts` importing from `../http/isc-get`
- [ ] **Step 2:** Export via `src/isc/controls/index.ts`
- [ ] **Step 3:** Add `src/isc/controls/controls.spec.ts`
- [ ] **Step 4:** Run `npm test -- controls` — PASS

## Task 4: Identity access API split

- [ ] **Step 1:** Create `identity-history/list-assigned-access-items.ts` + spec
- [ ] **Step 2:** Create `access-profiles/access-profile-entitlements.ts` + spec
- [ ] **Step 3:** Create `roles/role-entitlements.ts` + spec
- [ ] **Step 4:** Create `identity-access/{types,fetch-from-sdk,offline-data,index}.ts` delegating to 4.1–4.3
- [ ] **Step 5:** Port orchestration tests to `identity-access/identity-access.spec.ts`
- [ ] **Step 6:** Run `npm test -- identity-history access-profiles roles identity-access` — PASS

## Task 5: Token identity + consumers

- [ ] **Step 1:** Move token-identity to `src/isc/token-identity/`
- [ ] **Step 2:** Update sod-remediation imports (`violations`, `controls`, `identity-access`, `token-identity`)
- [ ] **Step 3:** Update `index.spec.ts` vi.mock paths
- [ ] **Step 4:** Update `framework/index.ts` and `result-source.ts` imports

## Task 6: Cleanup and full verify

- [ ] **Step 1:** Delete flat legacy isc files and old specs
- [ ] **Step 2:** Grep for stale paths; fix stragglers
- [ ] **Step 3:** Run `npm test` — PASS (211+ tests)
- [ ] **Step 4:** Run `npm run build` — PASS
- [ ] **Step 5:** Update README layout section

## Decision traceability

| Design | Plan task |
|--------|-----------|
| D1 Per-API subdirs | Tasks 2–5 |
| D2 Identity access split | Task 4 |
| D3 No experimental umbrella | Tasks 2–3 + http/ |
| D4 Barrel exports | index.ts in violations, controls, identity-access |
| D5 Spec deltas | Verified in Task 6 README + archive phase |
