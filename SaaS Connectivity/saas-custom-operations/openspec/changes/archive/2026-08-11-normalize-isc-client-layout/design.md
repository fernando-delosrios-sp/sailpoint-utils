## Context

The connector separates `src/framework/` (orchestration, persist, SDK factory), `src/isc/` (generic ISC integration), and `src/operations/` (command handlers). After `operation-layer-boundaries`, `forms/` and `sources/` established a subdirectory pattern, but legacy flat modules remained. Developers adding ISC helpers had no single rule for where code belongs, and `identity-access-client.ts` violated the one-API-per-module principle by mixing three SDK clients.

This change is a structural refactor with spec realignment. No custom command contracts change.

## Goals / Non-Goals

**Goals:**
- Every ISC API surface lives in `src/isc/<api-grouping>/` with room to add modules
- Split identity-access into per-API wrappers plus orchestration layer
- Split pre-SDK violations and controls into separate API folders (no `experimental/` umbrella)
- OpenSpec `target-client` sub-capabilities mirror code layout
- All existing tests pass after import path updates

**Non-Goals:**
- Changing `custom:sod-remediation` or other operation I/O contracts
- Moving SDK factory out of `src/framework/`
- Adding new ISC API integrations beyond relocating existing code
- `connector-spec.json` changes

## Decisions

### D1: Mandatory per-API subdirectory under src/isc/
- **选择:** Each ISC API surface MUST be `src/isc/<api-grouping>/`. Flat `*.ts` client files at `src/isc/` root are disallowed.
- **理由:** Matches `forms/` and `sources/` precedent; subfolders host additional modules without renaming.
- **已考虑 alternative:** Flat for single-file modules — rejected (inconsistent, blocks growth).

### D2: Identity access split by SDK API
- **选择:** `identity-history/`, `access-profiles/`, `roles/` each wrap one SDK client method family; `identity-access/` orchestrates and holds offline data.
- **理由:** Enforces API boundary; specs can require delegation instead of direct SDK calls in orchestration.
- **已考虑 alternative:** Keep combined client — rejected (user requirement).

### D3: Pre-SDK APIs split by REST surface, not experimental umbrella
- **选择:** `violations/` and `controls/` as separate folders; shared GET transport in `http/isc-get.ts`.
- **理由:** User rejected grouping APIs under `experimental/`; `http/` is transport plumbing only.
- **已考虑 alternative:** `experimental/` subfolder — rejected; duplicate transport per API — rejected (DRY).

### D4: Barrel index.ts per API folder
- **选择:** Every ISC client API folder MUST expose public API via `index.ts`; consumers import from folder entry paths.
- **理由:** Stable import paths; single discoverable entry per API grouping; supports growth without renaming consumer imports.
- **已考虑 alternative:** Deep imports only — rejected (noisy, breaks when modules split).

### D5: OpenSpec sub-capability per API grouping
- **选择:** New deltas for identity-history, access-profiles, roles, violations, controls; modify root target-client and identity-access.
- **理由:** Spec tree predicts code location; archive syncs requirements to main specs.
- **已考虑 alternative:** Monolithic target-client spec — rejected (continues mixing concerns).

## Risks / Trade-offs

- [Risk] Missed import after move → Mitigation: `npm test`, grep for old paths (`identity-access-client`, `isc-client`, `experimental/`)
- [Risk] Spec delta header mismatch on archive → Mitigation: copy exact requirement headers from main specs for MODIFIED/REMOVED
- [Trade-off] Extra `http/` folder needs explanation in README — accepted; document as shared pre-SDK transport only

## Migration Plan

1. Add `http/`, per-API folders, and modules with tests before deleting flat files
2. Update sod-remediation and framework imports to new paths
3. Delete deprecated flat files (`identity-access-client.ts`, `isc-client.ts`, root `token-identity.ts`)
4. Write spec deltas; run `npm test` and build
5. Update README layout section

Rollback: revert commit; no tenant data migration.

## Open Questions

- None blocking — layout rule and API split confirmed in exploration.
