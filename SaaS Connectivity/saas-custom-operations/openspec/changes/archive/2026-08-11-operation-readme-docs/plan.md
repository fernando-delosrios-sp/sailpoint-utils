# Operation README Docs Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Require and deliver a co-located `README.md` in every operation subdirectory, migrate sod-remediation docs from root README, and enforce README presence via discovery tests.

**Architecture:** Documentation-only change aligned with existing `operations/<slug>/index.ts` layout. `_template/README.md` scaffolds new ops; discovery test mirrors codegen slug scan; root README slimmed to framework scope.

**Tech Stack:** Markdown, Vitest, operation-introspection discovery (`scripts/templates/operation-introspection.ts`)

**Spec references:** `openspec/changes/operation-readme-docs/specs/`

---

## Task 1: Template README scaffold

- [ ] **Step 1:** Create `src/operations/_template/README.md` with section placeholders per design D3
- [ ] **Step 2:** Add one-line pointer in `_template/index.ts` comment block — copy README when scaffolding
- [ ] **Step 3:** Manual check — template directory has both `index.ts` and `README.md`

## Task 2: Example operation README

- [ ] **Step 1:** Create `src/operations/example/README.md` — Purpose, `custom:example`, input/output tables
- [ ] **Step 2:** Reference `payloads/custom-example-offline.json` and `payloads/custom-example.json` (or existing example payload paths)
- [ ] **Step 3:** Mark Workflow integration as N/A or minimal (Get Accounts read pattern only)

## Task 3: Sod-remediation README migration

- [ ] **Step 1:** Create `src/operations/sod-remediation/README.md` with standard sections
- [ ] **Step 2:** Move content from root README `### custom:sod-remediation` block (invoke JSON, input/output tables, workflow integration steps 1–7, formInput note, revocable-only search strings, experimental API note)
- [ ] **Step 3:** Link `payloads/sod-remediation-workflow.json`, offline/live variants, and `workflows/SOD Remediation - *.json`

## Task 4: Root README slimming

- [ ] **Step 1:** Delete migrated sod section from root `README.md`
- [ ] **Step 2:** Under "Extending the connector" / layout bullet, add: each operation maintains `README.md` in its subdirectory
- [ ] **Step 3:** Update project structure tree — show `README.md` next to `index.ts` under `example/` and `sod-remediation/`

## Task 5: Discovery test enforcement

- [ ] **Step 1:** Write failing test — each slug from `scanOperationModules()` has `src/operations/<slug>/README.md`
- [ ] **Step 2:** Implement assertion in existing introspection/discovery spec file
- [ ] **Step 3:** Run `npm test -- operation-introspection` (or matching spec path) — PASS
- [ ] **Step 4:** Optionally verify failure message when README removed (spot-check or dedicated negative test)

## Task 6: Final verification

- [ ] **Step 1:** `npm test` — full suite PASS
- [ ] **Step 2:** `openspec validate --change operation-readme-docs --json` — valid
- [ ] **Step 3:** Add CHANGELOG entry (docs: per-operation README convention)
- [ ] **Step 4:** Update `verify.md` with evidence

---

## Design decision checklist (apply)

| Decision | Implementation target |
|----------|----------------------|
| D1 README at `operations/<slug>/README.md` | All operation README files |
| D3 Standard sections | `_template/README.md`, example, sod-remediation |
| D4 Discovery test | `operation-introspection` or `generate-operation-schemas` tests |
| D5 Sod migration | `sod-remediation/README.md` + root README removal |
