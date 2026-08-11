# Brainstorm: SOD remediation access-path revocability

## Problem

Violation owners see access paths (entitlement, AP, role) but cannot tell which items a downstream workflow can actually revoke.

## Decisions (locked in explore)

- **Revocable** = workflow-actionable via ISC identity access removal (interpretation A)
- Derive from path expansion only — no extra entitlement API call
- HTML DESCRIPTION for group columns; email HTML parity in `situationSummary`
- UTF-8 emojis + text labels (✅ 🚫 ⭐ ⚠️ ℹ️)
- Same bundled seed / form name; admins recreate definition once to pick up seed changes
- `existing: false` violation criteria stay hidden

## Revocability rules

- ROLE / ACCESS_PROFILE on side → revocable
- ENTITLEMENT → revocable only when no ROLE/AP on same side; else not revocable (granted via role/AP)
- `recommendedRevoke` = highest-priority revocable item (Role > AP > Entitlement)
