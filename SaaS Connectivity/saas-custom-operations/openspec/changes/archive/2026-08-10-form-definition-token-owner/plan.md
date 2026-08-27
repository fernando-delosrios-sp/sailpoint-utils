# Form Definition Token Owner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix `custom:sod-remediation` so new form definitions are owned by the access-token identity (not the violation owner), remove temporary debug fetch instrumentation, and extend logging to show definition owner resolution.

**Architecture:** Resolve owner once in the operation handler using existing `resolveTokenIdentity` for online invokes and `offline-owner` fallback when `!ctx.apiUrl && !ctx.token`. Pass resolved id to `ensureFormDefinition`. Form instance recipient logic stays unchanged. Strip debug `#region agent log` blocks from SOD-related files.

**Tech Stack:** TypeScript, Vitest, `@sailpoint/connector-sdk`, existing `resolveTokenIdentity` from `src/framework/source-provisioning.ts`

## Global Constraints

- Canonical test command: `npm test`
- Build command: `npm run build`
- No connector-spec or operation I/O changes
- Never PATCH existing form definitions
- Recipient resolution unchanged: `input.owner ?? violation.owner.id`

**Spec reference:** `openspec/changes/form-definition-token-owner/specs/connector-operations/spec.md`

---

## Task 1: Form definition owner resolution

**Files:**
- Modify: `src/operations/sod-remediation-operation.ts`
- Modify: `src/isc/sod-remediation-logging.ts`

- [ ] **Step 1:** Write failing test — `ensureFormDefinition` called with token identity id when JWT has `identity_id` distinct from violation owner
- [ ] **Step 2:** Write failing test — offline invoke (no apiUrl/token) passes `offline-owner` to `ensureFormDefinition`
- [ ] **Step 3:** Import `resolveTokenIdentity` from `../framework`; compute `definitionOwnerId` and `definitionOwnerSource` before `ensureFormDefinition`
- [ ] **Step 4:** Replace `violation.owner.id` argument with `definitionOwnerId`
- [ ] **Step 5:** Extend `logSodRemediationFormDefinition` signature and log output
- [ ] **Step 6:** Run `npm test -- sod-remediation-operation sod-remediation-logging` — PASS

---

## Task 2: Update existing form definition create test

**Files:**
- Modify: `src/operations/sod-remediation-operation.spec.ts`

- [ ] **Step 1:** Update `creates form definition from seed when missing` test — expect token identity id (from mock JWT helper), not `owner-default`
- [ ] **Step 2:** Provide mock JWT in `workflowConfig.token` with known `identity_id` claim (reuse pattern from `source-provisioning.spec.ts`)
- [ ] **Step 3:** Run `npm test -- sod-remediation-operation` — PASS

---

## Task 3: Remove debug agent instrumentation

**Files:**
- Modify: `src/operations/sod-remediation-operation.ts`
- Modify: `src/isc/sod-form-service.ts`
- Modify: `src/isc/experimental-client.ts`
- Modify: `src/isc/identity-access-client.ts`
- Modify: `src/framework/sdk-factory.ts`

- [ ] **Step 1:** Delete all `#region agent log` / `#endregion` blocks and associated `fetch('http://127.0.0.1:7830/...')` calls
- [ ] **Step 2:** In `sod-form-service.ts`, simplify `logFormApiError` to remove ingest fetch (keep throw/rethrow behavior)
- [ ] **Step 3:** Grep repo for `127.0.0.1:7830` — confirm zero matches
- [ ] **Step 4:** Run `npm test` — PASS

---

## Task 4: Documentation

**Files:**
- Modify: `README.md`

- [ ] **Step 1:** In SOD remediation section, document that form definition owner on create = access token identity; note recipient `owner` override is separate
- [ ] **Step 2:** Run `npm test` — PASS (sanity)

---

## Verification checklist

- [ ] `ensureFormDefinition` receives token identity on online create
- [ ] Form instance recipient still uses violation owner / `input.owner` override
- [ ] No debug ingest fetch calls remain
- [ ] `npm test` passes with coverage thresholds
