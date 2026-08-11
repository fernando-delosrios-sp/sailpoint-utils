# Plan: base-schema-on-source-create

> **For agentic workers:** Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** When the framework auto-creates a DelimitedFile result source, apply the full base account schema (core attrs + union of all registered operation outputs) instead of a minimal three-attribute default, replacing or aligning any ISC-discovered schema on the create path.

**Architecture:** Shared `buildBaseAccountSchema` in framework; registry lists all sidecar schemas; `applyBaseAccountSchema` runs after `createSourceV1` in `createDelimitedFileResultSource`; templates import shared builder for parity.

**Tech Stack:** TypeScript, `@sailpoint/connector-sdk`, `sailpoint-api-client` SourcesApi, Vitest

**Test command:** `npm test`

---

## Task 1: Registry and base schema builder

- [ ] **Step 1:** Write failing test — `listRegisteredOperationSchemas` returns all registered sidecars
- [ ] **Step 2:** Implement registry list helper
- [ ] **Step 3:** Write failing test — `buildBaseAccountSchema` unions fields from multiple ops, excludes reserved keys, includes core attrs
- [ ] **Step 4:** Implement `buildBaseAccountSchema` in `src/framework/base-account-schema.ts`
- [ ] **Step 5:** Run `npm test -- base-account-schema operation-schema-registry` — green

## Task 2: Templates parity refactor

- [ ] **Step 1:** Refactor `scripts/templates/account-schema.ts` to call shared builder
- [ ] **Step 2:** Run `npm run templates` and diff `templates/account-schema.json` — expect no semantic change
- [ ] **Step 3:** Run `npm test -- account-schema` — green

## Task 3: Apply base schema on create

- [ ] **Step 1:** Write failing test — `createDelimitedFileResultSource` creates schema with operation output attrs when registry populated
- [ ] **Step 2:** Implement `applyBaseAccountSchema` with create-or-patch flow
- [ ] **Step 3:** Write failing test — when `getAccountSchema` returns pre-existing schema, patch adds missing base attrs (no duplicate create)
- [ ] **Step 4:** Wire `applyBaseAccountSchema` into `createDelimitedFileResultSource`; remove direct `DEFAULT_RESULT_ACCOUNT_SCHEMA` create on that path
- [ ] **Step 5:** Write failing test — `resolveSourceByName` with existing source does not call base schema apply
- [ ] **Step 6:** Run `npm test -- result-source` — green

## Task 4: Docs and full verification

- [ ] **Step 1:** Update README result-source section for base schema on auto-create
- [ ] **Step 2:** Update CHANGELOG
- [ ] **Step 3:** Run full `npm test` and `npm run build` — green
