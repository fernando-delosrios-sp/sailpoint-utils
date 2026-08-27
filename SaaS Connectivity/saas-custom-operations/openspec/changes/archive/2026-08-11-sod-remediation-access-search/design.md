# Design: SOD remediation access search strings

## Context

SOD remediation is launch-only. Form submission exposes user choices plus hidden launch-populated keys for workflow orchestration. Prior hidden keys serialized `SideRevokePayload` as JSON strings.

## Goals

- Emit workflow-consumable plain-string access filters per side at form launch
- Remove stringified JSON from submitted formData contract
- Preserve owner-facing revocability/keep HTML in `groupAContentsHtml` / `groupBContentsHtml`

## Non-goals

- Workflow revoke execution logic in the connector
- Exposing `recommendedRevoke` on form submission
- Changing operation persist output fields

## Decisions

### Search string builder

```typescript
function buildAccessSearchString(items: Array<{ id: string }>): string {
  return items.map((item) => `id:${item.id}`).join(' OR ')
}
```

Lives in `access-path-resolver.ts` alongside path resolution. Input: `accessPaths` ids (entitlements + expanded APs/roles).

### Form input keys

| Key | Example | Purpose |
|-----|---------|---------|
| `groupAAccessSearch` | `id:ent-a` | Workflow filter for side A access items |
| `groupBAccessSearch` | `id:ent-b OR id:role-1` | Workflow filter for side B access items |

Assembled in `assembleFormInput()`; passed through seed hidden TEXT elements via existing SET_DEFAULT_VALUE + DISABLE pattern.

### Internal revokePayload retained

`ResolvedAccessSide.revokePayload` remains for:
- `pickRecommendedRevoke` during resolution
- Keep-recommendation enrichment
- Launch logging (`recommendedRevoke`, item counts)

Not serialized to form submission.

### Seed migration

Replace hidden payload formInput entries, element keys, and formConditions sources/targets. Form-definition version watermark auto-patches tenant definitions on next launch.

## Rollback

Reintroduce revoke payload keys in seed + `assembleFormInput` and revert spec delta. Workflows that already migrated to search strings would need a second update.

## Risks

| Risk | Mitigation |
|------|------------|
| Workflows still read old keys | CHANGELOG breaking note; README updated |
| Search filter too broad | Includes all side paths by design — workflow selects side via `remediationSide` |
| Empty side (edge) | Returns `''`; SOD violations always have entitlements per side |
