## Why

Test mode v0.2.4 treats an empty or token-less config as "offline" and skips ISC checks. That allows `{ config: { testMode: true } }` to bypass connectivity validation even though config was supplied. Operators cannot distinguish "I intentionally omitted ISC" from "I provided config but forgot the token." Gating on **config presence** makes the contract explicit: no config → skip ISC; config present → validate and run read-only ISC, failing on missing or bad credentials.

## What Changes

**ISC gate criterion**
- From: Skip ISC when access token is absent or empty in config.
- To: Skip ISC only when no config object is resolved for the invocation; when config is present, require full connection fields and run read-only ISC, failing on missing token, invalid token, or API errors.
- Reason: Align offline behavior with "no config" rather than "no token."
- Impact: Breaking for minimal `{ testMode: true }` fixtures without connection fields.

**Offline fixture shape**
- From: `{ config: { testMode: true }, input: { requestId } }`.
- To: Omit `config` entirely; activate test mode via `SPCX_TEST_MODE=1` or document equivalent env-only path.
- Reason: Partial config is no longer treated as offline.
- Impact: Update `fixtures/custom-example-offline.json` and README.

**parseStandardInput in test mode**
- From: Relaxed validation when token absent.
- To: Relaxed validation only when config not provided; full validation when config provided.
- Reason: Fail fast on incomplete config when user supplied config.
- Impact: Non-breaking for no-config offline path.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `custom-operation-framework`: Replace token-gated ISC skip with config-presence gate; remove relaxed-config-without-token requirement; fail on bad config when config provided.
- `connector-config`: Update test mode documentation for no-config vs config-present behavior.
- `operation-test-runner`: Update offline fixture contract (config optional/absent).

## Impact

- **Code:** `test-mode.ts`, `with-custom-operation.ts`, `parseStandardInput`, fixture runner, offline fixture, tests, README, CHANGELOG.
- **Breaking:** Offline fixtures that pass partial config without connection fields will error unless config is removed.
