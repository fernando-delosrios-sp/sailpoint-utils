# Brainstorm: Add ISC accounts module

## Background

After `normalize-isc-client-layout`, `src/isc/` follows a one-subdirectory-per-ISC-API-surface rule (`forms/`, `sources/`, `roles/`, etc.). Account-related code is split inconsistently:

- **Account schema** (attributes, types, JSON Patch) lives in `src/isc/sources/source-client.ts` because ISC exposes schemas via `SourcesApi`.
- **Account instances** (`createAccountV1`, `putAccountV1`, `listAccountsV1`, `getAccountV1`) are embedded in `src/framework/persist-result.ts` alongside persist orchestration (task polling, verification, DelimitedFile retry policy).

There is no `target-client/accounts` OpenSpec sub-capability. The root `target-client/spec.md` lists expected ISC folders but omits `accounts`. `ctx.sdk.accounts` is wired in `sdk-factory.ts` only for framework persist — not as a reusable ISC module.

Developers adding account lookups outside persist have no discoverable home and must either duplicate OData filter logic or import from framework internals.

## Q1: Should accounts get its own `src/isc/accounts/` folder?

**Agreed: Yes** — `AccountsApi` is a distinct `sailpoint-api-client` surface and should follow the same layout rule as `sources/`, `roles/`, etc.

Account **schema** helpers remain under `sources/` (ISC API boundary). Account **instance** helpers move to `accounts/`.

**Rejected:** Leaving all AccountsApi code in `persist-result.ts` — violates layout rule and couples generic API wrappers to framework policy.

## Q2: What moves to `isc/accounts/` vs stays in framework?

**Agreed: Thin generic wrappers in isc; persist policy in framework.**

| Layer | Location | Responsibility |
|-------|----------|----------------|
| `isc/accounts/` | Generic | `getAccount`, `createAccount`, `putAccount`, `listAccounts`, `findAccountOnSource`, `escapeODataString`, shared types |
| `framework/persist-result.ts` | Policy | `buildAccountAttributes`, `formatAttributeValue`, `verifyPersistedAccount`, `upsertSourceAccount` orchestration, task wait via `TaskManagementApi`, read-back verification, `createPersist` |

**Rejected:** Moving `upsertSourceAccount` or task polling to isc — those encode result-source persist policy and cross API boundaries (Accounts + TaskManagement).

## Q3: Which functions to extract from persist-result.ts?

**Agreed:** Extract the lookup and CRUD thin wrappers currently inlined or exported for testing:

- `escapeODataString` — OData filter utility (used by lookup)
- `findAccountOnSource` — multi-filter + paginated scan lookup by native identity on a source
- New thin wrappers: `getAccount`, `createAccount`, `putAccount`, `listAccounts` — pass-through to `AccountsApi` with minimal response parsing

**Stays in framework:** `extractIscAccountIdFromProvisioningTask`, `waitForAccountProvisioningTask`, `resolveAccountAfterProvisioning`, `upsertSourceAccount`, attribute formatting, verification.

## Q4: How should OpenSpec align?

**Agreed:**

- New sub-capability: `target-client/accounts` — generic `AccountsApi` boundary requirements
- Modified: `target-client` root — add `accounts` to layout scenario list and barrel requirement
- Modified: `custom-operation-framework` — persist SHALL delegate account lookup/CRUD to `isc/accounts` (implementation detail; no behavior change)

**Rejected:** Merging accounts into `target-client/sources` — schema vs instance are different APIs.

## Q5: What stays unchanged?

- Runtime behavior of `ctx.persist` and verification
- Account schema functions in `src/isc/sources/`
- SDK factory location; `ctx.sdk.accounts` remains available
- `connector-spec.json` and custom operation I/O contracts
- No new ISC API integrations beyond relocating existing logic

## Trade-offs

- **Import churn in framework tests** — accepted; persist-result.spec.ts imports move to isc/accounts paths
- **findAccountOnSource complexity in isc layer** — accepted; it is generic lookup logic reusable outside persist, not persist-specific policy
- **Two places for "account"** — accepted; mirrors ISC API split (SourcesApi schemas vs AccountsApi instances)

## Open questions (resolved)

- Public exports: barrel `index.ts` re-exports lookup + CRUD + `escapeODataString` + `SourceAccountMatch` type
- Tests: new `accounts.spec.ts` for lookup filters and CRUD wrappers; persist tests remain in framework, mock isc/accounts or AccountsApi as today
