## Why

Integrating SaaS custom operations with ISC workflows requires a dummy-source account schema, OAuth token setup, and per-operation invoke instructions. Today operators assemble these manually from code and a sample workflow export. As operations are added, documentation drifts from `OperationSignature` types and persist behavior. A generator keeps operator artifacts aligned with implemented commands only.

## What Changes

**Developer tooling**
- Add `npm run templates` script that writes three files to `./templates/` (gitignored):
  - `account-schema.json` — ISC-compatible schema for POST `/sources/v1/:sourceId/schemas`
  - `access-token.md` — shared OAuth and configuration guide from sample workflow
  - `workflow-invocation.md` — per-operation invoke and read-result instructions

**Discovery scope**
- From: manual docs and stale param1–param9 schema in sample export
- To: auto-generated semantic attribute names from registered operations in `src/operations/`
- Reason: match framework persist contract (`id`, `status`, `date` + output keys)
- Impact: non-breaking; additive dev workflow only

**Output policy**
- Generated files are written locally, not committed (`templates/` in `.gitignore`)

## Capabilities

### New Capabilities

- `templates-generator`: npm script and supporting code that introspects registered custom operations and emits ISC operator templates (account schema JSON, access-token guide, workflow invocation guide)

### Modified Capabilities

<!-- none — no connector runtime behavior changes -->

## Impact

- **New files:** `scripts/generate-templates.ts` (or `scripts/templates/` module tree), Vitest tests for schema/type extraction
- **Modified files:** `package.json` (scripts + `tsx` devDependency), `.gitignore`
- **Reference input:** `workflows/Workflow - SaaS Custom Operations Call.json` (OAuth and invoke pattern; placeholders in output)
- **Unchanged:** connector runtime, `connector-spec.json`, operation handlers
