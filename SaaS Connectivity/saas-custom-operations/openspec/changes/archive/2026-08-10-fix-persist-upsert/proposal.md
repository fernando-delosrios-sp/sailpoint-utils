## Why

`ctx.persist` is documented as upsert semantics, but the implementation always calls `createAccountV1`. When a result account already exists — common when re-running local debug with the same `requestId` or retrying after a partial failure — the write fails or leaves stale attributes. That blocks reliable debug iteration and violates the spec scenario "Persist upserts duplicate identity." Fixing persist to update existing accounts via `putAccountV1` closes the gap between documented behavior and runtime behavior.

## What Changes

**Persist write path (create vs update)**
- From: Every persist invokes `createAccountV1` regardless of whether the identity already exists on the result source.
- To: Probe for an existing account by native identity; call `createAccountV1` when absent, `putAccountV1` when present (using the ISC account UUID from list).
- Reason: Duplicate create does not reliably overwrite existing dummy accounts; update API is the supported path.
- Impact: Non-breaking for first-time persists; fixes re-persist and debug re-run behavior.

**Spec alignment**
- From: Upsert scenario references "account create" generically.
- To: Scenario explicitly requires `putAccountV1` for existing identities and `createAccountV1` for new ones.
- Reason: Testable contract matching ISC API semantics.
- Impact: Spec-level clarification; no manifest change.

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `custom-operation-framework`: Update Result persistence helper requirement and upsert scenario to define probe-first create-or-update behavior.
- `target-client`: Update Accounts client persist scenario to include account update via `putAccountV1`.

## Impact

- **Code:** `src/framework/persist-result.ts`, `src/framework/types.ts`, `src/framework/request-context.ts`, `src/framework/persist-result.spec.ts`, possibly `src/framework/with-custom-operation.spec.ts` stub updates
- **APIs:** ISC `AccountsApi.listAccountsV1`, `createAccountV1`, `putAccountV1` via existing `sailpoint-api-client` dependency
- **Docs:** README persist/upsert section; CHANGELOG entry
- **Systems:** No connector-spec.json, workflow, or tenant config changes
