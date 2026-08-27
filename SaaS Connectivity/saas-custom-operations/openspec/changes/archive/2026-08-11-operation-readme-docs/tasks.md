## 1. README scaffold and template

- [x] 1.1 Create `src/operations/_template/README.md` with standard section placeholders (Purpose, Command, Input/Output, Invoke examples, Workflow integration, Local development)
- [x] 1.2 Update `_template/index.ts` header comment to mention copying `README.md` alongside `index.ts`

## 2. Operation READMEs

- [x] 2.1 Create `src/operations/example/README.md` documenting `custom:example` (input/output, `payloads/custom-example*.json` references, local dev notes)
- [x] 2.2 Create `src/operations/sod-remediation/README.md` by migrating sod content from root README under standard sections (preserve invoke tables, workflow integration, formInput keys, revocable-only search string note)
- [x] 2.3 Verify sod README references `payloads/sod-remediation*.json` and workflow export files under `workflows/`

## 3. Root README migration

- [x] 3.1 Remove inlined `custom:sod-remediation` section from root `README.md`
- [x] 3.2 Add pointer under Extending the connector — each operation documents invoke and workflow integration in `src/operations/<slug>/README.md`
- [x] 3.3 Update project structure tree in root README to list `README.md` under each operation subdirectory

## 4. Build enforcement

- [x] 4.1 Extend operation discovery tests to assert `README.md` exists for each scanned operation slug
- [x] 4.2 Verify test fails with descriptive error when README is missing (negative test or manual spot-check documented in verify)

## 5. Verification

- [x] 5.1 Run `npm test` — full suite PASS including new discovery assertions
- [x] 5.2 Run `openspec validate --change operation-readme-docs --json` — valid
- [x] 5.3 Manual review — root README has no duplicated sod workflow steps; sod README contains migrated content

## 6. Changelog

- [x] 6.1 Add CHANGELOG entry noting per-operation README convention and root README reorganization
