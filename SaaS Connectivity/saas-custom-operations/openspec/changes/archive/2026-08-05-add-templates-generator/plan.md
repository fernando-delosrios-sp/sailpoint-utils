# Templates Generator Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Add `npm run templates` that generates ISC operator artifacts (account schema JSON, access-token guide, workflow invocation guide) from registered custom operations.

**Architecture:** A Node script using the TypeScript compiler API introspects `src/operations/index.ts` and operation modules for `OperationSignature` types and `ctx.persist` child-identity patterns. Pure functions build ISC schema JSON and Markdown; the CLI writes to gitignored `./templates/`.

**Tech Stack:** TypeScript 4.x, `tsx`, Vitest, existing `typescript` devDependency for compiler API.

**Canonical test command:** `npm test`

---

## Task 1: Project wiring

- [ ] **Step 1:** Add `tsx` to devDependencies in `package.json`
- [ ] **Step 2:** Add script `"templates": "tsx scripts/generate-templates.ts"`
- [ ] **Step 3:** Add `templates/` line to `.gitignore`
- [ ] **Step 4:** Run `npm install` and verify `npm run templates` resolves (may fail until entrypoint exists)

**Files:** `package.json`, `.gitignore`

---

## Task 2: Operation introspection module

- [ ] **Step 1 (TDD):** Create `scripts/templates/operation-introspection.spec.ts` with tests:
  - parses `custom:example` from fixture `index.ts` snippet
  - extracts `{ summary: string, step?: string }` from fixture operation file
  - detects child identity `` `${ctx.requestId}:detail` `` pattern
- [ ] **Step 2:** Create `scripts/templates/operation-introspection.ts`:
  - `parseRegistrations(indexPath)` → `{ command, modulePath }[]`
  - `extractOperationSignature(filePath)` → `{ input: Field[], output: Field[] }`
  - `detectChildIdentities(filePath)` → `string[]` patterns
- [ ] **Step 3:** Run `npm test -- scripts/templates` — green

**Files:** `scripts/templates/operation-introspection.ts`, `scripts/templates/operation-introspection.spec.ts`

**Ref:** design.md D1, D4; spec scenarios for registered-only and child identity

---

## Task 3: Account schema builder

- [ ] **Step 1 (TDD):** Create `scripts/templates/account-schema.spec.ts`:
  - core attrs present, identityAttribute `id`, name `account`
  - merges output fields from multiple operations
  - excludes `sourceId`
- [ ] **Step 2:** Create `scripts/templates/account-schema.ts`:
  - `buildAccountSchema(operations: OperationMeta[]): object` matching ISC shape from workflow export
  - attribute helper with `type: 'STRING'`, standard flags
- [ ] **Step 3:** Run `npm test -- scripts/templates/account-schema` — green

**Files:** `scripts/templates/account-schema.ts`, `scripts/templates/account-schema.spec.ts`

**Ref:** design.md D2, D3; spec account schema scenarios

---

## Task 4: Markdown generators

- [ ] **Step 1 (TDD):** Create `scripts/templates/markdown.spec.ts`:
  - access-token output contains `{{API_URL}}`, `/oauth/token`, no hardcoded tenant IDs
  - workflow-invocation contains `custom:example`, invoke URL pattern, link to access-token.md
  - child identity section when detector returns patterns
- [ ] **Step 2:** Create `scripts/templates/access-token.ts` — `renderAccessTokenGuide(): string`
- [ ] **Step 3:** Create `scripts/templates/workflow-invocation.ts` — `renderWorkflowInvocationGuide(operations): string`
- [ ] **Step 4:** Run `npm test -- scripts/templates/markdown` — green

**Files:** `scripts/templates/access-token.ts`, `scripts/templates/workflow-invocation.ts`, `scripts/templates/markdown.spec.ts`

**Ref:** design.md D7; spec access token and workflow invocation scenarios

---

## Task 5: CLI entrypoint

- [ ] **Step 1:** Create `scripts/generate-templates.ts`:
  - resolve project root
  - call introspection on `src/operations/index.ts`
  - build schema + markdown
  - `fs.mkdirSync('templates', { recursive: true })`
  - write three output files
- [ ] **Step 2:** Run `npm run templates` — verify `./templates/` contains three files
- [ ] **Step 3:** Run full `npm test` — all green

**Files:** `scripts/generate-templates.ts`

---

## Task 6: Documentation and changelog

- [ ] **Step 1:** Update README with templates script section
- [ ] **Step 2:** Update CHANGELOG.md under `[Unreleased]` — Added `npm run templates`
- [ ] **Step 3:** Final `npm test` verification

**Files:** `README.md`, `CHANGELOG.md`

---

## Verification checklist (for /opsx:verify)

- [ ] `npm run templates` writes `account-schema.json`, `access-token.md`, `workflow-invocation.md`
- [ ] `templates/` is gitignored
- [ ] Vitest covers introspection, schema builder, markdown generators
- [ ] Only `custom:example` appears until additional operations are registered
