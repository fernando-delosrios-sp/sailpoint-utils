# Brainstorm: Inline spec test fixtures

## Background

The repo has two `offline-data.ts` modules:

- `src/isc/identity-access/offline-data.ts` — exports `fetchIdentityAccessItemsOffline` with canned access items
- `src/operations/sod-remediation/offline-data.ts` — exports `OFFLINE_VIOLATION` canned violation

Both serve **runtime offline invoke** (no `apiUrl`/`token`) and are imported by production handlers. They are also exercised directly in `identity-access.spec.ts` and indirectly referenced in `sod-remediation/index.spec.ts`.

Most other isc modules follow a cleaner pattern: mocks and expected values live inline in `*.spec.ts` (e.g. `violations.spec.ts`, `list-assigned-access-items.spec.ts`) via `vi.fn().mockResolvedValue({ ... })` and literal objects in `expect`.

The user request: **do not use extra files whose primary role is supporting Vitest `*.spec.ts` tests**, citing `offline-data.ts` as the anti-pattern.

## Q1: Scope — test-only files vs runtime offline stubs?

**Decision:** Separate concerns explicitly.

| Concern | Where data lives | Rationale |
|---|---|---|
| Vitest unit-test mocks/fixtures | Inline in the co-located `*.spec.ts` file | Keeps test intent local; matches existing isc/http/violations pattern |
| Runtime offline invoke stubs | Inline in the implementation module that consumes them (handler or isc module file), not a sibling `offline-data.ts` | Offline behavior remains for `npm run call:op` payloads without config; avoids a file that looks like test infrastructure |

Runtime offline is **not** removed — only the dedicated `offline-data.ts` extraction is removed.

## Q2: How should offline identity access work after refactor?

**Approach A (recommended):** Co-locate offline lookup map + `fetchIdentityAccessItemsOffline` in `fetch-from-sdk.ts` or a single `identity-access` implementation file; export from `index.ts`. Spec tests mock ISC clients inline (already done for SDK path) and use inline constants when asserting offline behavior via mocked deps in operation tests.

**Approach B:** Keep `fetchIdentityAccessItemsOffline` but move canned data into `index.ts` as private constants.

**Approach C:** Delete offline fetch entirely; operations hard-code stubs when `!config`.

**Choice:** A — preserves existing offline invoke contract from `target-client/identity-access` spec while eliminating the extra file.

## Q3: How should SOD offline violation work?

**Approach A (recommended):** Move `OFFLINE_VIOLATION` constant into `operations/sod-remediation/index.ts` (or `context.ts` if shared) as module-private constant; operation spec continues to mock isc imports inline.

**Approach B:** Share violation stub via isc violations module.

**Choice:** A — violation stub is operation-specific for local invoke; no cross-module test file.

## Q4: What convention gets encoded in specs?

Add or extend a **testing conventions** requirement (likely under `custom-operation-framework` or a focused delta on project conventions):

- Vitest `*.spec.ts` files SHALL define mock return values, stub entities, and expected payloads inline in the spec file (top-level `const`, `vi.fn()` setup, or `beforeEach` blocks).
- The project SHALL NOT add sibling `*-data.ts`, `fixtures.ts`, or `test-data.ts` files imported only (or primarily) by unit tests.
- Runtime offline invoke stubs are allowed but SHALL live in implementation modules, not dedicated test-fixture files.

## Trade-offs

| Pro | Con |
|---|---|
| Tests read as self-contained narratives | Slightly longer spec files |
| No ambiguity between test fixtures and runtime stubs | Runtime offline constants may duplicate shapes already in spec literals (acceptable — different purposes) |
| Aligns with majority of existing isc specs | Requires touching sod-remediation + identity-access and updating spec deltas |

## Acceptance criteria (brainstorm)

1. No `offline-data.ts` files remain in `src/`.
2. `identity-access.spec.ts` and operation specs use inline mocks/constants; no imports from removed fixture modules.
3. Offline invoke payloads (`payloads/sod-remediation-offline.json`, etc.) still succeed without config.
4. `npm test` passes with coverage thresholds unchanged.
