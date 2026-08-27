## Why

Local operation development uses overloaded "test" and "fixture" terminology that collides with Vitest (`npm test`) and obscures what each piece does. The runner was named `test:operation`, input files lived under `fixtures/` with a `command` field that diverged from spcx/workflow `type`, and README headings called everything "test mode." Operators could not tell unit tests, local invokes, and persist inhibition apart. A consistent vocabulary aligned with existing "invoke payload" language reduces onboarding friction and makes `config.testMode` readable as persist inhibition only.

## What Changes

**npm script entry point**
- From: `test:operation` → `scripts/run-operation-fixture.ts`
- To: `call:op` → `scripts/call-op.ts`
- Reason: Distinct from Vitest; reads as "call this operation"
- Impact: **Breaking** — existing docs/scripts referencing `test:operation` must update

**Invoke payload directory and envelope field**
- From: `fixtures/*.json` with `command`, `config`, `input`
- To: `payloads/*.json` with `type`, `config`, `input` (matches `invoke-payload.json` and spcx POST body)
- Reason: Same file shape locally and in production invoke paths
- Impact: **Breaking** — payload files must use `type`

**Runner output labels**
- From: "Fixture run", "Inhibited persist outputs"
- To: "Local invoke", "Simulated persist (testMode=true)"
- Reason: Output vocabulary matches runner vocabulary
- Impact: Non-breaking (console only)

**Documentation and specs**
- From: fixture / test-operation terminology in README, CHANGELOG, OpenSpec
- To: local invoke / payload / `call:op` vocabulary; three invoke modes table (offline, connected dry-run, live)
- Reason: Single glossary across docs and specs
- Impact: Non-breaking

**Persist inhibition flag**
- From: Documented as "test mode (dry run)" banner concept
- To: `config.testMode` documented as persist inhibition; flag name unchanged
- Reason: User preference to keep the config key
- Impact: Non-breaking

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `operation-test-runner`: Rename requirements from fixture/command to payload/type; npm script `call:op`; output section labels
- `connector-config`: Documentation requirements for payload format and `call:op` script reference (replaces fixture envelope docs)

## Impact

- **Code:** `scripts/call-op.ts`, `scripts/payload-output.ts`, `src/framework/payload-persist-collector.ts`, `package.json`, example payloads under `payloads/`
- **Removed:** `scripts/run-operation-fixture.ts`, `scripts/fixture-output.ts`, `fixtures/`, `test-mode-fixture-collector.ts`
- **Docs:** README Development section, CHANGELOG Unreleased
- **Tests:** `scripts/call-op.spec.ts`, `scripts/payload-output.spec.ts`
- **Out of scope:** Live invoke safety gate (`--allow-persist`), `[test-mode]` log prefix rename, `operation-test-runner` capability directory rename
