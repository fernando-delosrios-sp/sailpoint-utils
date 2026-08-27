# Retrospective — auto-operation-registration

**Date:** 2026-08-07

## What went well

- Reused existing `operation-introspection.ts` AST parser; discovery logic stayed consistent with templates and codegen.
- Hybrid model preserved: auto ops via `command` literal + registry; manual ops unchanged.
- Generated `auto-registry.ts` keeps runtime registration declarative and reviewable in PR diffs.

## Friction

- Collision detection initially filtered manual index registrations by module `command` presence, missing the case where index.ts re-registers an auto op. Fixed by checking all index registrations against auto commands first.
- `context.commandType` is optional in SDK types; ncc build failed until guarded before registry lookup.
- OpenSpec delta for `templates-generator` required copying all existing scenarios into MODIFIED blocks (not just changed ones).

## Learnings

- “Manual registration” and “index.ts collision” are distinct checks: collision scans every index `.command()`, while manual discovery excludes modules that already declare `command`.
- Committing generated `auto-registry.ts` makes auto-registration visible in code review without running codegen.

## Follow-ups (deferred)

- None blocking merge.
