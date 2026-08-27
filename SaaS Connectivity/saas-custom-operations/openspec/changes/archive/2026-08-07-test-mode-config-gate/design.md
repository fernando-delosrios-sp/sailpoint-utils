## Context

Test mode (v0.2.4) uses `hasAccessToken(config)` to choose between read-only ISC checks and fully offline execution. The fixture runner passes `context.config` from JSON; a `{ testMode: true }` object counts as config but skips ISC because token is empty.

## Goals / Non-Goals

**Goals:**

- Skip ISC in test mode only when no config is resolved for the invocation.
- When config is provided, validate standard connection fields and run read-only ISC; fail on missing/invalid token or API errors.
- Update fixtures, docs, and tests to match the new contract.

**Non-Goals:**

- Changing production (non-test-mode) behavior.
- Changing write inhibition (persist still logged, not executed).
- Auto-wiring fixture runner to auto-registry.

## Decisions

### D1: Config resolution tracking

- **选择:** Introduce `resolveInvocationConfig(deps, context)` returning `{ config, configProvided: boolean }`. `configProvided` is true when `deps.config` or `context.config` is defined, or when `readConfig()` returns a non-empty object at runtime.
- **理由:** Distinguishes explicit/absent config from empty token within config.
- **已考虑 alternative:** Token-only gate — rejected per user request.

### D2: ISC branch in test mode

- **选择:** If `!configProvided` → skip ISC, placeholder sourceId, minimal input parsing. If `configProvided` → full `parseStandardInput` validation, `verifyIscStatus`, `resolveSourceByNameReadOnly`; propagate errors.
- **理由:** Config present implies operator expects real connectivity check.
- **已考虑 alternative:** Partial config with only testMode still offline — rejected.

### D3: Test mode activation without config

- **选择:** When config not provided, `isTestMode` falls back to `SPCX_TEST_MODE=1` env only (config.testMode unavailable).
- **理由:** Offline fixtures omit config; env activates test mode.
- **已考虑 alternative:** Require testMode in input — rejected; env matches existing runner pattern.

### D4: Remove hasAccessToken ISC gate

- **选择:** Remove `hasAccessToken` from ISC branching; keep or remove helper based on usage after refactor.
- **理由:** Obsolete gate condition.

### D5: Offline fixture migration

- **选择:** `custom-example-offline.json` removes `config` block; README documents `SPCX_TEST_MODE=1 npm run test:operation -- fixtures/...`.
- **理由:** `{ testMode: true }` alone would now fail validation.

## Risks / Trade-offs

- [Risk] Users with partial config expect offline → Mitigation: CHANGELOG breaking note; clear error messages listing missing fields.
- [Trade-off] Env required for offline CLI → Accept: documented one-liner.

## Migration Plan

1. Implement config resolution + gate.
2. Update tests and offline fixture.
3. Bump patch version; CHANGELOG breaking note for partial-config offline fixtures.

## Open Questions

None blocking.
