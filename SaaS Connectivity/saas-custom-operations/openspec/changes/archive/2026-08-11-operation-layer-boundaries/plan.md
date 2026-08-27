# Operation Layer Boundaries Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Enforce operation vs isc/framework boundaries by moving every operation into `operations/<slug>/index.ts`, extracting generic `isc/forms`, and realigning OpenSpec capabilities.

**Architecture:** Generic isc/forms primitives accept caller-supplied seeds and formInput; SOD domain stays in `operations/sod-remediation/`; codegen discovers subdirectory `index.ts` entries; specs split per-operation and by SDK API groupings.

**Tech Stack:** TypeScript, Vitest, operation-introspection codegen, sailpoint-api-client CustomFormsApi

**Spec references:** `openspec/changes/operation-layer-boundaries/specs/`

---

## Task 1: Generic isc/forms (foundation)

- [ ] **Step 1:** Write failing tests for seed-loader, ensure-definition, create-instance, error-formatting
- [ ] **Step 2:** Implement `src/isc/forms/*` modules with neutral types (no SOD field names)
- [ ] **Step 3:** Run `npm test -- isc/forms` — PASS

## Task 2: Codegen subdirectory discovery

- [ ] **Step 1:** Write failing test — discovers `example/index.ts` and `sod-remediation/index.ts`
- [ ] **Step 2:** Update `operation-introspection.ts` scan + `generate-operation-schemas.ts` import paths
- [ ] **Step 3:** Write failing test — `_template/index.ts` not registered
- [ ] **Step 4:** Run `npm test -- operation-introspection generate-operation-schemas` — PASS

## Task 3: Example operation migration

- [ ] **Step 1:** Move to `operations/example/index.ts`; update tests
- [ ] **Step 2:** Create `operations/_template/index.ts` scaffold; remove flat `_template.ts`
- [ ] **Step 3:** Run codegen; verify auto-registry imports `./example/index`

## Task 4: SOD remediation restructure

- [ ] **Step 1:** Create sod-remediation subdirectory tree; wire index.ts to generic isc/forms via form-service.ts
- [ ] **Step 2:** Move access-path-resolver, context, logging, seed locally
- [ ] **Step 3:** Delete old flat operation file and polluted isc sod modules
- [ ] **Step 4:** Run `npm test -- sod-remediation` — PASS (all sod-remediation spec scenarios)

## Task 5: Verification

- [ ] **Step 1:** `npm run codegen:schemas` — commands unchanged
- [ ] **Step 2:** `npm test` — full suite PASS
- [ ] **Step 3:** `npm run build` — PASS
- [ ] **Step 4:** `npm run templates` — discovers both subdirectory operations

---

## Design decision checklist (apply)

| Decision | Implementation target |
|----------|----------------------|
| D1 All ops in subdirs + index.ts | `operations/example/index.ts`, `operations/sod-remediation/index.ts` |
| D3 Generic isc/forms | `src/isc/forms/*` |
| D4 Experimental flat in isc | `experimental-client.ts` unchanged location |
| D5 access-path-resolver local | `operations/sod-remediation/access-path-resolver.ts` |
| D7 Codegen scan index.ts | `operation-introspection.ts` |
