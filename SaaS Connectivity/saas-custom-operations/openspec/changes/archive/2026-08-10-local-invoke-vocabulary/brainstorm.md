<!--
Raw capture of design exploration for local-invoke-vocabulary.
-->

# Brainstorm: Local Invoke Vocabulary

## Background

The connector supports local operation development via a JSON-driven runner, persist inhibition via `config.testMode`, and Vitest unit tests. Over time the naming converged on overloaded "test" terminology:

- `npm test` — Vitest unit tests
- `npm run test:operation` — local handler invoke (not unit testing)
- `config.testMode` — persist inhibition (not "testing mode" broadly)
- `fixtures/` — invoke envelope files (test-harness jargon)
- `command` field in local files — diverged from spcx/workflow `type`

Operators reported confusion: "test operation" sounds like unit tests; "fixture" sounds like test infrastructure; `testMode` bundles persist inhibition with offline stub behavior and logging.

## Q1: What should the local runner be called?

**Options considered:**

1. **`invoke:local`** — emphasizes local execution vs ISC workflow
2. **`call:op`** — short, operation-focused, distinct from `npm test`
3. **`run:payload`** — ties to payload files but less discoverable

**Decision:** `call:op` npm script. Reads as "call this operation" without colliding with Vitest.

## Q2: What should invoke envelope files be called?

**Options considered:**

1. **fixtures** — existing; rejected as test-framework jargon
2. **payloads** — aligns with `invoke-payload.json` and README "invoke payload" language
3. **invokes** — grammatically awkward as a folder name

**Decision:** `payloads/` directory; files are **invoke payloads**.

## Q3: Align envelope shape with spcx/workflow?

**Options considered:**

1. Keep local-only `command` field
2. Standardize on `type` (matches `invoke-payload.json`, spcx POST body, workflow export)

**Decision:** Require `type` in payload files. Removes silent divergence from production invoke shape.

## Q4: Rename `config.testMode`?

**Options considered:**

1. Rename to `dryRun` / `inhibitPersist` — clearer semantics
2. Keep `testMode` — already in invoke config, spec'd, user preference

**Decision:** Keep `config.testMode` as the config key. Document it as **persist inhibition**, not as a banner concept ("test mode"). Separate runner vocabulary from flag vocabulary.

## Q5: What about live persist during local invoke?

**Context:** `testMode: false` already enables real ISC writes; undocumented and lacks safety gate.

**Decision:** Out of scope for vocabulary rename. Follow-up change can add `--allow-persist` gate and `*-live.json` payload tier. This change documents the three invoke modes in README/specs.

## Vocabulary table (target state)

| Concept | Name |
|---------|------|
| Vitest | unit tests — `npm test` |
| Local runner | `npm run call:op` |
| JSON input | invoke payload — `payloads/*.json` |
| Envelope field | `type`, `config`, `input` |
| No-config run | offline invoke |
| Config + testMode true | connected dry-run |
| Config + testMode false | live invoke |
| Flag semantics | persist inhibited when testMode true |

## Trade-offs

- **Breaking rename** — scripts, paths, and payload field change; no `test:operation` alias unless added in apply
- **Partial pre-implementation** — exploratory session already landed core rename; change artifacts document intent and remaining gaps (log prefix, capability rename, sod-remediation change refs)
- **operation-test-runner spec name** — capability id unchanged; content updated to payload vocabulary

## Acceptance criteria

- `npm run call:op -- payloads/custom-example-offline.json` succeeds
- Payloads use `type` not `command`
- README uses local invoke / payload vocabulary; avoids "fixture" and "test operation"
- OpenSpec main specs synced after archive
