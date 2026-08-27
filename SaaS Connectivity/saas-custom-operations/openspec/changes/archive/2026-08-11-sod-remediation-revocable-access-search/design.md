# Design: SOD remediation revocable-only access search

## Context

SOD remediation resolves each violation side into access paths with revocability metadata. Launch populates `groupAAccessSearch` / `groupBAccessSearch` for workflow access-item fetch after form submission. Owner-facing HTML (`groupAContentsHtml`, situation summary) already shows non-revocable entitlements with grantor context.

The access-search change (archived) intentionally included all path ids. With revocability shipped, workflows need filters that match actionable targets only.

## Goals

- Emit access search strings containing only revocable access path item ids
- Preserve full path display in HTML for owner review
- Keep existing form key names and internal `revokePayload` structure

## Non-goals

- Changing revocability derivation or keep-recommendation behavior
- Exposing revocability metadata in form submission
- Workflow-side filtering as a substitute for connector-side correctness

## Decisions

### Revocable-only builder

```typescript
export function buildRevocableAccessSearchString(accessPaths: AccessPathLine[]): string {
    return buildAccessSearchString(accessPaths.filter((item) => item.revocable))
}
```

Co-located in `access-path-resolver.ts`. `buildAccessSearchString()` remains a generic id joiner for tests and potential reuse.

### Form input assembly

`assembleFormInput()` switches from:

```typescript
buildAccessSearchString(groupA.accessPaths)
```

to:

```typescript
buildRevocableAccessSearchString(groupA.accessPaths)
```

(same for group B)

### Display contract unchanged

`buildAccessContentsHtml`, `renderAccessPathListHtml`, and situation summary continue to iterate all `accessPaths` — owners still see non-revocable entitlements with "Not directly revocable" labels.

### Empty filter edge case

When no revocable items exist on a side, the search string is `''`. Normal SOD sides with role/AP expansion always include at least one revocable elevated path; entitlement-only sides mark entitlements revocable. Spec documents empty result for completeness.

## Migration Plan

No seed schema change. Tenants receive corrected search string values on next operation launch. Workflows that attempted to revoke non-revocable entitlement ids from the old filter should already have failed at ISC — behavior correction is forward-compatible for correct workflows.

**Rollback:** Revert to `buildAccessSearchString(group*.accessPaths)` and spec delta.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Workflows assumed all path ids in filter | CHANGELOG behavior note; README clarifies revocable-only semantics |
| Empty search string on edge-case side | Spec scenario; resolver invariants ensure revocable elevated path when grantor exists |
| Divergence between HTML and search string | Intentional — HTML is informational; search string is actionable subset |

## Open Questions

_(none — scope locked in brainstorm)_
