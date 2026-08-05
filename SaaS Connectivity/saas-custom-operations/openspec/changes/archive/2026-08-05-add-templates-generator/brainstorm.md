<!--
Raw capture of superpowers:brainstorming output from /opsx-explore session.
-->

# Background

Operators integrating SaaS custom operations with ISC workflows need:
1. A dummy-source **account schema** compatible with POST `/sources/v1/:sourceId/schemas` that reflects what operations persist.
2. **Workflow invocation instructions** per registered custom command (invoke body, read-result step).
3. A shared **access-token guide** extracted from the sample workflow export (`workflows/Workflow - SaaS Custom Operations Call.json`).

Today these are assembled manually. The framework persists named attributes (`id`, `status`, `date` + operation output keys) via `ctx.persist`, but the sample workflow schema still uses generic `param1`–`param9` slots — stale relative to the framework.

# Decision Chain

**Q1: What operations should the generator include?**
- Decision: **Only finished operations** — TypeScript files registered in `src/operations/index.ts`. No openspec fallback for unimplemented commands in `connector-spec.json`.
- Rationale: Avoid documenting contracts that don't exist in code yet.

**Q2: Should generated `templates/` be committed?**
- Decision: **No** — write to disk on `npm run templates`; add `templates/` to `.gitignore`.
- Rationale: Generated artifacts; operators regenerate locally after clone.

**Q3: How to handle child persist identities (`${requestId}:detail`)?**
- Decision: **Document when detected** in operation source (scan `ctx.persist(...)` calls for non-root identity patterns).
- Rationale: Example operation already uses child identity; readers need to know to read both accounts.

**Q4: Schema attribute naming — param slots vs semantic names?**
- Decision: **Semantic names** from `OperationSignature.output` interfaces, plus core `id`, `status`, `date`. Exclude reserved keys `sourceId` from paste-ready schema (framework-internal).
- Rationale: Aligns with `buildAccountAttributes` and persist framework spec.

**Q5: How to extract operation types?**
- Decision: **TypeScript compiler API** — parse `interface * extends OperationSignature` in `src/operations/*.ts`, exclude `_template.ts`. Map command names from `index.ts` `.command('custom:…', handler)`.
- Alternatives considered: explicit metadata registry (drift risk), openspec hybrid (rejected per Q1).

**Q6: Output file layout?**
- Decision: Three files under `./templates/`:
  - `account-schema.json` — ISC schema body (union of all output attributes)
  - `access-token.md` — shared OAuth + configuration (placeholders, not tenant IDs)
  - `workflow-invocation.md` — per-operation invoke/read sections; links to access-token.md

**Q7: Script runner?**
- Decision: Add `tsx` devDependency; `"templates": "tsx scripts/generate-templates.ts"`.
- Rationale: No ts-node in project today; tsx is lightweight for one-off scripts.

# Design Trade-offs

| Approach | Pros | Cons |
|----------|------|------|
| TS compiler API | Stays in sync with interfaces | AST parsing complexity |
| Manual manifest | Simple | Drifts from code |
| Commit templates | Visible in PRs | Stale without CI regen |

Chosen: TS compiler API + gitignored output + npm script.

# Workflow pattern (from sample export)

```
Configuration → Get Access Token → Call Operation → Read Result → Success
```

Invoke URL: `{apiUrl}/beta/platform-connectors/{connectorId}/invoke`

Invoke body structure:
- `config`: `{ apiUrl, sourceId, token }`
- `connectorRef`, `type` (command name), `tag: "latest"`
- `input`: `{ requestId, …operationFields }`

Read result (persisted ops): `sp:get-accounts` filter `nativeIdentity eq {requestId}`.

Operations without persist (future `check-sod-pending`): read invoke response only — not in scope until implemented.

# Current scope (at proposal time)

Only `custom:example` is registered. Expected schema attrs: `id`, `status`, `date`, `summary`, `step`. Child identity `requestId:detail` documented from example source.

# Acceptance criteria (informal)

- `npm run templates` writes three files to `./templates/`
- `templates/` is gitignored
- Schema JSON is valid for ISC create-schema API shape
- MD files use placeholders (`{{API_URL}}`, etc.), not hardcoded tenant values
- Re-running after adding operations updates output automatically
