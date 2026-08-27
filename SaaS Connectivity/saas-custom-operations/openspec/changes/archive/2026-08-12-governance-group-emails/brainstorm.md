# Brainstorm: governance-group-emails

## Background

Workflows often need BCC or distribution lists from ISC governance groups (workgroups). Today this requires manual HTTP steps (list workgroup by name, list members, extract emails). The ABB branch had `custom:govgroup-emails`; main scaffold has no governance-group integration.

## Decision chain

**Q1: Is this generally reusable?**
Yes — pure lookup utility; only input is governance group name.

**Q2: Command name?**
`custom:governance-group-emails` (rename from ABB `govgroup-emails` for clarity).

**Q3: Output shape?**
Persist `governance-group-emails:emails: string[]` on result source (namespaced per connector convention).

**Q4: Where does ISC logic live?**
New `src/isc/governance-groups/` module (listWorkgroupsV1 + listWorkgroupMembersV1), following existing isc layer boundaries.

**Q5: Error handling?**
Throw ConnectorError when group not found or API fails (match ABB WorkgroupService behavior on main).

## Out of scope

- access-request-status, access-request-threshold, approval routing
- Caching workgroup membership
