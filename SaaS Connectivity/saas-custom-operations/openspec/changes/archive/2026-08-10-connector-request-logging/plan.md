# Connector Request Logging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add default readable incoming-request logging for all registered commands and fix invoke config resolution under spcx local dev.

**Architecture:** Extract shared JSON formatting; resolve config via external SDK readConfig (spcx) then bundled readConfig (production); wrap `connector.command()` at registration to log redacted invoke envelopes before handler execution.

**Tech Stack:** TypeScript, @sailpoint/connector-sdk, Vitest, ncc, spcx

## Global Constraints

- Canonical test command: `npm test`
- Coverage thresholds: 60% statements, 50% branches
- Prettier: 120 width, 4-space tabs, no semicolons, single quotes
- No connector-spec.json changes required

---

## Task 1: Shared pretty-json and invoke-config

**Files:** `src/framework/pretty-json.ts`, `src/framework/invoke-config.ts`, `scripts/fixture-output.ts`

- [ ] **Step 1:** Write failing test for `formatSpreadJson` blank-line spacing (may already exist in `scripts/fixture-output.spec.ts`; point import to framework)
- [ ] **Step 2:** Implement `formatSpreadJson` in `src/framework/pretty-json.ts`
- [ ] **Step 3:** Update `scripts/fixture-output.ts` to re-export from framework; run tests
- [ ] **Step 4:** Write failing test for `readInvokeConfig` returning undefined when no sources
- [ ] **Step 5:** Implement `readExternalInvokeConfig` using `createRequire(join(process.cwd(), 'package.json'))`
- [ ] **Step 6:** Implement `readInvokeConfig` with external-then-bundled fallback; run tests

**Verify:** `npm test -- src/framework/invoke-config.spec.ts scripts/fixture-output.spec.ts`

---

## Task 2: Request logging module

**Files:** `src/framework/request-logging.ts`, `src/framework/request-logging.spec.ts`, `src/operations/index.ts`, `src/framework/index.ts`

- [ ] **Step 1:** Write failing tests for `redactConfigForLogging`, `formatIncomingRequest`, `withRequestLogging`
- [ ] **Step 2:** Implement `formatIncomingRequest` with section headers and spread JSON (mirror fixture-output style)
- [ ] **Step 3:** Implement `withRequestLogging` calling `resolveConfigForRequestLogging` → `readInvokeConfig`
- [ ] **Step 4:** Implement `wrapConnectorWithRequestLogging` patching `connector.command`
- [ ] **Step 5:** Wire in `registerCommands`; export from framework index; run tests

**Verify:** `npm test -- src/framework/request-logging.spec.ts`

---

## Task 3: Fix resolveInvocationConfig

**Files:** `src/framework/test-mode.ts`, `src/framework/test-mode.spec.ts`

- [ ] **Step 1:** Change default `readConfigFn` to `readInvokeConfig`
- [ ] **Step 2:** Guard against undefined config: `(await readConfigFn()) ?? {}`
- [ ] **Step 3:** Add/update test for spcx config path if mockable; run full test suite

**Verify:** `npm test`

---

## Task 4: Integration and documentation

**Files:** `README.md`, `CHANGELOG.md`

- [ ] **Step 1:** `npm run build`
- [ ] **Step 2:** Start `npm run debug`; curl POST with `{ type, config, input }`; confirm Incoming request log shows config with redacted token and handler proceeds past config validation
- [ ] **Step 3:** Update README Development section (spcx invoke shape + logging note)
- [ ] **Step 4:** Run changelog-generator skill; add PATCH entry

**Verify:** `npm test && npm run build`

---

## Spec traceability

| Scenario | Test / validation |
|---|---|
| Invoke payload logged at command entry | `request-logging.spec.ts` withRequestLogging |
| Config included when resolved | `request-logging.spec.ts` formatIncomingRequest |
| Token redacted | `request-logging.spec.ts` redactConfigForLogging |
| All registered commands wrapped | `index.spec.ts` + manual spcx curl |
| spcx config resolved | spcx curl + test-mode resolution tests |
| spcx invoke shape documented | README review |
