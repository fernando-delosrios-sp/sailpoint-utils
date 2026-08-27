# Proposal: SOD remediation access-path revocability

## Why

SOD remediation forms list conflicting access paths without indicating which items are actionable for corrective removal. Owners need clear revocable vs informational lines before choosing a remediation side.

## Capabilities

- Annotate each resolved access path with revocable / not revocable and recommended target
- Render annotations as HTML with UTF-8 emojis in form group columns and email `situationSummary`
- Extend hidden revoke JSON payloads with `revocable`, `recommended`, and `reason` per item

## Non-goals

- Fetch direct entitlement assignments (deferred — path expansion is sufficient for v1)
- PATCH existing tenant form definitions
- Show `existing: false` violation criteria

## Impact

- **Breaking (operational):** Updated seed requires one-time form definition recreate per tenant
- **Non-breaking:** Operation I/O contract unchanged (`formUrl`, `situationSummary`)
