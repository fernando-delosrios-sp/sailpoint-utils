## Why

Dedicated `offline-data.ts` files and sibling test-fixture modules blur Vitest unit-test data with runtime offline invoke stubs. Most isc specs already inline mocks and expected values in `*.spec.ts`, but operation-level `offline-data.ts` files made the layout inconsistent. This change standardizes Vitest fixtures inline in spec files, removes operation-level offline-data extraction, and keeps identity-access runtime offline data in a dedicated module separate from SDK orchestration.

## What Changes

**Vitest fixture placement**
- From: sibling files imported primarily by `*.spec.ts` for mock data
- To: mock return values, stub entities, and expected payloads defined inline in co-located `*.spec.ts` files
- Reason: tests should be self-contained narratives matching `violations.spec.ts` and `list-assigned-access-items.spec.ts`
- Impact: non-breaking; affects test authoring convention only

**Runtime offline stub placement**
- From: `src/operations/sod-remediation/offline-data.ts` exporting canned violation data
- To: `OFFLINE_VIOLATION` as module-private constant in `sod-remediation/index.ts`
- Reason: operation offline stub belongs with the handler that consumes it
- Impact: non-breaking for offline payloads; one source file removed

**Identity-access module layout**
- From: mixed orchestration and offline lookup in overlapping files
- To: SDK orchestration in `fetch-identity-access-items.ts`; runtime offline lookup in dedicated `offline-data.ts`
- Reason: separates production offline invoke data from SDK loopback logic without using offline-data as a Vitest fixture module
- Impact: non-breaking; `fetch-from-sdk.ts` renamed to `fetch-identity-access-items.ts`

**Project testing convention**
- From: no explicit rule forbidding test-fixture sibling files
- To: documented requirement that unit tests SHALL NOT rely on dedicated fixture modules
- Reason: prevent Vitest-only `fixtures.ts` / `test-data.ts` patterns
- Impact: affects future contributions only

## Capabilities

### New Capabilities

_(none — convention encoded as a delta on an existing capability)_

### Modified Capabilities

- `custom-operation-framework`: add Vitest unit-test fixture placement requirements
- `target-client/identity-access`: clarify offline stub module vs orchestration file split (behavior unchanged)

## Impact

- **Removed:** `src/operations/sod-remediation/offline-data.ts`, `src/isc/identity-access/fetch-from-sdk.ts` (renamed)
- **Added:** `src/isc/identity-access/fetch-identity-access-items.ts`
- **Retained:** `src/isc/identity-access/offline-data.ts` (runtime offline invoke only)
- **Modified:** `src/operations/sod-remediation/index.ts`, related `*.spec.ts` files, `openspec/specs/` deltas
- **Unchanged:** offline invoke payloads, connector-spec.json, ISC API contracts, coverage thresholds
- **Verification:** `npm test`; smoke `npm run call:op -- payloads/sod-remediation-offline.json`
