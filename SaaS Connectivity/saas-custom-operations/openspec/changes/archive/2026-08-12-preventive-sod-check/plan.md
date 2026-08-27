# Preventive SOD Check Operation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `custom:preventive-sod-check` — evaluates executing GRANT_ACCESS requests for an identity via ISC SoD prediction and persists namespaced `preventive-sod-check:situation-summary` and `preventive-sod-check:violated-policy-names` outputs.

**Architecture:** Extend `ctx.sdk` with AccessRequestsApi, SearchApi, and SODViolationsApi. New isc modules under `access-requests/`, `events-search/`, and `sod-prediction/` wrap API calls; entitlement expansion reuses existing roles/access-profiles clients. Operation handler orchestrates pending-grant discovery, events retry, predict, and plain-text summary builder. Optional `accessRequestId` affects summary narrative only.

**Tech Stack:** TypeScript, Vitest, `@sailpoint/connector-sdk`, `sailpoint-api-client`

## Global Constraints

- Canonical test command: `npm test`
- Build command: `npm run build`
- Codegen command: `npm run codegen:schemas` (registers new command)
- Integration validation: `npm run build` + optional `spcx` pack after implementation
- Operation input: `identityId` (required), optional `accessRequestId`
- Operation output (persisted): `preventive-sod-check:situation-summary`, `preventive-sod-check:violated-policy-names` only — NO `approved` field
- Summary rules: no violations → `"No violations found"`; violations without accessRequestId → list policies; with accessRequestId → attribute to request; violated-policy-names always full set

**Spec references:** `openspec/changes/preventive-sod-check/specs/connector-operations/preventive-sod-check/spec.md`, `openspec/changes/preventive-sod-check/specs/target-client/*.md`

**Design references:** `openspec/changes/preventive-sod-check/design.md` §D1–D10

---

## Task 1: SDK client extensions

**Files:**
- Modify: `src/framework/types.ts`
- Modify: `src/framework/sdk-factory.ts`
- Modify: `src/framework/request-context.ts` (offline stubs)
- Create: `src/framework/sdk-factory.spec.ts` (extend if exists)

- [ ] **Step 1:** Write failing test — `createSailPointClients` returns `accessRequests`, `search`, `sodViolations`
- [ ] **Step 2:** Import and wire `AccessRequestsApi`, `SearchApi`, `SODViolationsApi` in sdk-factory
- [ ] **Step 3:** Extend `SailPointClients` type; update offline request-context stubs with no-op methods
- [ ] **Step 4:** Run `npm test -- sdk-factory` — PASS

---

## Task 2: Access-requests isc module

**Files:**
- Create: `src/isc/access-requests/index.ts`
- Create: `src/isc/access-requests/list-executing-grants.ts`
- Create: `src/isc/access-requests/offline-data.ts`
- Create: `src/isc/access-requests/access-requests.spec.ts`

- [ ] **Step 1:** Write failing test — lists EXECUTING requests for identity via `listAccessRequestStatusV1`
- [ ] **Step 2:** Write failing test — filters to GRANT_ACCESS only
- [ ] **Step 3:** Write failing test — offline helper returns canned executing grant
- [ ] **Step 4:** Implement list + filter helpers with mocked AccessRequestsApi
- [ ] **Step 5:** Run `npm test -- access-requests` — PASS

---

## Task 3: Events-search isc module

**Files:**
- Create: `src/isc/events-search/index.ts`
- Create: `src/isc/events-search/search-events.ts`
- Create: `src/isc/events-search/extract-access-items.ts`
- Create: `src/isc/events-search/offline-data.ts`
- Create: `src/isc/events-search/events-search.spec.ts`

- [ ] **Step 1:** Write failing test — `searchEventsByTrackingNumber` queries `events` index
- [ ] **Step 2:** Write failing test — retry succeeds on second attempt
- [ ] **Step 3:** Write failing test — retry returns empty after max attempts without throw
- [ ] **Step 4:** Write failing test — `extractAccessItemsFromEvents` dedupes ENTITLEMENT/ROLE/ACCESS_PROFILE refs
- [ ] **Step 5:** Implement search, retry wrapper, extractor; add offline fixtures
- [ ] **Step 6:** Run `npm test -- events-search` — PASS

