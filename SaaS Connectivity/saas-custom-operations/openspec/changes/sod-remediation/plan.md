# SOD Remediation Launch Operation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `custom:sod-remediation` — a launch-only operation that fetches a violation, ensures a named form definition exists, creates a standalone form instance for the violation owner (or override), and returns `formUrl` + `situationSummary`.

**Architecture:** Extend `ctx.sdk` with CustomFormsApi plus a thin experimental HTTP client for `/violations/v1` and `/controls/v1`. An access-path resolver expands entitlement pairs to AP/role display lists and hidden revoke JSON. The operation handler orchestrates ensure-form-by-name, formInput assembly, and instance create. Revoke/mitigate execution stays in downstream workflows reading submitted form keys.

**Tech Stack:** TypeScript, Vitest, `@sailpoint/connector-sdk`, `sailpoint-api-client`, experimental ISC REST headers

## Global Constraints

- Canonical test command: `npm test`
- Build command: `npm run build`
- Codegen command: `npm run codegen:schemas` (registers new command)
- Integration validation: `npm run build` + optional `spcx` pack after implementation
- Operation input: `violationId`, `formName`, optional `owner`
- Operation output: `formUrl`, `situationSummary` only
- Never PATCH existing form definitions after create
- Experimental APIs require `X-SailPoint-Experimental: true`

**Spec references:** `openspec/changes/sod-remediation/specs/connector-operations/spec.md`, `openspec/changes/sod-remediation/specs/target-client/spec.md`

---

## Task 1: Experimental ISC HTTP client

**Files:**
- Create: `src/isc/experimental-client.ts`
- Create: `src/isc/experimental-client.spec.ts`

- [ ] **Step 1:** Write failing test — `getViolationV1(id)` calls `GET /violations/v1/{id}` with experimental header
- [ ] **Step 2:** Write failing test — `listControlsV1()` calls `GET /controls/v1` with experimental header
- [ ] **Step 3:** Implement minimal axios/fetch wrapper using `apiUrl` + token from standard input
- [ ] **Step 4:** Run `npm test -- experimental-client` — PASS

---

## Task 2: Access path resolver

**Files:**
- Create: `src/isc/access-path-resolver.ts`
- Create: `src/isc/access-path-resolver.spec.ts`

- [ ] **Step 1:** Write failing test — entitlement-only side produces display lines and standard warning
- [ ] **Step 2:** Write failing test — AP-granted entitlement adds AP line and elevated warning
- [ ] **Step 3:** Write failing test — role-granted entitlement adds role line and elevated warning
- [ ] **Step 4:** Write failing test — `recommendedRevoke` prefers Role > Access Profile > Entitlement
- [ ] **Step 5:** Implement resolver using identity access listing (Search or `listIdentityAccessItemsV1`)
- [ ] **Step 6:** Run `npm test -- access-path-resolver` — PASS

---

## Task 3: SDK forms client extension

**Files:**
- Modify: `src/framework/sdk-factory.ts`
- Modify: `src/framework/types.ts`
- Modify: `src/framework/request-context.ts` (if stub needs forms for test mode)

- [ ] **Step 1:** Write failing test — `createSailPointClients` returns `forms: CustomFormsApi`
- [ ] **Step 2:** Wire `CustomFormsApi` into factory and `SailPointClients` type
- [ ] **Step 3:** Update offline test-mode stub to no-op forms methods
- [ ] **Step 4:** Run `npm test -- sdk-factory request-context` — PASS

---

## Task 4: Seed form asset

**Files:**
- Create: `assets/forms/sod-violation-remediation.seed.json`
- Create: `src/isc/form-seed-loader.ts` (optional small helper)
- Create: `src/isc/form-seed-loader.spec.ts`

- [ ] **Step 1:** Author seed JSON from scratch export — add `formInput`, DESCRIPTION blocks, `remediationSide` SELECT, hidden keys, `hasControls` conditions
- [ ] **Step 2:** Write test — loader reads seed and applies runtime `formName` + owner on create payload
- [ ] **Step 3:** Implement loader
- [ ] **Step 4:** Run `npm test -- form-seed-loader` — PASS

---

## Task 5: Form ensure + instance service

**Files:**
- Create: `src/isc/sod-form-service.ts`
- Create: `src/isc/sod-form-service.spec.ts`

- [ ] **Step 1:** Write failing test — `ensureFormDefinition(name)` searches tenant; creates from seed when missing
- [ ] **Step 2:** Write failing test — `ensureFormDefinition(name)` reuses existing ID without patch
- [ ] **Step 3:** Write failing test — `createRemediationInstance` sets `standAloneForm: true`, recipient, formInput
- [ ] **Step 4:** Implement service using mocked CustomFormsApi
- [ ] **Step 5:** Run `npm test -- sod-form-service` — PASS

---

## Task 6: Sod remediation operation handler

**Files:**
- Create: `src/operations/sod-remediation-operation.ts`
- Create: `src/operations/sod-remediation-operation.spec.ts`
- Generated: `src/operations/sod-remediation-operation.schema.ts`, `auto-registry.ts`, `connector-spec.json`

- [ ] **Step 1:** Write failing test — handler returns `formUrl` and `situationSummary` on happy path
- [ ] **Step 2:** Write failing test — recipient defaults to violation owner; `owner` input overrides
- [ ] **Step 3:** Write failing test — zero controls sets mitigate-unavailable formInput + summary note
- [ ] **Step 4:** Implement handler wiring violation fetch, controls list, access resolver, form service
- [ ] **Step 5:** Run `npm run codegen:schemas`; commit generated registry + manifest
- [ ] **Step 6:** Register fixture handler in `scripts/run-operation-fixture.ts`
- [ ] **Step 7:** Run `npm test -- sod-remediation-operation` — PASS

---

## Task 7: Fixture and docs

**Files:**
- Create: `fixtures/sod-remediation.json` (or under existing fixtures dir)
- Modify: `README.md`
- Modify: `CHANGELOG.md` (via changelog-generator skill)

- [ ] **Step 1:** Add offline/test-mode fixture with mocked SDK deps
- [ ] **Step 2:** Document invoke payload, output fields, workflow formData keys, and downstream workflow pattern
- [ ] **Step 3:** Run full `npm test` — PASS
- [ ] **Step 4:** Run `npm run build` — PASS
- [ ] **Step 5:** Update CHANGELOG via changelog-generator skill

---

## Commit guidance

- Commit experimental client + access resolver separately
- Commit SDK forms extension
- Commit seed asset + form service
- Commit operation handler + codegen outputs together
- Commit docs/CHANGELOG last

## PRECHECK (apply phase)

Before Task 6 integration spike against live tenant (optional):
- Confirm violation JSON field paths for left/right criteria
- Confirm controls SELECT data source works in Form Builder or document TEXT fallback
