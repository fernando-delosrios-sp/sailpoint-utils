## Context

The connector registers `custom:access-sod-remediation` today under `src/operations/access-sod-remediation/`. The operation scans enabled roles and access profiles for intrinsic SoD violations and creates policy-owner remediation forms. Persist output uses the `access-sod-remediation:` namespace on parent (`requestId`) and child (`{requestId}:{accessItemId}:{policyId}`) identities. Auto-discovery codegen registers the command from the `command` literal in `index.ts` and syncs `connector-spec.json`.

Stakeholders: connector maintainers, ISC workflow authors, and operators running scheduled access-model hygiene scans.

## Goals / Non-Goals

**Goals:**
- Rename command, directory, persist namespace, payloads, seeds, and spec capability path to `access-model-sod-remediation`
- Preserve all runtime behavior, violation logic, form launch, and email output semantics
- Update ubiquitous-language and cross-spec references in one atomic change
- Document breaking migration in CHANGELOG

**Non-Goals:**
- Dual-write or alias registration for the old command
- Backfill or migrate existing ISC persisted accounts
- Rename `custom:sod-remediation` or refactor shared sod-form-html APIs

## Decisions

### D1: Full slug rename (not command-only)

- **Choice**: Rename command, source directory, persist keys, payload/seed filenames, and OpenSpec capability path together
- **Reason**: Slug consistency is a project convention; partial rename leaves broken JSONPath and confusing docs
- **Considered alternatives**: Command alias only (rejected — persist keys would still be ambiguous); dual-write both namespaces (rejected — doubles schema surface and delays cleanup)

### D2: Git mv for source directory

- **Choice**: `git mv src/operations/access-sod-remediation src/operations/access-model-sod-remediation`
- **Reason**: Preserves history; matches prior operation additions
- **Considered alternatives**: Copy-delete (rejected — loses blame history)

### D3: String-replace persist keys in OperationSignature and schema sidecar

- **Choice**: Update `command` literal and all output keys in `index.ts`; run `npm run codegen:schemas` to regenerate `index.schema.ts` and auto-registry
- **Reason**: Codegen is source of truth for connector-spec.json account schema attributes
- **Considered alternatives**: Manual schema edits (rejected — overwritten on next codegen)

### D4: OpenSpec archive strategy

- **Choice**: Delta ADDED at `connector-operations/access-model-sod-remediation`; delta REMOVED at `connector-operations/access-sod-remediation`; archive deletes old spec directory
- **Reason**: Clear capability rename semantics for OpenSpec merge
- **Considered alternatives**: In-place MODIFIED at old path only (rejected — capability name would not update)

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Deployed workflows break on upgrade | CHANGELOG breaking entry; README migration note with old→new command and key mapping |
| Missed string references in repo | Grep for `access-sod-remediation`; `npm test` catches command/schema assertions |
| Stale persisted accounts with old keys | Document that re-running the scan creates new child identities with new keys; no automatic migration |

## Migration Plan

1. Apply rename in source, specs, payloads, and tests
2. Run `npm run build` (codegen + ncc) to verify auto-registry and connector-spec sync
3. Run `npm test`
4. Release with CHANGELOG breaking note listing:
   - `custom:access-sod-remediation` → `custom:access-model-sod-remediation`
   - `access-sod-remediation:*` → `access-model-sod-remediation:*` (same suffixes)
   - Offline payload path rename
5. Consumers update ISC workflow command steps and Get Accounts JSONPath before or during connector upgrade

**Rollback**: Revert commit; redeploy previous connector bundle. No data migration required on rollback beyond workflow command name.

## Open Questions

None.
