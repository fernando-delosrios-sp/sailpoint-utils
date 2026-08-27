# Design: SOD remediation keep recommendations

## Context

`sod-remediation-revocability` added path-derived revocability and a connector-owned ⭐ on `recommendedRevoke`. Owners misread that star. ISC exposes keep recommendations via `POST /recommendations/v1/request` (`IAIRecommendationsApi.getRecommendationsV1`). SOD launch already resolves access paths, builds HTML form columns, and assembles hidden revoke JSON.

Constraints: HTML DESCRIPTION columns; email parity in `situationSummary`; UTF-8 emojis; offline mode with canned data; API failures must not block launch.

## Goals / Non-Goals

**Goals:**

- Fetch ISC keep recommendations for all resolved path items at launch
- Show ⭐ “Recommended to keep” only for `YES` responses
- Remove owner-visible connector revoke ⭐
- Improve non-revocable copy with named grantor (`grantedVia`)
- Compute and display side correction hint when keep asymmetry exists
- Show 🔐 on privileged entitlements when metadata available
- Extend hidden revoke payload with keep metadata

**Non-Goals:**

- Surfacing `MAYBE` / `NO` interpretations to owners
- Patching existing tenant form definitions
- Replacing workflow revoke logic (`recommendedRevoke` may remain hidden-only)

## Decisions

### D1: Recommendations client location

- **选择:** New module `src/isc/recommendations/` using existing `IscClientConfig` + SDK `IAIRecommendationsApi`
- **理由:** Matches isc layer pattern (controls, violations); keeps operation layer orchestration-only
- **已考虑 alternative:** Inline HTTP in sod-remediation → rejected (duplicates isc abstraction)

### D2: Batch request shape

- **选择:** One `getRecommendationsV1` call per launch with `requests[]` built from unique `(identityId, item.id, item.type)` across both sides
- **理由:** Minimize round-trips; map responses back by item id + type
- **已考虑 alternative:** Per-item calls → rejected (N+1 latency)

### D3: Keep vs revoke `recommended` field

- **选择:** Remove UI use of `recommended` on `AccessPathLine`; add `keepRecommendation?: 'YES' | 'NO' | 'MAYBE' | 'NOT_FOUND'`; stop setting `recommended: true` for revoke targets in display pipeline
- **理由:** Single star semantics for owners
- **已考虑 alternative:** Rename in place → rejected (confusing for existing payload consumers)

### D4: Side correction algorithm

- **选择:** `recommendedSideToCorrect: 'groupA' | 'groupB' | null` using asymmetric YES counts (see brainstorm)
- **理由:** Simple, testable, matches owner intent
- **MAYBE/NOT_FOUND/NO:** Do not count as “has keep”

### D5: Named grantor (`grantedVia`)

- **选择:** During `resolveAccessSide`, when linking entitlement to role/AP, store `grantedVia?: { type, id, name }` on entitlement lines; render reason as `(granted via {name} role|access profile)`
- **理由:** Fixes generic reason text without extra API calls

### D6: Privileged flag source

- **选择:** Fetch entitlement assignments via historical-identities access-items (`type=entitlement`, experimental) at launch; merge `privileged` (or equivalent) onto entitlement path lines
- **理由:** Recommendations API does not expose privileged; identity-access fetch today is AP/role only
- **Offline:** Canned entitlements in offline-data with privileged samples

### D7: API failure handling

- **选择:** try/catch around recommendations + entitlement fetch; on failure, proceed with empty keep map / no privileged flags; no owner error
- **理由:** Launch must succeed; keep hints are advisory

### D8: Display module

- **选择:** Extend `revocability-labels.ts` (or rename to `access-path-labels.ts`) with keep star, privileged badge, side hint block; update `context.ts` to inject side recommendation paragraph
- **理由:** Centralize emoji/HTML; preserve escapeHtml for user-derived names

## Data model changes

```typescript
interface GrantedViaRef {
  type: 'ROLE' | 'ACCESS_PROFILE'
  id: string
  name: string
}

interface AccessPathLine {
  // existing fields...
  grantedVia?: GrantedViaRef
  keepRecommendation?: 'YES' | 'NO' | 'MAYBE' | 'NOT_FOUND'
  privileged?: boolean
  recommended: boolean  // deprecated for UI; false always in display path
}

interface SideRevokePayload {
  items: RevokeTarget[]
  recommendedRevoke: RevokeTarget  // workflow-only
  recommendedSideToCorrect?: 'groupA' | 'groupB' | null  // on operation context, not per-side payload
}
```

Side hint lives at operation level (comparing both groups), exposed in HTML and optionally `formInput.recommendedSideToCorrect` for workflow JSONPath.

## Risks / Trade-offs

- [Risk] Recommendations API latency at launch → Mitigation: single batch call; parallel with controls/violation fetch where safe
- [Risk] Entitlement history API unavailable in some tenants → Mitigation: skip 🔐; no launch failure
- [Trade-off] Silent degradation on API errors → Accept: advisory UX must not block remediation

## Migration Plan

N/A — no connector-spec command contract change. If new `formInput` keys are added for side hint, document one-time form definition recreate (existing operational pattern). Archive prior revocability change spec deltas into main spec on apply+archive.

## Open Questions

None — all resolved in brainstorm.
