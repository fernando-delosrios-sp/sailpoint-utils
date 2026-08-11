## Context

The connector separates `src/framework/` (orchestration, persist, SDK factory), `src/isc/` (generic ISC integration), and `src/operations/` (command handlers). The `normalize-isc-client-layout` change established mandatory per-API subdirectories under `src/isc/`, but AccountsApi code remained in `persist-result.ts` because persist was the only consumer at the time.

Account functionality in ISC spans two APIs: `SourcesApi` for account **schemas** (already in `isc/sources/`) and `AccountsApi` for account **instances**. This change completes the layout rule for the latter without altering persist semantics.

## Goals / Non-Goals

**Goals:**
- Add `src/isc/accounts/` with thin `AccountsApi` wrappers and native-identity lookup
- Refactor `persist-result.ts` to delegate lookup/CRUD to `isc/accounts`
- Add `target-client/accounts` OpenSpec sub-capability; update root layout requirement
- All existing tests pass; persist behavior unchanged

**Non-Goals:**
- Moving account schema helpers out of `sources/`
- Moving TaskManagementApi task polling out of framework
- Changing `ctx.persist` verification, retry, or attribute formatting policy
- New account features beyond relocating existing logic
- `connector-spec.json` changes

## Decisions

### D1: accounts/ for AccountsApi instance operations only
- **Choice:** `src/isc/accounts/` wraps `AccountsApi`; account schema stays in `src/isc/sources/`.
- **Rationale:** Mirrors ISC API boundaries; avoids conflating schema and instance concerns.
- **Alternative rejected:** Single "accounts" module covering SourcesApi schemas — wrong API client.

### D2: Extract lookup and CRUD; keep persist policy in framework
- **Choice:** Move `findAccountOnSource`, `escapeODataString`, and thin get/list/create/put wrappers to isc. Keep `upsertSourceAccount`, task resolution, verification, and attribute building in framework.
- **Rationale:** Lookup filters and SDK pass-through are reusable; upsert orchestration and cross-API task wait are persist policy.
- **Alternative rejected:** Move entire persist-result account section to isc — leaks framework policy into shared layer.

### D3: findAccountOnSource is generic isc surface
- **Choice:** Export `findAccountOnSource` from `isc/accounts` with multi-filter OData strategy and paginated source scan (existing behavior).
- **Rationale:** Operations may need account lookup without importing framework; logic is not persist-specific.
- **Alternative rejected:** Simplify lookup to single filter — would change persist behavior.

### D4: Barrel index.ts per layout rule
- **Choice:** `src/isc/accounts/index.ts` exports public lookup, CRUD, types, and `escapeODataString`.
- **Rationale:** Matches D4 from normalize-isc-client-layout; stable import paths for consumers.
- **Alternative rejected:** Deep imports only — inconsistent with other isc modules.

### D5: OpenSpec sub-capability target-client/accounts
- **Choice:** New delta spec for AccountsApi boundary; modify root target-client layout scenario to include `accounts`.
- **Rationale:** Spec tree predicts code location; archive promotes to main specs.
- **Alternative rejected:** Document accounts only in framework spec — misses isc layer contract.

## Module layout

```
src/isc/accounts/
  account-client.ts      # getAccount, createAccount, putAccount, listAccounts
  find-account.ts        # findAccountOnSource, escapeODataString, internal scan helpers
  types.ts               # SourceAccountMatch and shared types
  index.ts               # barrel
  account-client.spec.ts # unit tests
```

Framework imports from `../isc/accounts` for lookup/CRUD; continues to own `upsertSourceAccount`, task polling, verification.

## Risks / Trade-offs

- [Risk] Missed import after extraction → Mitigation: `npm test`, grep for direct AccountsApi usage outside isc/accounts and sdk-factory
- [Risk] Circular dependency framework ↔ isc → Mitigation: isc/accounts MUST NOT import from framework
- [Trade-off] `findAccountOnSource` is non-trivial for a "thin" module — accepted as generic reusable lookup, not persist policy

## Migration Plan

1. Create `isc/accounts/` modules and tests (copy behavior from persist-result.ts)
2. Update `persist-result.ts` to import from isc/accounts
3. Adjust persist-result.spec.ts — move lookup-specific tests to accounts.spec.ts where appropriate
4. Write spec deltas; run `npm test` and `npm run build`
5. Optional README note: schemas in sources/, instances in accounts/

Rollback: revert commit; no tenant data migration.

## Open Questions

- None blocking — scope and API split confirmed in brainstorm.
