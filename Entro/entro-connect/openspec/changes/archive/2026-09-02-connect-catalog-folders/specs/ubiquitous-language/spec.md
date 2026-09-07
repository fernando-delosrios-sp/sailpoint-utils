<!--
Delta spec — glossary terms promoted from discovery.
-->

## ADDED Requirements

### Requirement: Skill catalog layout terms

The glossary SHALL define Skill catalog, Skill catalog index, Row catalog,
catalogPath, and Tool install file with the definitions in Term entries below.
Notes on Skill-held onboarding artifact MUST name the row folder, not `vendor/`.
Notes on Add New Account target MUST say the ingest Integration index keeps one
full row per target in `documentation/integrations.json`, while the Skill
catalog uses one Row catalog file per target.

#### Scenario: Specs use Skill catalog for the tree

- **GIVEN** a change authors skill or ingest requirements about Connect-run catalog data
- **WHEN** it names that data
- **THEN** it MUST use Skill catalog for the generated tree
- **AND** it MUST NOT require the skill to open `documentation/` markdown

#### Scenario: Specs distinguish index from Row catalog

- **GIVEN** a change authors requirements about what Lock reads versus what Intro reads
- **WHEN** it names those files
- **THEN** it MUST use Skill catalog index and Row catalog
- **AND** it MUST NOT call the thin index a full Integration index row

#### Scenario: Specs use catalogPath

- **GIVEN** a change authors requirements about how Lock finds a folder
- **WHEN** it names the pointer
- **THEN** it MUST use catalogPath
- **AND** it MUST NOT require the skill to derive the path from a slug rule at run time

#### Scenario: Specs use Tool install file

- **GIVEN** a change authors requirements about where `toolInstall` lives on disk
- **WHEN** it names that file
- **THEN** it MUST use Tool install file
- **AND** it MUST NOT require `toolInstall` on the Skill catalog index

#### Scenario: Skill-held home is the row folder

- **GIVEN** a change authors requirements about Skill-held onboarding artifacts
- **WHEN** it names their location
- **THEN** it MUST place them in the row folder
- **AND** it MUST NOT use `vendor/` as the live home

## Term entries

### Term: Skill catalog
**Context**: integration-automation
**Definition**: The generated Connect-run data tree in both `entro-connect` skill folders: Skill catalog index, Tool install file, and one row folder per Add New Account target.
**Aliases**: skill integrations.json
**Notes**: Written by `integration_catalog.py` in the same run as `documentation/integrations.json`. Hand-edits are overwritten. The skill MUST NOT read `documentation/` markdown. Not the ingest Integration index. Not a per-integration skill.

### Term: Skill catalog index
**Context**: integration-automation
**Definition**: The thin root `integrations.json` in a skill tree that lists each Add New Account target for Orientation and Lock: tile, targetSelection, summary, Setup and Authentication method names, Coverage names, and catalogPath.
**Aliases**: none
**Notes**: MUST NOT carry `prepSteps`, `typedActions`, `connectionFields`, or `toolInstall`. Not `documentation/integrations.json`.

### Term: Row catalog
**Context**: integration-automation
**Definition**: The `catalog.json` in a row folder: the complete Skill catalog row object for one Add New Account target, including nested Coverages.
**Aliases**: none
**Notes**: Same schema as today's full skill row. Opened only after Lock. Not a Coverage folder. Not a per-method file.

### Term: catalogPath
**Context**: integration-automation
**Definition**: The skill-root-relative path on a Skill catalog index entry that names that target's Row catalog file.
**Aliases**: none
**Notes**: Example: `integrations/github-cloud-new/catalog.json`. The skill MUST use this field rather than recomputing a slug at run time.

### Term: Tool install file
**Context**: integration-automation
**Definition**: The skill-root JSON file that holds `toolInstall` keyed by CLI binary or MCP id, sibling to the Skill catalog index.
**Aliases**: tool-install.json
**Notes**: Opened after Lock. Connect reads only keys named by the locked row's Configuration tools. Not copied onto every Row catalog.

### Term: Skill-held onboarding artifact
**Context**: documentation-ingest
**Definition**: A vendor-published file or in-page onboarding snippet stored in the owning Add New Account target's row folder in both `entro-connect` skill trees, identified by skill-root-relative path and SHA-256.
**Aliases**: vendor script copy, skill-local script
**Notes**: Connect executes these bytes only. GitBook is not the runtime source. Live home is the row folder, not `vendor/`. Not an Operator input, not a CloudFormation launch in the Entro wizard unless that wizard artifact is itself a harvested GitBook file.

### Term: Add New Account target
**Context**: documentation-ingest
**Definition**: The selection in Entro's Add New Account flow that determines which connection form the operator sees — a tile on its own, or an explicit in-form target choice under a tile such as `GitHub Cloud - New`, `BitBucket Data Center`, or `Slack Enterprise Grid App`.
**Aliases**: target
**Notes**: One ingest Integration index row in `documentation/integrations.json` is exactly one target, identified by the tile label and the in-form selection together. The Skill catalog stores that same target as one Row catalog. Take the tile label from the Add New Account provider list. When a GitBook page documents a navigation path, use that label only if the named tile exists on the provider list; a path that names a missing tile is Coverage of the target those pages actually connect through, not a new row. A connector is always required; the row records Hosting, not Connector deployment. Not a setup method, not an authentication method, not a checkbox inside a form, not a Coverage.
