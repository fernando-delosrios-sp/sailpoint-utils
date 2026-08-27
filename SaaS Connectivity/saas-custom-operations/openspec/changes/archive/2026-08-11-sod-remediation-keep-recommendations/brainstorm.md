# Brainstorm: SOD remediation keep recommendations

## Background

Phase 1 (`sod-remediation-revocability`) shipped workflow-actionable revocability labels and a connector-owned ⭐ **Recommended** badge tied to `recommendedRevoke` (Role > AP > Entitlement). Live owner feedback showed that star was misleading — it meant “recommended revoke target,” not ISC’s certification/IAI **keep** recommendation.

Owners also need clearer copy on non-revocable entitlements (“Not directly revocable”) and named grantors (“granted via B2B Buyer role”) instead of generic “granted via role.”

## Problem

Violation owners cannot see which access ISC recommends they **keep**, nor which **side** to correct when keep recommendations asymmetry exists across Group A vs Group B.

## Decision chain

### Q1: What should ⭐ mean in the UI?

- **Agreed:** ⭐ only when ISC Recommendations API returns `YES` → label **Recommended to keep**
- **Rejected:** Connector `recommendedRevoke` star in owner-facing UI (may remain in hidden payload for workflow only)

### Q2: Which API?

- **Agreed:** `POST /recommendations/v1/request` via `IAIRecommendationsApi.getRecommendationsV1`
- Response per item: `YES` | `NO` | `MAYBE` | `NOT_FOUND`
- **`YES`** = recommended to keep

### Q3: How to handle `MAYBE` and API failures?

- **`MAYBE`:** No star; does **not** count toward “has keep” for side logic
- **API failure:** Treat as no keep recommendations; no error surfaced to owner

### Q4: Side correction recommendation?

When one group has keep recommendations and the other does not, recommend correcting the group **without** keep recommendations:

```
A_has = any YES on Group A items
B_has = any YES on Group B items

if (!A_has && B_has)  → recommend correct Group A
if (A_has && !B_has)  → recommend correct Group B
else                  → no side recommendation
```

Show side recommendation in **both** form group DESCRIPTION columns and `situationSummary` email HTML.

### Q5: Revocability copy fixes?

- **Agreed:** “Not directly revocable” (not “Not revocable”)
- **Agreed:** Named grantor in reason — e.g. `(granted via B2B Buyer role)` — requires tracking `grantedVia` during path expansion

### Q6: Privileged access indicator?

- **Agreed:** 🔐 badge for privileged entitlements
- **Source:** Entitlement metadata from `historical-identities/v1/{id}/access-items?type=entitlement` (experimental header) or equivalent privileged flag on resolved items

## Trade-offs

| Choice | Pro | Con |
|--------|-----|-----|
| Batch recommendations call at launch | Single round-trip for all path items | Adds latency; failure → silent no-keep |
| Keep `recommendedRevoke` in hidden JSON only | Workflow retains revoke hint | Two “recommendation” concepts in payload |
| Entitlement fetch for privileged | Accurate 🔐 | Extra API call; offline mode needs canned data |

## Non-goals

- Surfacing connector revoke ⭐ to owners
- Patching existing tenant form definitions (recreate once if seed changes)
- Showing `existing: false` violation criteria

## Open questions (resolved)

All resolved in explore — no blocking TBDs for proposal.
