# Brainstorm: Normalize ISC client layout

## Background

After `operation-layer-boundaries`, `src/isc/` remained inconsistent: `forms/` and `sources/` used subfolders, while `identity-access-client.ts`, `isc-client.ts` (experimental HTTP), and `token-identity.ts` stayed flat at the root. The identity-access module incorrectly mixed `IdentityHistoryApi`, `AccessProfilesApi`, and `RolesApi` in one file. Pre-SDK violations and controls were grouped under a single client module with no per-API spec split.

OpenSpec sub-capabilities (`target-client/identity-access`) did not mirror code layout, making promotion rules unclear for new ISC helpers.

## Q1: Should every ISC client use a subdirectory?

**Agreed: Yes — one subdirectory per ISC API surface**, not one folder per file unconditionally.

- Multi-module SDK groupings already use subfolders (`forms/`, `sources/`)
- Single-file modules that may grow should still get a subfolder to host additional modules later
- Flat files directly under `src/isc/` are deprecated for client implementations

**Rejected:** Keeping flat files for "simple" modules — scales poorly and contradicts forms/sources precedent.

## Q2: How should identity-access be split?

**Agreed: Separate by SDK API client, orchestrate in identity-access.**

| API | Folder | Responsibility |
|-----|--------|----------------|
| IdentityHistoryApi | `identity-history/` | `listIdentityAccessItemsV1` |
| AccessProfilesApi | `access-profiles/` | `getAccessProfileEntitlementsV1` |
| RolesApi | `roles/` | `getRoleEntitlementsV1` |
| Orchestration | `identity-access/` | `fetchIdentityAccessItemsFromSdk`, offline data, shared types |

**Rejected:** Single `identity-access-client.ts` with all three SDK clients — violates API boundary rule.

## Q3: How should pre-SDK APIs (violations, controls) be organized?

**Initial approach:** `experimental/` umbrella folder — **rejected by user**.

**Agreed:** One folder per REST API surface:
- `violations/` — GET `/violations/v1/{id}`
- `controls/` — GET `/controls/v1`
- Shared transport in `http/` (auth, experimental header, error wrapping) — infrastructure only, not an API grouping

**Rejected:** Grouping violations + controls under `experimental/` — obscures API boundaries same as the old flat `isc-client.ts`.

## Q4: How should OpenSpec capabilities align?

**Agreed:** Sub-spec per API grouping under `target-client/`:
- Root `target-client/spec.md` — layout rule, SDK factory, token-identity path
- New sub-specs: `identity-history`, `access-profiles`, `roles`, `violations`, `controls`
- Modified `identity-access` — orchestration-only requirements

Spec layout requirement explicitly forbids `experimental/` umbrella and mixed API files.

## Q5: What stays unchanged?

- Runtime contracts for `custom:sod-remediation` and other operations
- `connector-spec.json` commands
- SDK factory remains in `src/framework/sdk-factory.ts`
- Promotion gate: no `custom:*` names or operation domain types in isc public APIs

## Trade-offs

- **More directories for trivial modules** — accepted for uniform scaling
- **`http/` shared folder** — accepted as transport plumbing, not API grouping; avoids duplicating auth/error logic in each pre-SDK module
- **Import path churn** — mitigated by barrel `index.ts` per API folder and full test suite

## Open questions (resolved)

- Entry pattern per folder: primary module + optional `index.ts` barrel (matches `forms/`, `sources/`)
- `http/` purpose: shared pre-SDK GET transport only; SDK-backed modules use `sailpoint-api-client` directly
