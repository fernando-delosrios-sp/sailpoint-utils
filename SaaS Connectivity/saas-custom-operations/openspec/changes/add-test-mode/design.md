## Context

The custom operation framework (`src/framework/`) wraps handlers with `customOperation`, builds a volatile `RequestContext`, resolves a result source by name, and wires `ctx.persist` / `ctx.verifyPersisted` to SailPoint Accounts API calls with schema reconciliation. Handlers communicate workflow results via `ctx.res.send`. Local development uses `spcx run` against a built connector and Vitest with injected dependencies.

There is no supported path to run a handler end-to-end from a JSON file while suppressing ISC writes and surfacing what would have been persisted.

## Goals / Non-Goals

**Goals:**

- Opt-in test mode that inhibits ISC persistence and write-side schema/source mutations.
- When access token is provided, run read-only ISC status validation and list-only source resolution.
- When no access token, skip all ISC API calls and allow minimal fixture config.
- Preserve handler code paths and natural `ctx.res.send` behavior.
- Log every inhibited framework-managed ISC operation to console with `[test-mode]` prefix.
- Provide a JSON fixture runner aligned with ISC invoke envelope (`command`, `config`, `input`).
- Unit test coverage for test mode behavior and fixture runner.

**Non-Goals:**

- Changing production default when `testMode` is absent or false.
- Fixture-based assertion of `expectedOutput` (deferred).
- connector-spec.json UI field for testMode.
- Inhibiting direct `ctx.sdk` calls made by handler code (only framework-managed persistence/source/schema).

## Decisions

### D1: Activation via config flag with env fallback

- **选择:** Read `config.testMode === true` first; if unset, treat `process.env.SPCX_TEST_MODE === '1'` as enabled.
- **理由:** Fixture files are self-documenting; env var supports quick CLI runs without editing JSON.
- **已考虑 alternative:** Env-only — rejected because user request centers on JSON input files.

### D2: Token-gated ISC checks; inhibit writes at RequestContext layer

- **选择:** When test mode is active and config provides a non-empty token and apiUrl, call a read-only ISC status check (e.g., `listSourcesV1` with minimal filter) and resolve result source via list-only lookup (`listSourceByName`); never auto-create source or reconcile schema. When token is absent or empty, skip all ISC calls and use placeholder `sourceId` `test-mode-local`. Persist/schema/account writes always use no-op dependencies that log inhibited operations.
- **理由:** Supports both offline fixtures and credential-validated dry runs without mutating ISC.
- **已考虑 alternative:** Skip all ISC in test mode — rejected per user requirement to validate status when token present.

### D2b: Relaxed config parsing without token

- **选择:** In test mode only, when token is absent or empty, `parseStandardInput` SHALL require only `requestId` in input; `apiUrl`, `token`, and `sourceName` become optional with sensible defaults (empty strings / placeholder sourceName).
- **理由:** Enables fully offline JSON fixtures.
- **已考虑 alternative:** Require dummy token string — rejected; empty/missing token is the explicit offline signal.

### D3: Persist API unchanged; logging via createPersist no-op path

- **选择:** Reuse `createPersist` / `createVerifyPersisted` with test-mode `PersistDependencies` that skip API calls but still call `buildAccountAttributes` and log built attributes.
- **理由:** Logged output matches production attribute formatting; minimal new surface area.
- **已考虑 alternative:** Separate `ctx.dryPersist` — rejected; forces handler changes.

### D4: Fixture runner as standalone script

- **选择:** Add `scripts/run-operation-fixture.ts` and npm script `test:operation` that loads JSON, imports built connector, invokes command handler, prints `res.send` payload to stdout.
- **理由:** Works with `npm run build && npm run test:operation -- fixtures/example.json` without spcx invoke quirks.
- **已考虑 alternative:** Extend spcx CLI — rejected; out of repo control for v1.

### D5: Console log format

- **选择:** Prefix `[test-mode]`; persist lines include `identity`, `status`, and JSON-serialized attributes; end-of-run summary with persist count and response status.
- **理由:** Grep-friendly; consistent with existing `[persist]` log style.
- **已考虑 alternative:** Structured JSON logs — rejected for v1 simplicity.

## Risks / Trade-offs

- [Risk] Production invoke with accidental `testMode: true` skips persistence → Mitigation: loud startup log line; README warns dev-only; default false.
- [Risk] Handlers calling `ctx.sdk` directly still mutate ISC → Mitigation: document as non-goal; future optional SDK stub.
- [Trade-off] Missing source with token uses placeholder sourceId instead of auto-create → Accept: test mode must not write; log warning that source was not found.
- [Trade-off] Handlers calling `ctx.sdk` directly with token present can still mutate ISC → Mitigation: document; persistence path remains inhibited.

## Migration Plan

N/A — additive feature. Existing operations and tests unchanged when test mode is off. Rollback: remove test mode branch and fixture script.

## Open Questions

- None blocking v1. Optional v2: fixture `expectedOutput` assertion in runner.
