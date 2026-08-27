# Local Invoke Vocabulary Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Replace fixture/test-operation vocabulary with `call:op`, `payloads/`, and `type`-aligned invoke payloads while keeping `config.testMode` as persist inhibition.

**Architecture:** Rename runner scripts and collector modules; move example JSON to `payloads/` with spcx-compatible `type` field; update README/specs/tests. No framework behavior change beyond naming and envelope validation.

**Tech Stack:** TypeScript, Vitest, tsx, OpenSpec delta specs

**Canonical test command:** `npm test`

**Smoke command:** `npm run call:op -- payloads/custom-example-offline.json`

---

## Task 1: Runner rename and payload envelope

**Files:**
- Create: `scripts/call-op.ts`, `scripts/payload-output.ts`
- Create: `src/framework/payload-persist-collector.ts`
- Modify: `src/framework/test-mode-persist.ts`, `package.json`
- Delete: `scripts/run-operation-fixture.ts`, `scripts/fixture-output.ts`, `src/framework/test-mode-fixture-collector.ts`

- [ ] **Step 1:** Write failing test in `scripts/call-op.spec.ts` — `loadPayload` rejects file without `type`
- [ ] **Step 2:** Implement `loadPayload` / `InvokePayload` with required `type` in `call-op.ts`
- [ ] **Step 3:** Write failing test — offline `runPayload` returns example operation response
- [ ] **Step 4:** Port handler registry as `OPERATION_HANDLERS`; wire `runPayload` / `runPayloadFromPath`
- [ ] **Step 5:** Implement `payload-output.ts` with `Local invoke` and `Simulated persist (testMode=true)` headers
- [ ] **Step 6:** Move collector to `payload-persist-collector.ts`; update `test-mode-persist.ts` import
- [ ] **Step 7:** Set `"call:op": "tsx scripts/call-op.ts"` in `package.json`; remove `test:operation`
- [ ] **Step 8:** Run `npm test -- scripts/call-op.spec.ts scripts/payload-output.spec.ts`

## Task 2: Example payloads

**Files:**
- Create: `payloads/custom-example-offline.json`, `payloads/custom-example.json`, `payloads/sod-remediation-offline.json`, `payloads/sod-remediation.json`
- Delete: `fixtures/*`

- [ ] **Step 1:** Copy fixtures to `payloads/` replacing `command` with `type`
- [ ] **Step 2:** Update error hints in `call-op.ts` to reference `payloads/` paths
- [ ] **Step 3:** Smoke `npm run call:op -- payloads/custom-example-offline.json`

## Task 3: Test coverage for spec scenarios

**Files:** `scripts/call-op.spec.ts`, `scripts/payload-output.spec.ts`

- [ ] **Step 1:** Test config-present payload passes `context.config` to handler (stub handler map)
- [ ] **Step 2:** Test `runPayloadFromPath` exit code 1 for missing `type`
- [ ] **Step 3:** Test output summary contains `type=custom:sod-remediation`
- [ ] **Step 4:** Test package.json `call:op` script points to `call-op`
- [ ] **Step 5:** Run full `npm test`

## Task 4: Documentation and changelog

**Files:** `README.md`, `CHANGELOG.md`, `openspec/specs/operation-test-runner/spec.md`, `openspec/specs/connector-config/spec.md`

- [ ] **Step 1:** Rewrite README Development section — local invoke, payloads, persist inhibition heading
- [ ] **Step 2:** Add breaking CHANGELOG entry under Unreleased
- [ ] **Step 3:** Sync main specs on archive (delta already in change specs)

**Note:** Core implementation may already exist from exploratory session. Apply phase should verify each step and mark tasks complete rather than re-implement blindly.
