# Tasks — tile-path-catalog

## 1. Schema and migration

- [x] 1.1 Add `integration_catalog_migration.py` with tile rename map, consolidation, stub tiles, path evidence
- [x] 1.2 Refactor `IntegrationDefinition`, serializers, validators, and `catalog_contracts.py` for Integration paths
- [x] 1.3 Update `skill_held.py` slug routing to tile-only folders with legacy slug aliases

## 2. Catalog data

- [x] 2.1 Wire `INTEGRATIONS = consolidate_tile_catalog(_LEGACY_INTEGRATIONS)`
- [x] 2.2 Map optional capabilities (AWS Vault/NHI, Copilot Studio, GitHub RTS/S3, etc.)
- [x] 2.3 Add 29 additional UI tiles plus capture-required SharePoint and OneDrive rows (31 capture-required rows; 58 total)

## 3. Connect skill

- [x] 3.1 Update Lock, Intro, prep, tools, inputs, session-log in both skill trees
- [x] 3.2 Document capture-required stop and just-in-time optional capability consent

## 4. Generation and folders

- [x] 4.1 Regenerate `documentation/integrations.json` and both skill catalog trees
- [x] 4.2 Migrate row folders to `kebab(tile)`; remove obsolete target folders after artifact move

## Verification

- [x] 5.1 Rewrite `tests/test_ingest_docs.py` for 58 tiles, paths, stubs, and index shape
- [x] 5.2 Run `python -m pytest` and `openspec validate --all --json`

## Documentation

- [x] 6.1 Add `docs/adr/0003-tile-path-catalog.md` superseding ADR-0002 slug rule
- [x] 6.2 Update `README.md` and `AGENTS.md` entro-connect Lock wording

## Changelog

- [x] 7.1 Add CHANGELOG entry for tile/path catalog migration
