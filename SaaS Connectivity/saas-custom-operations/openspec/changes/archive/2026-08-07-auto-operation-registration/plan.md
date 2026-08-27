# Auto Operation Registration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Auto-register custom operations from optional `command` on `OperationSignature`, sync manifest commands, and resolve schemas from a build-time registry for auto-discovered ops.

**Architecture:** Extend `operation-introspection.ts` for module scan + AST export discovery; expand `generate-operation-schemas.ts` to emit `auto-registry.ts` and update `connector-spec.json`; add runtime schema registry with `customOperation` fallback; hybrid manual registration unchanged for ops without `command`.

**Tech Stack:** TypeScript, Vitest, tsx, TypeScript compiler API (existing introspection)

## Global Constraints

- Canonical test command: `npm test`
- Build command: `npm run build`
- Codegen command: `npm run codegen:schemas`
- Commit generated files: `*.schema.ts`, `auto-registry.ts`, `connector-spec.json`
- Inline string literals only for `command` and `output` (v1)
- One `customOperation` export per auto-discovered file

---

## Task 1: Introspection helpers

**Files:**
- Modify: `scripts/templates/operation-introspection.ts`
- Create/Modify: `scripts/templates/operation-introspection.spec.ts`
- Modify: `src/framework/output-schema.ts`

- [ ] **Step 1:** Write failing tests — extract `command` literal, find single export, fail on duplicates
- [ ] **Step 2:** Implement `scanOperationModules`, `extractCommandLiteral`, `findCustomOperationExport`, `discoverAllOperations`
- [ ] **Step 3:** Add `command?: string` to `OperationSignature`
- [ ] **Step 4:** Run `npm test -- operation-introspection` — PASS

---

## Task 2: Schema registry

**Files:**
- Create: `src/framework/operation-schema-registry.ts`
- Create: `src/framework/operation-schema-registry.spec.ts`
- Modify: `src/framework/with-custom-operation.ts`, `src/framework/index.ts`

- [ ] **Step 1:** Write failing test — `customOperation` resolves schema from registry by commandType
- [ ] **Step 2:** Implement registry map + `registerOperationSchema` / `getOperationSchema`
- [ ] **Step 3:** Wire fallback in `customOperation`; explicit `operationSchema` wins
- [ ] **Step 4:** Run `npm test -- operation-schema-registry with-custom-operation` — PASS

---

## Task 3: Codegen — auto-registry and manifest

**Files:**
- Modify: `scripts/generate-operation-schemas.ts`
- Modify: `scripts/generate-operation-schemas.spec.ts`

- [ ] **Step 1:** Write failing tests — emits `auto-registry.ts`, syncs `commands[]`, fails on collision
- [ ] **Step 2:** Implement `renderAutoRegistry`, `syncConnectorSpecCommands`, integrate into `generateOperationSchemas`
- [ ] **Step 3:** Switch sidecar generation to `discoverAllOperations`
- [ ] **Step 4:** Run `npm test -- generate-operation-schemas` — PASS

---

## Task 4: Migrate example operation

**Files:**
- Modify: `src/operations/example-operation.ts`
- Modify: `src/operations/index.ts`
- Modify: `src/operations/_template.ts`
- Generated: `src/operations/auto-registry.ts`, `connector-spec.json`

- [ ] **Step 1:** Add `command` to example interface; remove manual wiring
- [ ] **Step 2:** Update `index.ts` to use `registerAutoOperations`
- [ ] **Step 3:** Run `npm run codegen:schemas`; commit generated outputs
- [ ] **Step 4:** Run `npm test` — PASS

---

## Task 5: Templates alignment

**Files:**
- Modify: `scripts/templates/operation-introspection.ts` (`loadOperationMeta`)
- Modify: `scripts/generate-templates.ts`

- [ ] **Step 1:** Point `loadOperationMeta` at `discoverAllOperations`
- [ ] **Step 2:** Update templates tests/comments
- [ ] **Step 3:** Run `npm test` — PASS

---

## Task 6: Docs and verification

- [ ] **Step 1:** Update README and `_template.ts`
- [ ] **Step 2:** Run `npm test` — full suite
- [ ] **Step 3:** Run `npm run build` — PASS
- [ ] **Step 4:** CHANGELOG via changelog-generator skill

---

## Commit guidance

- Commit introspection + tests first
- Commit schema registry + customOperation wiring
- Commit codegen expansion + generated files together
- Commit docs/CHANGELOG separately
