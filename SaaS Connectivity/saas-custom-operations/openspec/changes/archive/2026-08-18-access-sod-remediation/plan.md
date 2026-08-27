# Access SOD Remediation Operation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `custom:access-sod-remediation` — scan enabled roles/access profiles in scope, detect intrinsic SoD violations via policy query intersection, launch policy-owner remediation forms, and persist parent rollup + per-form child accounts.

**Architecture:** New `src/isc/sod-policies/` module (list/get policies, parse `policyQuery`, owner resolution). Extend roles/access-profiles with paginated enabled listing. Operation orchestrates discovery → expansion → violation detection → form launch with idempotency. Parent persist on `requestId`; child persist on `` `${requestId}:${accessItemId}:${policyId}` ``. No SoD predict API.

**Tech Stack:** TypeScript, Vitest, `@sailpoint/connector-sdk`, `sailpoint-api-client`

## Global Constraints

- Canonical test command: `npm test`
- Build command: `npm run build`
- Codegen command: `npm run codegen:schemas` (registers new command)
- Integration validation: `npm run build` + optional `spcx` pack after implementation
- Operation input: `formName` (required), optional `scope` (default `"*"`), `searchIndices` (default `['accessprofiles','roles']`), `policyScope` (default `state eq "ENFORCED"`)
- Parent output: `access-sod-remediation:access-items-scanned`, `access-sod-remediation:violations-found`, optional `access-sod-remediation:forms-skipped` — NO `forms-created`
- Child output per form: `access-sod-remediation:form-url`, access item fields, policy fields, `recipient-id`
- Form cap: 100 instances per invocation
- Evaluation: policyQuery AND-between-sides; entitlement ids only in group lists

**Spec references:** `openspec/changes/access-sod-remediation/specs/connector-operations/access-sod-remediation/spec.md`, `openspec/changes/access-sod-remediation/specs/target-client/*.md`

**Design references:** `openspec/changes/access-sod-remediation/design.md` §D1–D12

---

## Task 1: SDK sod-policies client

**Files:**
- Modify: `src/framework/types.ts`
- Modify: `src/framework/sdk-factory.ts`
- Modify: `src/framework/request-context.ts` (offline stubs)

- [ ] **Step 1:** Write failing test — sdk-factory exposes sodPolicies client
- [ ] **Step 2:** Wire SodPolicies API (or HTTP wrapper) in sdk-factory
- [ ] **Step 3:** Update offline stubs
- [ ] **Step 4:** Run `npm test -- sdk-factory` — PASS

---

## Task 2: sod-policies isc module

**Files:**
- Create: `src/isc/sod-policies/index.ts`
- Create: `src/isc/sod-policies/list-policies.ts`
- Create: `src/isc/sod-policies/get-policy.ts`
- Create: `src/isc/sod-policies/parse-policy-query.ts`
- Create: `src/isc/sod-policies/resolve-policy-sides.ts`
- Create: `src/isc/sod-policies/resolve-policy-owner.ts`
- Create: `src/isc/sod-policies/offline-data.ts`
- Create: `src/isc/sod-policies/sod-policies.spec.ts`

- [ ] **Step 1:** Write failing tests — parse `@access(id:a OR id:b) AND @access(id:c OR id:d)`
- [ ] **Step 2:** Write failing tests — criteria fallback, unresolvable skip, owner extraction
- [ ] **Step 3:** Implement modules with mocked client and offline fixtures
- [ ] **Step 4:** Run `npm test -- sod-policies` — PASS

---

## Task 3: roles and access-profiles listing

**Files:**
- Create: `src/isc/roles/list-enabled-roles.ts`
- Create: `src/isc/access-profiles/list-enabled-access-profiles.ts`
- Extend: respective `index.ts`, offline data, spec files

- [ ] **Step 1:** Write failing tests — paginated enabled list, scope filter, offline
- [ ] **Step 2:** Implement list helpers
- [ ] **Step 3:** Run `npm test -- roles access-profiles` — PASS

---

## Task 4: Violation detection and expansion

**Files:**
- Create: `src/operations/access-sod-remediation/expand-access-item-entitlements.ts`
- Create: `src/operations/access-sod-remediation/detect-violations.ts`
- Create: `src/operations/access-sod-remediation/detect-violations.spec.ts`

- [ ] **Step 1:** Write failing tests — role with nested AP, intersection both sides, no violation one side
- [ ] **Step 2:** Implement expansion + detection
- [ ] **Step 3:** Run `npm test -- detect-violations` — PASS

---

## Task 5: Form seed and form service

**Files:**
- Create: `src/operations/access-sod-remediation/seed/access-sod-remediation.seed.json`
- Create: `src/operations/access-sod-remediation/form-service.ts`
- Create: `src/operations/access-sod-remediation/group-html.ts`
- Create: `src/operations/access-sod-remediation/form-service.spec.ts`

- [ ] **Step 1:** Write failing tests — formInput fields, entitlement-only group ids, idempotency skip
- [ ] **Step 2:** Implement ensure + instance create (reuse `src/isc/forms/` helpers)
- [ ] **Step 3:** Run `npm test -- form-service` — PASS

---

## Task 6: Operation handler

**Files:**
- Create: `src/operations/access-sod-remediation/index.ts`
- Create: `src/operations/access-sod-remediation/offline-data.ts`
- Create: `src/operations/access-sod-remediation/index.spec.ts`
- Create: `src/operations/access-sod-remediation/README.md`
- Generated: schema, auto-registry, connector-spec.json

- [ ] **Step 1:** Write failing tests — parent rollup, child persist identity pattern, offline happy path
- [ ] **Step 2:** Write failing tests — searchIndices validation, 100-form cap, forms-skipped counter
- [ ] **Step 3:** Implement handler orchestration
- [ ] **Step 4:** Run `npm run codegen:schemas`
- [ ] **Step 5:** Add payload + call-op registration
- [ ] **Step 6:** Run `npm test -- access-sod-remediation` — PASS

---

## Task 7: Documentation and changelog

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md` (via changelog-generator skill)

- [ ] **Step 1:** Document parent/child Get Accounts pattern in README and operation README
- [ ] **Step 2:** Run full `npm test` — PASS
- [ ] **Step 3:** Run `npm run build` — PASS
- [ ] **Step 4:** Update CHANGELOG via changelog-generator skill

---

## Commit guidance

- Commit SDK + sod-policies module separately
- Commit roles/access-profiles listing separately
- Commit violation detection + form service
- Commit operation handler + codegen outputs together
- Commit docs/CHANGELOG last

## PRECHECK (apply phase)

Before live tenant spike (optional):
- Confirm Sod Policies list/get API paths and filter syntax for `policyScope`
- Confirm Roles/Access Profiles list filter for `enabled eq true`
- Confirm policy `ownerRef` types in tenant (IDENTITY vs GOVERNANCE_GROUP)
- Confirm PAT scopes for sod-policies, roles, access-profiles, custom forms
