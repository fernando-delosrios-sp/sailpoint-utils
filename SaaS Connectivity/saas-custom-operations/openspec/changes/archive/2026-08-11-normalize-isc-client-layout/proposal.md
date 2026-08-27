## Why

The ISC integration layer under `src/isc/` grew inconsistently after `operation-layer-boundaries`: some API surfaces use subfolders (`forms/`, `sources/`) while others remain flat single files that mix unrelated SDK clients (`identity-access-client.ts`) or unrelated REST APIs (`isc-client.ts`). Without a documented layout rule, each new operation risks polluting the shared layer and OpenSpec sub-specs no longer predict code location. Normalizing now — before more operations land — keeps ISC helpers discoverable and enforces one API client per module.

## What Changes

**ISC module layout**
- From: Mixed flat files and subfolders under `src/isc/`; no normative layout requirement
- To: Mandatory `src/isc/<api-grouping>/` per ISC API surface; flat client files at `src/isc/` root disallowed
- Reason: Uniform scaling and clear promotion boundaries
- Impact: Non-breaking refactor — import paths change; runtime behavior unchanged

**Identity access API separation**
- From: `identity-access-client.ts` combines IdentityHistoryApi, AccessProfilesApi, and RolesApi
- To: `identity-history/`, `access-profiles/`, `roles/` thin wrappers; `identity-access/` orchestrates only
- Reason: Spec and code should enforce separation by API
- Impact: Non-breaking — same public orchestration functions, different module paths

**Pre-SDK API separation**
- From: Violations and controls in flat `isc-client.ts` (or grouped under `experimental/`)
- To: `violations/` and `controls/` subdirectories; shared GET transport in `http/`
- Reason: Do not group unrelated APIs under an umbrella folder
- Impact: Non-breaking — same HTTP endpoints and headers

**Token identity**
- From: Flat `src/isc/token-identity.ts`
- To: `src/isc/token-identity/token-identity.ts`
- Reason: Consistent subfolder pattern for future helpers
- Impact: Non-breaking

**OpenSpec target-client capabilities**
- From: Root spec holds pre-SDK HTTP; single `identity-access` sub-spec without per-API siblings
- To: Layout requirement in root spec; new sub-specs for identity-history, access-profiles, roles, violations, controls; identity-access spec scoped to orchestration
- Reason: Spec tree mirrors code tree
- Impact: Spec-only alignment; no connector contract change

## Capabilities

### New Capabilities

- `target-client/identity-history`: IdentityHistoryApi wrappers for assigned access item listing
- `target-client/access-profiles`: AccessProfilesApi wrappers for access profile entitlement listing
- `target-client/roles`: RolesApi wrappers for role entitlement listing
- `target-client/violations`: Pre-SDK violations API wrappers
- `target-client/controls`: Pre-SDK controls API wrappers

### Modified Capabilities

- `target-client`: Add ISC module layout requirement; relocate token-identity path; remove root pre-SDK HTTP requirement (moved to sub-capabilities)
- `target-client/identity-access`: Require orchestration-only module delegating to per-API isc modules

## Impact

- **Code:** Restructure `src/isc/` — move/delete flat files; add API subfolders; update imports in `src/operations/sod-remediation/`, `src/framework/`
- **Tests:** Relocate and extend unit tests per API subdirectory
- **Docs:** README layout section; inline paths in target-client specs
- **Out of scope:** `connector-spec.json`, custom operation input/output contracts, SDK factory location
