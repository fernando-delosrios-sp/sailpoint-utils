## Context

The connector exposes local operation development through a JSON envelope runner, persist inhibition via `config.testMode`, and Vitest unit tests. Historical naming used "test" for three orthogonal concerns (unit tests, local invoke, persist inhibition) and "fixture" for invoke payload files. Production invoke shape uses `type` at the top level (`invoke-payload.json`, spcx POST, workflow export); the local runner used `command`.

Exploratory implementation already landed core renames (`call:op`, `payloads/`, `type`). This change formalizes vocabulary, completes spec/doc sync, and closes remaining references.

## Goals / Non-Goals

**Goals:**

- Single glossary: **local invoke**, **invoke payload**, **`call:op`**, **`type`/`config`/`input`**
- Payload files interchangeable in shape with spcx/workflow invoke bodies (minus workflow-only fields)
- README documents three invoke modes without "fixture" or "test operation" as concept names
- OpenSpec main specs reflect payload/type requirements

**Non-Goals:**

- Renaming `config.testMode` or `SPCX_TEST_MODE`
- Live invoke safety gate (`--allow-persist`, tenant confirmation)
- Renaming `[test-mode]` console log prefix in framework
- Renaming OpenSpec capability directory `operation-test-runner`
- Auto-wiring `OPERATION_HANDLERS` to auto-registry

## Decisions

### D1: npm script name

- **选择:** `call:op`
- **理由:** Short, operation-focused, no collision with `npm test`
- **已考虑 alternative:** `invoke:local` (more explicit but longer); `test:operation` (rejected — collides semantically with Vitest)

### D2: Payload directory and file term

- **选择:** `payloads/`; files called invoke payloads
- **理由:** Matches existing `invoke-payload.json` and framework "invoke envelope" language
- **已考虑 alternative:** `fixtures/` (rejected — test jargon); `invokes/` (awkward)

### D3: Envelope operation field

- **选择:** Require `type`; reject payloads missing `type`
- **理由:** Aligns local files with spcx/workflow; one less mental translation
- **已考虑 alternative:** Accept `command` alias (rejected for v1 — keeps divergence)

### D4: Keep `config.testMode`

- **选择:** Retain flag name; document as persist inhibition only
- **理由:** Already in invoke config, spec'd, user preference
- **已考虑 alternative:** `dryRun` (clearer but breaking config contract)

### D5: Runner module naming

- **选择:** `call-op.ts`, `payload-output.ts`, `payload-persist-collector.ts`
- **理由:** Module names mirror user-facing vocabulary
- **已考虑 alternative:** Keep `run-operation-fixture.ts` internals (rejected)

### D6: Deprecation alias for `test:operation`

- **选择:** No alias in v1 — hard break documented in CHANGELOG
- **理由:** Small team scaffold; alias prolongs confusion
- **已考虑 alternative:** `"test:operation": "npm run call:op"` shim for one release

## Risks / Trade-offs

- [Risk] Operators with saved `fixtures/` paths break → Mitigation: CHANGELOG breaking note; README migration examples
- [Risk] External docs reference old names → Mitigation: grep repo; update sod-remediation change task refs on archive
- [Trade-off] Hard break vs alias → Accept hard break for vocabulary clarity

## Migration Plan

1. Replace npm script and runner modules (or verify pre-landed renames)
2. Move/rename payload files to `payloads/` with `type` field
3. Update README, CHANGELOG, OpenSpec specs
4. Run `npm test` and smoke `npm run call:op -- payloads/custom-example-offline.json`
5. Rollback: revert commit; restore `fixtures/` and `test:operation` if needed

## Open Questions

- Add `test:operation` deprecation alias for one release? (Currently: no)
- Follow-up change for live invoke `--allow-persist` gate? (Deferred)