---

## Task 4: Sod-prediction isc module

**Files:**
- Create: `src/isc/sod-prediction/index.ts`
- Create: `src/isc/sod-prediction/predict-violations.ts`
- Create: `src/isc/sod-prediction/expand-entitlements.ts`
- Create: `src/isc/sod-prediction/parse-policy-names.ts`
- Create: `src/isc/sod-prediction/offline-data.ts`
- Create: `src/isc/sod-prediction/sod-prediction.spec.ts`

- [ ] **Step 1:** Write failing test — `predictSodViolationsForIdentity` posts IdentityWithNewAccess with ENTITLEMENT refs
- [ ] **Step 2:** Write failing test — `parseViolatedPolicyNames` extracts policy names from ViolationPrediction
- [ ] **Step 3:** Write failing test — `expandAccessItemsToEntitlementIds` expands ROLE and ACCESS_PROFILE via existing isc modules
- [ ] **Step 4:** Write failing test — zero entitlements skips predict call
- [ ] **Step 5:** Write failing test — API failure throws ConnectorError
- [ ] **Step 6:** Implement modules with mocked SDK clients and offline fixtures
- [ ] **Step 7:** Run `npm test -- sod-prediction` — PASS

---

## Task 5: Situation summary builder

**Files:**
- Create: `src/operations/preventive-sod-check/situation-summary.ts`
- Create: `src/operations/preventive-sod-check/situation-summary.spec.ts`

- [ ] **Step 1:** Write failing test — empty policies → `"No violations found"`
- [ ] **Step 2:** Write failing test — policies without accessRequestId → lists all policy names
- [ ] **Step 3:** Write failing test — policies with accessRequestId → attributes request in text
- [ ] **Step 4:** Implement `buildPreventiveSituationSummary({ violatedPolicyNames, accessRequestId? })`
- [ ] **Step 5:** Run `npm test -- situation-summary` — PASS

---

## Task 6: Preventive-sod-check operation handler

**Files:**
- Create: `src/operations/preventive-sod-check/index.ts`
- Create: `src/operations/preventive-sod-check/pending-grants.ts`
- Create: `src/operations/preventive-sod-check/offline-data.ts`
- Create: `src/operations/preventive-sod-check/index.spec.ts`
- Create: `src/operations/preventive-sod-check/README.md`
- Generated: `src/operations/preventive-sod-check/index.schema.ts`, `auto-registry.ts`, `connector-spec.json`

- [ ] **Step 1:** Write failing test — handler persists namespaced outputs on happy path (offline)
- [ ] **Step 2:** Write failing test — no executing grants → `"No violations found"` and empty policy array
- [ ] **Step 3:** Write failing test — optional accessRequestId changes summary but not policy array
- [ ] **Step 4:** Write failing test — output contract excludes `approved`
- [ ] **Step 5:** Implement orchestration in `pending-grants.ts` and handler in `index.ts`
- [ ] **Step 6:** Run `npm run codegen:schemas`; commit generated registry + manifest
- [ ] **Step 7:** Register payload in `scripts/call-op.ts`; add `payloads/preventive-sod-check.json`
- [ ] **Step 8:** Run `npm test -- preventive-sod-check` — PASS

---

## Task 7: Documentation and changelog

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md` (via changelog-generator skill)

- [ ] **Step 1:** Document invoke payload, persisted output fields, and workflow branching pattern in README and operation README
- [ ] **Step 2:** Run full `npm test` — PASS
- [ ] **Step 3:** Run `npm run build` — PASS
- [ ] **Step 4:** Update CHANGELOG via changelog-generator skill

---

## Commit guidance

- Commit SDK extensions separately
- Commit each isc module (access-requests, events-search, sod-prediction) separately
- Commit situation-summary builder
- Commit operation handler + codegen outputs together
- Commit docs/CHANGELOG last

## PRECHECK (apply phase)

Before live tenant spike (optional):
- Confirm events index query field for tracking number
- Confirm retry defaults (propose 3–5 attempts, 1–2s backoff)
- Confirm PAT scopes for access request status, search, and sod predict endpoints
