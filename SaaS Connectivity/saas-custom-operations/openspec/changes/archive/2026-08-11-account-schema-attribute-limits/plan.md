# Account schema attribute value limits Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Enforce ISC storage limits (128-char identity, 256-char STRING values) at persist time with warn-and-truncate behavior.

**Architecture:** New `attribute-limits.ts` holds constants and `truncateForIscStorage`. `persist-result.ts` applies STRING caps in `formatScalarValue` and identity cap in `buildAccountAttributes`. All custom operations inherit via existing persist path.

**Tech Stack:** TypeScript, Vitest, `@sailpoint/connector-sdk` persist helpers

**Test command:** `npm test`

---

## Task 1: Attribute limit module

- [ ] **Step 1:** Write failing tests in `src/framework/attribute-limits.spec.ts` — passthrough at exact limit, truncate above limit, warning includes context
- [ ] **Step 2:** Implement `ISC_IDENTITY_MAX_LENGTH`, `ISC_STRING_ATTRIBUTE_MAX_LENGTH`, `truncateForIscStorage` in `attribute-limits.ts`
- [ ] **Step 3:** Run `npm test -- attribute-limits`

## Task 2: Persist integration

- [ ] **Step 1:** Write failing test — identity >128 truncated in `buildAccountAttributes` output
- [ ] **Step 2:** Write failing test — STRING field >256 truncated in `formatAttributeValue`
- [ ] **Step 3:** Write failing test — STRING array element >256 truncated independently
- [ ] **Step 4:** Write failing test — values within limits unchanged, no warn log
- [ ] **Step 5:** Wire truncation into `formatScalarValue` (STRING branch) and `buildAccountAttributes` (`id` field)
- [ ] **Step 6:** Export constants from `src/framework/index.ts`
- [ ] **Step 7:** Run `npm test -- persist-result attribute-limits`

## Task 3: Documentation and changelog

- [ ] **Step 1:** Update README persist section with ISC limits and truncation policy
- [ ] **Step 2:** Update CHANGELOG (user-visible: oversized values truncated on persist)
- [ ] **Step 3:** Final `npm test` and `npm run build`

**Spec references:** `openspec/changes/account-schema-attribute-limits/specs/custom-operation-framework/spec.md`

**Design references:** `openspec/changes/account-schema-attribute-limits/design.md` §D1–D5
