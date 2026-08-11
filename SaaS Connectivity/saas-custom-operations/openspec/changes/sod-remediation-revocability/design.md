# Design: SOD remediation access-path revocability

## Data model

`ResolvedAccessSide` gains structured `accessPaths: AccessPathLine[]` alongside legacy `displayLines` for tests/logging.

```typescript
interface AccessPathLine {
  type: AccessPathType
  id: string
  name: string
  revocable: boolean
  recommended: boolean
  reason?: 'direct-assignment' | 'granted-via-role' | 'granted-via-access-profile'
}
```

`RevokeTarget` in hidden payload mirrors the same fields.

## Revocability algorithm

After unique item expansion:

1. Detect `hasElevatedPath` (any ROLE or ACCESS_PROFILE on side)
2. For each item:
   - ROLE / ACCESS_PROFILE → `revocable: true`
   - ENTITLEMENT → `revocable: !hasElevatedPath`; reason when false based on which elevated types exist
3. `recommendedRevoke` = highest-priority among items where `revocable: true`

## Display

Central emoji map in `revocability-labels.ts`. HTML builder escapes user-derived names only.

Group columns: DESCRIPTION elements interpolate `groupAContentsHtml` / `groupBContentsHtml`.

Email / `situationSummary`: reuse same list renderer.

## Seed migration

Replace TEXTAREA group columns with DESCRIPTION; drop SET_DEFAULT_VALUE/DISABLE conditions for removed textareas. Admins delete and recreate form definition once.
