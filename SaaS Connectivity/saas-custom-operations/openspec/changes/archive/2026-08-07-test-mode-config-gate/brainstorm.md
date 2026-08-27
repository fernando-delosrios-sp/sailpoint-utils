<!--
Raw capture for test-mode-config-gate — refines add-test-mode offline gate.
-->

# Brainstorm: Test Mode Config Presence Gate

## Background

v0.2.4 test mode skips ISC when **no access token** is in config (`hasAccessToken` false). Fixtures use `{ config: { testMode: true } }` with only `requestId` in input — a partial config that silently skips ISC even though config was "provided."

User request: gate on **config presence**, not token presence.

## Q1: What counts as "no config provided"?

**Decision:** Config is **not provided** when none of these supply a config object for the invocation:
- `deps.config` (tests / explicit override)
- `context.config` (fixture runner / ISC invoke)
- `readConfig()` result when invoked at runtime

When all are absent or `readConfig()` yields no usable config object, treat as **no config** → skip ISC in test mode.

When **any** explicit config object is supplied (including `{ testMode: true }` only), config **is provided** → full standard config validation applies.

## Q2: Behavior when config is provided?

**Decision:** Same as production envelope validation:
- Require `apiUrl`, `token`, `sourceName`, `requestId`
- Run read-only `verifyIscStatus` + `resolveSourceByNameReadOnly`
- **Fail** with `ConnectorError` (or propagated API error) on missing token, invalid token, connectivity failure, or other ISC read errors
- No silent fallback to offline when config exists but token is bad

## Q3: Behavior when no config?

**Decision:**
- Activate test mode if `SPCX_TEST_MODE=1` env **or** testMode cannot be read from config (defaults to env)
- Skip all ISC API calls
- Require only `requestId` in input
- Placeholder `sourceId`
- Log `[test-mode] no config — skipping ISC`

## Q4: Fixture format change?

**Decision:** Offline fixture drops `config` section entirely (or empty fixture omits config key). Token fixture keeps full config. **Breaking** for `custom-example-offline.json` which currently has `{ testMode: true }` — move testMode to env or document that offline = no config block.

For offline runs: `SPCX_TEST_MODE=1` + fixture without config, **or** future: testMode in env only.

## Q5: Replace hasAccessToken?

**Decision:** Replace with `isConfigProvided(resolution)` tracking whether config came from an explicit source. Deprecate offline branch keyed on empty token; remove `hasAccessToken` from ISC gate (may keep for other uses or remove).

## Trade-offs

- `{ config: { testMode: true } }` alone will **fail** unless token/apiUrl/sourceName added — clearer than silent skip
- Fixture runner must omit config for offline; use env for testMode when config absent
