## Context

The connector uses Vitest co-located `*.spec.ts` files across `src/isc/`, `src/operations/`, and `src/framework/`. `sod-remediation/offline-data.ts` exported canned entities used at runtime and could be mistaken for test infrastructure. Identity-access needed a clearer split between SDK orchestration and runtime offline lookup. The majority pattern — inline `vi.fn()` mocks and literal objects inside specs — is easier to read and maintain.

## Goals / Non-Goals

**Goals:**

- Encode a project convention: Vitest fixtures live in `*.spec.ts`, not dedicated test-fixture sibling modules
- Remove `sod-remediation/offline-data.ts`; co-locate SOD offline violation in the operation handler
- Keep identity-access runtime offline data in dedicated `offline-data.ts`, separate from `fetch-identity-access-items.ts`
- Preserve runtime offline invoke behavior for identity access and SOD remediation
- Keep existing spec scenarios passing under `npm test`

**Non-Goals:**

- Removing identity-access runtime offline invoke support
- Changing offline vs connected invoke semantics or payload formats
- Introducing shared test utility packages or `__fixtures__` directories
- Altering connector-spec.json or std command handlers

## Decisions

### D1: Inline unit-test fixtures in spec files

- **选择:** All mock responses, stub entities, and `expect` literals for Vitest tests SHALL be defined in the co-located `*.spec.ts` file (module-level constants, `beforeEach`, or inline in `it` blocks).
- **理由:** Matches established isc/http/violations patterns; removes indirection.
- **已考虑 alternative:** Shared `test/fixtures/` directory — rejected; centralizes unrelated data and encourages cross-test coupling.

### D2: Split identity-access runtime offline from orchestration

- **选择:** Keep `fetchIdentityAccessItemsOffline` and its lookup map in `src/isc/identity-access/offline-data.ts`. SDK orchestration lives in `fetch-identity-access-items.ts` (renamed from `fetch-from-sdk.ts`).
- **理由:** Runtime offline invoke data is production code, not Vitest infrastructure; separating it from orchestration clarifies module boundaries without conflating offline-data with test fixtures.
- **已考虑 alternative:** Inline offline lookup into orchestration file — rejected; mixes two production concerns in one module.

### D3: Co-locate SOD offline violation in operation handler

- **选择:** Move `OFFLINE_VIOLATION` into `src/operations/sod-remediation/index.ts` as a module-private constant; delete `sod-remediation/offline-data.ts`.
- **理由:** Operation-specific offline stub belongs with the handler; eliminates an extra file that read like test infrastructure.
- **已考虑 alternative:** Share violation stub via isc violations module — rejected; stub is operation-specific for local invoke.

### D4: Operation specs mock isc deps inline

- **选择:** `sod-remediation/index.spec.ts` continues to `vi.mock` isc modules; offline identity id assertions use inline string literals, not imports from fixture modules.
- **理由:** Operation tests already mock `fetchIdentityAccessItemsOffline`; no fixture file needed.

### D5: Spec capability deltas

- **选择:** Add testing convention requirements under `custom-operation-framework`; document offline-data vs orchestration split under `target-client/identity-access`.
- **理由:** Reuses existing capability taxonomy; avoids a one-off `test-fixtures` capability.

## Risks / Trade-offs

- [Risk] Duplicated object shapes between runtime stubs and spec literals → Mitigation: acceptable; different layers; specs assert via inline literals not shared constants
- [Risk] `offline-data.ts` name still resembles test infrastructure → Mitigation: spec documents it as runtime-only; specs must not import it for fixtures
- [Trade-off] Two identity-access implementation files instead of one → Accept: clearer separation of offline lookup vs SDK orchestration

## Migration Plan

1. Rename `fetch-from-sdk.ts` to `fetch-identity-access-items.ts`; keep offline lookup in `offline-data.ts`.
2. Move `OFFLINE_VIOLATION` into `sod-remediation/index.ts`; delete `sod-remediation/offline-data.ts`.
3. Ensure `identity-access.spec.ts` uses inline expected literals; imports production API via `./index` only.
4. Run `npm test` and offline payload smoke invoke.
5. Rollback: restore deleted sod-remediation offline-data from git if offline invoke regresses.

N/A — no deployment, database, or connector manifest changes.

## Open Questions

_(none)_
