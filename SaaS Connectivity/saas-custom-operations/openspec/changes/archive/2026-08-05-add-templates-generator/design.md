## Context

The custom-operation framework persists results to a dummy ISC source via named account attributes (`buildAccountAttributes` in `src/framework/persist-result.ts`). Operators configure workflows that: obtain an OAuth token, invoke the platform connector, then read accounts by `nativeIdentity` (the operation `requestId`).

A sample workflow export exists at `workflows/Workflow - SaaS Custom Operations Call.json` and demonstrates the Configuration → OAuth → invoke → read-result pattern operators should follow.

Stakeholders: connector authors adding operations, and ISC admins wiring workflows to call them.

## Goals / Non-Goals

**Goals:**

- Provide `npm run templates` that regenerates operator artifacts from implemented code
- Emit ISC-ready account schema JSON (core attrs + union of operation output fields)
- Emit shared access-token documentation parameterized with placeholders
- Emit per-operation workflow invocation sections (invoke body, read-result, child identities when detected)
- Include only operations registered in `src/operations/index.ts`

**Non-Goals:**

- Documenting unimplemented commands listed in `connector-spec.json` but absent from `src/operations/`
- Committing generated output to git
- Calling ISC APIs at generation time
- Generating full workflow JSON exports (MD instructions only)

## Decisions

### D1: Operation discovery source

- **Choice:** Parse `src/operations/index.ts` for `.command('custom:…', handler)` registrations; resolve handler module; extract `OperationSignature` via TypeScript compiler API
- **Reason:** Single source of truth is finished code; avoids drift from openspec or connector-spec
- **Considered alternatives:** openspec hybrid (rejected — user chose TS-only); manual manifest registry (rejected — maintenance burden)

### D2: Schema attribute set

- **Choice:** Always include `id` (identityAttribute), `status`, `date`; union all `output` interface keys across registered operations; exclude `RESERVED_OUTPUT_KEYS` (`sourceId` omitted from paste-ready schema)
- **Reason:** Matches persist behavior and ISC dummy-source read pattern
- **Considered alternatives:** per-operation schemas (rejected — one dummy source); param slots (rejected — legacy)

### D3: TypeScript type → ISC schema type mapping

- **Choice:** All attributes map to ISC `STRING` (arrays/objects documented as JSON-serialized strings, consistent with `serializeAttributeValue`)
- **Reason:** Framework always stores string account attributes
- **Considered alternatives:** infer INT/BOOLEAN (rejected — not how persist works today)

### D4: Child identity documentation

- **Choice:** Scan operation source for `ctx.persist` calls whose first argument is not literally `ctx.requestId`; document additional read steps for detected patterns (e.g. `` `${ctx.requestId}:detail` ``)
- **Reason:** Example operation already uses child identities; operators must know to fetch them
- **Considered alternatives:** ignore child accounts (rejected — incomplete instructions)

### D5: Output location and git policy

- **Choice:** Write to `./templates/`; add `templates/` to `.gitignore`
- **Reason:** Generated artifacts; regenerate on demand
- **Considered alternatives:** commit templates (rejected by user)

### D6: Script runner

- **Choice:** `tsx` devDependency; `"templates": "tsx scripts/generate-templates.ts"`
- **Reason:** Project has TypeScript but no existing script runner; tsx is minimal overhead
- **Considered alternatives:** compile script with tsc (more ceremony); plain Node + JSON manifest (loses type introspection)

### D7: Access-token MD content

- **Choice:** Static structure derived from `workflows/Workflow - SaaS Custom Operations Call.json` Configuration + Get Access Token steps; replace tenant-specific IDs/URLs with placeholders while preserving ISC workflow expression patterns (e.g. `{{$.configuration.aPIURL}}`)
- **Reason:** OAuth flow is identical for all operations; one shared doc avoids duplication
- **Considered alternatives:** embed token steps in each operation section (rejected — redundant)

## Risks / Trade-offs

- [Risk] TS AST parsing breaks on unconventional interface naming → Mitigation: convention test — operations must export `*Operation extends OperationSignature`; generator logs warnings for unparseable files
- [Risk] `index.ts` registration pattern changes → Mitigation: unit test on registration parser; document expected `.command('custom:…', …)` pattern
- [Trade-off] Generator only reflects registered ops, not connector-spec declarations → Accepted per user decision; re-run after implementing new operations
- [Trade-off] MD instructions are not importable workflow JSON → Accepted; goal is copy/paste guidance, not SP-Config export

## Migration Plan

N/A — This change does not involve deployment or connector runtime changes.

**Adoption:** After merge, authors run `npm run templates` locally when adding or modifying operations. No ISC migration required until operator chooses to update dummy-source schema using generated JSON.

**Rollback:** Remove npm script and generator code; no runtime impact.

## Open Questions

None — explore session decisions are locked.
