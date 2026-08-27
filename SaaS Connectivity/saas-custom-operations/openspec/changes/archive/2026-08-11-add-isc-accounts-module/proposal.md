## Why

After normalizing ISC client layout, account instance operations remain embedded in `src/framework/persist-result.ts` while every other `sailpoint-api-client` surface has a dedicated `src/isc/<api-grouping>/` module. Account schema helpers correctly live under `sources/` (SourcesApi), but AccountsApi wrappers — lookup by native identity, create, put, get, list — are mixed with persist orchestration (task polling, verification, attribute formatting). This breaks the layout rule, hides reusable account APIs from operations, and leaves no `target-client/accounts` spec to guide extenders. Extracting a thin `isc/accounts/` module now completes the layout normalization without changing persist behavior.

## What Changes

**ISC accounts module**
- From: AccountsApi call sites and lookup helpers live in `persist-result.ts`
- To: `src/isc/accounts/` with thin wrappers and `findAccountOnSource`; barrel `index.ts`
- Reason: Align AccountsApi with per-API subdirectory rule established by normalize-isc-client-layout
- Impact: Non-breaking refactor — persist behavior unchanged; import paths change

**Framework persist delegation**
- From: `persist-result.ts` calls `AccountsApi` directly for lookup and upsert primitives
- To: Framework imports account lookup/CRUD from `isc/accounts`
- Reason: Separate generic API boundary from persist policy
- Impact: Non-breaking — same runtime persist semantics

**OpenSpec target-client alignment**
- From: Root layout scenario lists API folders without `accounts`; no accounts sub-spec
- To: `accounts` added to layout requirement; new `target-client/accounts` sub-capability
- Reason: Spec tree mirrors code tree
- Impact: Spec-only addition plus minor root spec update

**Account schema unchanged**
- From: Schema helpers in `src/isc/sources/`
- To: Unchanged — SourcesApi boundary preserved
- Reason: ISC models account schemas on sources, not AccountsApi
- Impact: None

## Capabilities

### New Capabilities

- `target-client/accounts`: Generic AccountsApi wrappers for account get, list, create, put, and native-identity lookup on a source

### Modified Capabilities

- `target-client`: Add `accounts` to ISC module layout and barrel entry scenarios
- `custom-operation-framework`: Persist helper SHALL delegate AccountsApi primitives to `isc/accounts` (no externally observable behavior change)

## Impact

- **Code:** New `src/isc/accounts/` module; refactor `src/framework/persist-result.ts` to import from it; update `persist-result.spec.ts` imports
- **Tests:** New `accounts.spec.ts`; existing persist tests remain green
- **Docs:** Optional README layout note for `accounts/` vs `sources/` schema split
- **Out of scope:** `connector-spec.json`, custom operation I/O contracts, TaskManagementApi task polling location, account schema functions in sources
