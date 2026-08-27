# Plan: sod-remediation-keep-recommendations

> **For agentic workers:** Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Replace connector revoke stars with ISC keep recommendations, named grantor copy, privileged badges, and asymmetric side correction hints in SOD remediation form/email HTML.

**Architecture:** New `isc/recommendations` client batches `getRecommendationsV1`; sod-remediation launch enriches resolved paths with keep + privileged metadata, computes side hint, and renders via extended label module. API failures degrade silently.

**Tech Stack:** TypeScript, `@sailpoint/connector-sdk`, `sailpoint-api-client` IAIRecommendationsApi, Vitest

**Test command:** `npm test`

---

## Task 1: Recommendations client

- [ ] **Step 1:** Write failing test — batch fetch maps YES/MAYBE/NOT_FOUND per item id+type
- [ ] **Step 2:** Implement `src/isc/recommendations/fetch-keep-recommendations.ts` using SDK + `IscClientConfig`
- [ ] **Step 3:** Add `offline-data.ts` canned responses; export from `index.ts`
- [ ] **Step 4:** Run `npm test -- isc/recommendations` — green

## Task 2: grantedVia and privileged metadata

- [ ] **Step 1:** Write failing test — entitlement line gets `grantedVia` with role name when expanded via role
- [ ] **Step 2:** Update `resolveAccessSide` to attach `grantedVia` on entitlement lines
- [ ] **Step 3:** Write failing test — privileged entitlement flagged from history API mock
- [ ] **Step 4:** Add `list-assigned-entitlements` (or extend identity-history) for privileged flag; offline samples
- [ ] **Step 5:** Run `npm test -- access-path-resolver` — green

## Task 3: Merge keep recommendations and side hint

- [ ] **Step 1:** Write failing test — YES item gets `keepRecommendation: 'YES'`; MAYBE does not count for side logic
- [ ] **Step 2:** Add launch orchestration: batch recommendations after path resolve; catch errors → empty map
- [ ] **Step 3:** Write failing tests for side algorithm (A-only YES → correct B, symmetric → null, API fail → null)
- [ ] **Step 4:** Implement `computeRecommendedSideToCorrect(groupA, groupB)`
- [ ] **Step 5:** Remove setting `recommended: true` for display; keep `recommendedRevoke` in payload only

## Task 4: HTML labels and context

- [ ] **Step 1:** Write failing test — HTML shows “Not directly revocable (granted via X role)” and keep star only for YES
- [ ] **Step 2:** Update `revocability-labels.ts`: keep star copy, privileged 🔐, no connector revoke star
- [ ] **Step 3:** Write failing test — side hint appears in `buildSituationSummary` and formInput when asymmetric
- [ ] **Step 4:** Update `context.ts` / `assembleFormInput` with side hint + payload fields
- [ ] **Step 5:** Run full `npm test` — green; update CHANGELOG
