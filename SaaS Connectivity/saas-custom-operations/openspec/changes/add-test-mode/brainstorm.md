<!--
Raw capture of superpowers:brainstorming output for add-test-mode.
-->

# Brainstorm: Test Mode for Custom Operations

## Background

The saas-custom-operations connector scaffold wraps custom command handlers with `customOperation`, which initializes a volatile `RequestContext`, resolves an ISC result source, and exposes `ctx.persist` / `ctx.verifyPersisted` that write accounts to ISC via the SailPoint API. Handlers return workflow output through `ctx.res.send`.

Developers need to exercise operation logic locally without creating or updating accounts on ISC. Today, running an operation (via `spcx run` or unit tests) either hits real ISC APIs or requires heavy mocking in Vitest. There is no first-class "dry run" path that runs the real handler code, preserves natural `res.send` behavior, and makes persistence side effects visible in the console.

## Q1: How should test mode be activated?

**Options considered:**

1. **Config flag on invoke payload** (`config.testMode: true`) — travels with the same JSON envelope ISC uses; works for local fixtures and could be honored if ISC ever passes it.
2. **Environment variable only** (`SPCX_TEST_MODE=1`) — simple for CLI but invisible in fixture files and harder to document per-operation runs.
3. **Separate test harness that never calls ISC** — duplicates framework wiring outside `customOperation`.

**Decision:** Config flag `testMode: true` in the invoke `config` section, read by `customOperation` / `createRequestContext`. Optional env var `SPCX_TEST_MODE=1` as a developer convenience that sets the flag when absent from config (documented, not required).

## Q2: What is the JSON input file?

**Options considered:**

1. **Full invoke envelope** — `{ command, config, input }` matching ISC/spcx invoke shape.
2. **Input-only file** — command and config passed via CLI flags.
3. **Expected-output fixture** — JSON includes `expectedOutput` for assertion after run.

**Decision:** Full invoke envelope JSON file (command + config + input). The file drives a local runner script (`npm run test:operation -- <path>`). Operation output comes from the handler's natural `ctx.res.send` call, printed to stdout by the runner. Optional `expectedOutput` in the fixture is a future enhancement; out of scope for v1.

## Q3: Which ISC operations must be inhibited?

**Decision:** When test mode is active, the framework SHALL NOT call write/mutate APIs:

- Source auto-provision (`createDelimitedFileSource`)
- Schema reconciliation (`ensureSourceSchema`, schema patches)
- Account create (`createAccountV1` via `ctx.persist`)
- Account read-back verification for persist (`readAccount`, `verifyPersisted`)

Instead, `ctx.persist` and `ctx.verifyPersisted` remain callable with the same signatures but record intent and log to console. Handler code paths stay unchanged.

## Q3b: Should test mode still talk to ISC at all?

**Options considered:**

1. **Never call ISC in test mode** — simplest offline fixtures; no token validation.
2. **Always call ISC for status** — contradicts offline fixture goal.
3. **Token-gated read-only checks** — validate connectivity when token present; fully offline when absent.

**Decision:** Token-gated read-only ISC checks:

- **With valid access token** (non-empty after normalize, plus apiUrl): run ISC status check (read-only API call to verify token/connectivity), resolve result source by name via list-only lookup (real `sourceId` when found; log and use placeholder when missing — no auto-create).
- **Without access token** (absent or empty): skip all ISC API calls; use placeholder `sourceId`; `apiUrl`, `token`, and `sourceName` optional in fixture config (only `requestId` required in input).

Write paths remain inhibited in both branches.

## Q4: What gets logged to console?

**Decision:** Structured console lines prefixed with `[test-mode]`:

- Mode enabled at operation start (command, requestId)
- Each inhibited persist: identity, status, attributes (formatted same as production `buildAccountAttributes`)
- Each inhibited verifyPersisted: identity list
- ISC status check result when token present (success or failure before handler)
- Inhibited write operations: source create, schema reconcile (single line each when skipped)
- Summary at completion: count of inhibited persists, final `res.send` payload reference

Token values MUST NOT appear in logs (existing security rule).

## Q5: Does `res.send` behavior change?

**Decision:** No. `ctx.res` is the real SDK `Response` object. The local runner captures and prints the send payload. In test mode, handlers behave identically except persistence side effects are simulated.

## Agreed approach (recommended)

**Framework-level test mode** inside `customOperation` / `createRequestContext`:

- Parse `testMode` from config (or env fallback)
- Branch on token presence: read-only ISC status + source list when token provided; fully offline when not
- Use real `sourceId` when source found via list; placeholder (`test-mode-local`) when offline or source missing
- Swap persist dependencies for no-op implementations that log inhibited writes
- Add `scripts/run-operation-fixture.ts` + npm script for JSON-driven local runs
- Document fixture format in README

**Trade-offs accepted:**

- Test mode is not a security boundary — a misconfigured production invoke with `testMode: true` would skip persistence. Mitigation: log prominently at start; document that testMode is for local/dev only.
- With token, handlers receive a live `ctx.sdk` and real sourceId when the result source exists; framework-managed writes remain inhibited.
- Without token, `ctx.sdk` is not initialized for ISC calls; handlers that require SDK must supply token or handle absence.

## Open items deferred

- Fixture `expectedOutput` assertion in runner (v2)
- connector-spec.json UI toggle for testMode (not needed — local/dev only)
