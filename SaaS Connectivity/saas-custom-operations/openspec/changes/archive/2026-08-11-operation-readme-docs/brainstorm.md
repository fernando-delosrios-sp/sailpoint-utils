# Brainstorm: operation-readme-docs

## Background

Custom operations live in `src/operations/<slug>/` with co-located domain modules, seeds, and tests (enforced since `operation-layer-boundaries`). Operation-specific documentation is split inconsistently:

- Root `README.md` carries a long **`custom:sod-remediation`** section (~55 lines: invoke payload, input/output tables, workflow integration, formInput keys, revocable-only search strings).
- **`custom:example`** has no dedicated docs beyond generic "Extending the connector" guidance.
- **`_template/`** scaffold comments describe layout but include no README to copy when authoring a new operation.
- `npm run templates` generates operator artifacts under `./templates/` (workflow-invocation.md) but not per-operation README files in source.

As more operations accumulate, the root README becomes a dumping ground and operation authors lack a discoverable, co-located doc contract next to the code they maintain.

## Decision chain

### Q1: What belongs in per-operation README vs root README?

**Agreed:** Split by audience and stability.

| Location | Content |
|---|---|
| Root `README.md` | Connector purpose, framework flow, prerequisites, generic invoke envelope, persist/testMode, extending connector (how to add an op), RequestContext API, project structure — **framework-level only** |
| `src/operations/<slug>/README.md` | Command name, purpose, input/output field tables, example invoke payloads (local + workflow), relevant `payloads/` file references, workflow integration steps, domain-specific notes (APIs, form seeds, offline behavior) |

**Rejected:** Duplicate full framework docs in every operation README — creates drift and maintenance burden.

**Rejected:** Keep all operation docs in root README with anchor links — does not scale; violates co-location with operation code.

### Q2: Which directories require a README?

**Agreed:** Every **discovered operation subdirectory** (auto-registered via codegen scan of `operations/<slug>/index.ts`) MUST include `README.md` at `src/operations/<slug>/README.md`.

**Agreed:** `_template/` MUST include a `README.md` scaffold copied when authors add a new operation (same as `index.ts` copy workflow).

**Excluded:** `operations/index.ts`, `operations/auto-registry.ts`, and non-operation folders — not in scope.

### Q3: How is the requirement enforced?

**Agreed:** OpenSpec requirement on `connector-operations` (layout/registry capability already owns operation subdirectory rules).

**Agreed:** Unit test alongside codegen discovery — when `scanOperationModules` finds a slug, assert `README.md` exists in that subdirectory. Build fails with descriptive error if missing (mirrors duplicate-command detection pattern).

**Rejected:** Codegen auto-generating README content from OperationSignature — generated docs drift from workflow context; authors must write meaningful integration notes.

### Q4: Root README migration for existing operations?

**Agreed:** Move **`custom:sod-remediation`** section from root README into `src/operations/sod-remediation/README.md` (preserve content; reorganize under standard sections).

**Agreed:** Add **`src/operations/example/README.md`** with minimal reference docs (command, input/output, local payload paths).

**Agreed:** Root README retains a short pointer under "Extending the connector" — e.g. "Each operation documents invoke and workflow integration in its own `README.md`" — and removes the inlined sod-remediation block.

### Q5: Standard README section outline?

**Agreed** minimum sections for operation READMEs (authors may add domain sections):

1. **Purpose** — one paragraph
2. **Command** — `custom:<slug>` literal
3. **Input / Output** — tables aligned with OperationSignature
4. **Invoke examples** — local (`call:op`) and workflow-ready payload references under `payloads/`
5. **Workflow integration** — numbered steps when applicable; omit or mark N/A for simple ops
6. **Local development** — offline payload behavior, testMode notes specific to this operation

`_template/README.md` includes HTML comment placeholders for each section.

## Approaches considered

| Approach | Pros | Cons |
|---|---|---|
| **A. Spec + discovery test + manual READMEs (recommended)** | Enforced at build; co-located; authors control workflow nuance | One-time migration effort for sod-remediation content |
| **B. Spec only (no test)** | Minimal code change | Easy to forget README when adding ops |
| **C. Codegen README from OperationSignature** | Always in sync for I/O tables | Cannot capture workflow JSONPath, payload file names, domain caveats |

**Recommendation:** Approach A — matches existing codegen enforcement patterns and scales with operation count.

## Trade-offs

- **Root README slimming** — operators must follow link to operation folder for sod-remediation details; acceptable because docs live beside code.
- **Manual README maintenance** — I/O tables may drift from OperationSignature; mitigate with codegen test only for file existence, not content parity (YAGNI until drift becomes a problem).
- **`_template` README** — slightly more copy ceremony; aligns with existing `_template/index.ts` workflow.

## Open questions (resolved for propose)

- Enforcement mechanism: **discovery unit test** (not content lint).
- `example` operation: **gets README** (reference implementation).
- Root README sod section: **move, not duplicate**.
