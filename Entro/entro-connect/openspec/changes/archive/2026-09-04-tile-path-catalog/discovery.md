# Discovery — tile-path-catalog

## Scope

Replace Add New Account target identity (`targetSelection`, Setup method, Authentication method, Coverage pre-selection) with one catalog row per exact Entro Select Provider tile (58 tiles from 2026-09-03 screenshot) and one **Integration path** per mutually exclusive choice visible on that tile's connection form. Optional capabilities are just-in-time additional instructions or actions, not Lock dimensions.

**In:** catalog schema, generators, validators, both skill trees, entro-connect Lock workflow, ubiquitous language, ADR-0002 supersession.

**Out:** Entro product UI changes, capturing all 58 connection forms in this change (31 stubs stop before Lock).

## Language (promote)

| Term | Definition | Status |
|---|---|---|
| Integration | One exact Select Provider tile label | promote |
| Integration path | Mutually exclusive connection-form choice on that tile; singleton paths are implicit | promote |
| Optional capability | Non-core surface or feature; additional prep/actions only after just-in-time operator consent | promote |
| Capture required | Tile row exists but form/paths not yet evidenced; Connect stops before Lock | promote |
| Path evidence | `ui-verified` \| `documentation-derived` \| `capture-required` | promote |

Retire from Lock vocabulary: Add New Account target, `targetSelection`, Setup method, Authentication method, Coverage (as operator selection).

## Decisions

1. Tile labels match the live screenshot exactly (`Amazon Web Services`, `Microsoft ecosystem`, …).
2. Integration path source of truth is Entro connection form UI when captured; otherwise documentation-derived with operator asked to verify via screenshot.
3. AWS CloudFormation / Terraform / Assume Role are paths; Basic Monitoring is baseline; Vault management and NHI Management are optional capabilities.
4. Atlassian paths: Classic API Token, Scoped API Token - Jira, Scoped API Token - Confluence; server rows become server paths; Self managed is a form modifier, not a path.
5. SharePoint and OneDrive are separate tiles (not Microsoft ecosystem Coverages).
6. Stubs: `captureRequired: true`, no invented paths or Typed actions; Connect requests form screenshots and stops.

## Open questions

- None blocking proposal. Remaining path labels for undocumented tiles stay documentation-derived until UI capture.
