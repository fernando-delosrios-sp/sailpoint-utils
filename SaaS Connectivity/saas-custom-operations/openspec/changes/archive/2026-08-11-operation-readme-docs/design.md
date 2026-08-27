## Context

The connector enforces `src/operations/<slug>/index.ts` as the entry for every custom operation. Root `README.md` documents framework behavior and currently embeds the full `custom:sod-remediation` workflow guide. Operation authors copy `_template/` when adding commands but receive no README scaffold. Codegen already scans operation subdirectories for auto-registration (`operation-introspection.ts`); extending that scan for README presence is low-cost enforcement.

## Goals / Non-Goals

**Goals:**

- Every auto-discovered operation subdirectory has a co-located `README.md`
- `_template/README.md` provides a copy scaffold for new operations
- Root README stays framework-focused; operation-specific invoke and workflow docs live beside operation code
- Build fails when a discovered operation lacks `README.md`

**Non-Goals:**

- Auto-generating README content from `OperationSignature`
- Validating README section content or I/O table parity with types
- Generating per-operation README via `npm run templates`
- Changing operation runtime behavior or manifest commands

## Decisions

### D1: README location and naming

- **选择**: `src/operations/<slug>/README.md` (fixed filename, same directory as `index.ts`)
- **理由**: Matches Node/project convention; predictable for authors and CI
- **已考虑 alternative**: `DOCS.md` or `docs.md` — rejected; README is universal discoverability

### D2: Content split root vs operation

- **选择**: Root README = framework + generic extending guide; operation README = command-specific invoke, payloads, workflow integration
- **理由**: Prevents root README growth; docs change with operation PRs
- **已考虑 alternative**: Keep sod section in root with anchor — rejected; does not co-locate with code

### D3: Standard section outline

- **选择**: Minimum sections — Purpose, Command, Input/Output tables, Invoke examples (payload file refs), Workflow integration (or N/A), Local development notes
- **理由**: Consistent author experience without over-specifying domain content
- **已考虑 alternative**: Free-form only — rejected; `_template` would not guide new authors

### D4: Enforcement via discovery test

- **选择**: Extend operation introspection / discovery unit tests to assert `README.md` exists for each scanned slug (excluding `_template` from auto-discovery, but `_template` still ships README scaffold)
- **理由**: Same pattern as duplicate-command and `_template` exclusion tests; fails at `npm test` / prebuild
- **已考虑 alternative**: Spec-only — rejected; easy to forget in apply

### D5: Sod-remediation migration

- **选择**: Move existing root README sod content verbatim (reorganized under standard sections) to `sod-remediation/README.md`; replace root block with one-line pointer
- **理由**: No information loss; immediate compliance for largest doc consumer
- **已考虑 alternative**: Rewrite from scratch — rejected; unnecessary risk

### D6: Example operation README

- **选择**: Minimal reference README for `custom:example` (purpose, I/O, `payloads/custom-example*.json` refs)
- **理由**: Demonstrates pattern for simple operations; satisfies discovery test

## Risks / Trade-offs

- [Risk] README I/O tables drift from OperationSignature → Mitigation: document in `_template` that authors should update README when changing output fields; defer automated parity check
- [Risk] External bookmarks to root README sod section break → Mitigation: CHANGELOG note; root README pointer to new path
- [Trade-off] Manual README maintenance vs codegen → Accept manual for workflow/domain nuance

## Migration Plan

1. Add `_template/README.md` scaffold and update `_template/index.ts` comment to mention copying README
2. Create `example/README.md` and `sod-remediation/README.md` (migrate sod content from root)
3. Slim root README — remove sod section, add per-operation README pointer under Extending
4. Add discovery test for README presence
5. Run `npm test` and `openspec validate`

N/A — no deployment or runtime migration; documentation-only change.

## Open Questions

None — enforcement, content split, and migration scope locked in brainstorm.
