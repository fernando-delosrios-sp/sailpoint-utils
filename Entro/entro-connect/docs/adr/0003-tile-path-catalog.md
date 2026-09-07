# ADR-0003: Tile and Integration path catalog identity

## Status

Accepted

Supersedes the Add New Account target folder slug rule in [ADR-0002](0002-skill-catalog-tree.md). ADR-0002's thin index and one-folder-per-row layout remain; identity changes from `(tile, targetSelection)` to **tile only**.

## Context

Entro's Select Provider UI lists 58 provider tiles. Connection forms expose mutually exclusive path choices (radio cards) — AWS CloudFormation/Terraform/Assume Role, Atlassian token types — not separate Add New Account targets. The catalog had 36 rows with duplicated tiles (GitHub ×3, Atlassian ×4) and separate Setup/Authentication method dimensions that do not match Lock UX.

## Decision

1. **One catalog row per Select Provider tile** (58 total). Tile label matches the UI string exactly.
2. **`integrationPaths`** replace `targetSelection`, `setupMethods`, and `authenticationMethods` as the operator-facing route. Paths visible on the form are named; singleton paths are implicit.
3. **`optionalCapabilities`** replace Coverage pre-selection. Consent is just-in-time during Prep.
4. **`captureRequired` stubs** reserve tiles without invented paths; Connect stops before Lock.
5. **Folder slug** is `kebab(tile)` only. Legacy target-based folders migrate via alias map during generation.

Legacy row definitions remain in `_LEGACY_INTEGRATIONS`; `consolidate_tile_catalog()` produces runtime `INTEGRATIONS`.

## Consequences

### Positive

- Lock matches Entro UI
- One GitHub folder, one Atlassian folder
- Clear stop for uncaptured providers

### Negative

- Breaking change for all catalog consumers and tests
- 31 tiles need future UI capture
- Documentation-derived paths may drift until verified
