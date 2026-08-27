# Retrospective — normalize-isc-client-layout

**Date**: 2026-08-11

## What went well

- Per-API subdirectory layout mirrors OpenSpec target-client sub-capabilities; code location is predictable for extenders.
- Shared `http/isc-get.ts` avoided duplicating pre-SDK transport while keeping violations and controls as separate API surfaces.
- Identity-access split (identity-history, access-profiles, roles + orchestration) preserved sod-remediation behavior with clearer boundaries.
- Full test suite and build passed after import path migration; no connector contract changes.

## What was harder than expected

- TypeScript build (ncc) surfaced a stricter `IscAttributeType` assignment in `result-source.ts` that Vitest did not catch — fixed with explicit cast after refactor touched imports.
- Apply session found implementation largely complete but tasks.md checkboxes and verify/archive artifacts were still pending.

## Misses / follow-ups

- None blocking. Optional: add dedicated identity-history tests for access-profile vs role `type` filter branches if finer-grained coverage is desired (currently covered via identity-access orchestration tests).

## Process notes

- Layout rule in README and CHANGELOG gives extenders a single place to learn import conventions (`../../isc/<api-grouping>`).
- Archive sync will promote spec deltas to main `openspec/specs/target-client/` tree.
