# Operation Schema Codegen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Eliminate manual `defineOperationSchema` duplication by generating per-operation `*.schema.ts` sidecars from `OperationSignature.output` at build time (Option B).

**Architecture:** Extend existing `operation-introspection.ts` parser; new `generate-operation-schemas.ts` writes sidecars next to handlers; `prebuild` runs codegen before `ncc`; operations import `{name}Schema` sidecar.

**Tech Stack:** TypeScript, Vitest, tsx, existing templates introspection

## Global Constraints

- Canonical test command: `npm test`
- Build command: `npm run build`
- Codegen command: `npm run codegen:schemas`
- Commit generated sidecars (not gitignored)
- Inline `output: { ... }` literals only in v1

---

## Task 1: Codegen script

**Files:**
- Create: `scripts/generate-operation-schemas.ts`
- Create: `scripts/generate-operation-schemas.spec.ts`

- [ ] **Step 1:** Write failing test — generates `example-operation.schema.ts` with correct exports
- [ ] **Step 2:** Implement `generateOperationSchemas` using introspection
- [ ] **Step 3:** Run `npm test -- scripts/generate-operation-schemas` — PASS

---

## Task 2: npm integration

**Files:**
- Modify: `package.json`

- [ ] **Step 1:** Add `codegen:schemas` script
- [ ] **Step 2:** Update `prebuild` to invoke codegen after clean
- [ ] **Step 3:** Run codegen; verify `example-operation.schema.ts` created

---

## Task 3: Migrate operations

**Files:**
- Modify: `src/operations/example-operation.ts`, `_template.ts`
- Create: `src/operations/example-operation.schema.ts` (generated)

- [ ] **Step 1:** Import sidecar in example operation; remove inline defineOperationSchema
- [ ] **Step 2:** Update template with sidecar pattern comment/import

---

## Task 4: Docs and verification

- [ ] **Step 1:** Update README authoring section
- [ ] **Step 2:** Run `npm test` — full suite
- [ ] **Step 3:** Run `npm run build` — PASS
- [ ] **Step 4:** CHANGELOG entry

---

## Commit guidance

- Commit codegen script + tests first
- Commit generated sidecars + operation migration together
- Commit docs separately
