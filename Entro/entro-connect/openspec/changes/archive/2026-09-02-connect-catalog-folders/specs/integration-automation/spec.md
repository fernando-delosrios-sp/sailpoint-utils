<!--
Delta spec — one file per capability at specs/<capability>/spec.md
OpenSpec validates structure; scenarios use Gherkin steps inside the Markdown wrapper.
-->

## ADDED Requirements

### Requirement: Connect loads the Skill catalog progressively

The `entro-connect` skill SHALL read the Skill catalog index for Orientation and
Lock. It MUST NOT open a Row catalog, `tool-install.json`, or any Skill-held
artifact until Lock is stated. After Lock it SHALL open only that Lock's
`catalogPath`. For supervised and automated it SHALL read Tool install file
entries keyed by the locked row's Configuration tools only. It MUST NOT open
`documentation/` markdown to perform a Connect run. It MUST NOT treat a Coverage
as an Add New Account target. It MUST remain one skill: row folders MUST NOT
contain a `SKILL.md`.

_Rationale: ADR-0002 (apply)_

#### Scenario: Coverage name locks the parent from the index

- **GIVEN** the operator asks to connect Microsoft Copilot Studio
- **WHEN** the skill Locks the target
- **THEN** it MUST use the Skill catalog index Coverage names to Lock Microsoft Ecosystem with that Coverage
- **AND** it MUST NOT open a Row catalog before that Lock is stated

#### Scenario: Row catalog opens after Lock only

- **GIVEN** a completed Lock of GitHub Cloud - New
- **WHEN** the skill continues the Connect run
- **THEN** it MUST open `catalogPath` for that target only
- **AND** it MUST NOT open another target's `catalog.json`

#### Scenario: Tool install file waits for tools

- **GIVEN** Orientation and Lock are in progress
- **WHEN** the skill reads catalog data
- **THEN** it MUST NOT read `tool-install.json`
- **AND** after Lock, tools.md MUST read only the locked Configuration tool keys from that file

#### Scenario: Skill does not read ingested pages

- **GIVEN** `documentation/` markdown is absent
- **WHEN** the skill Locks GitHub Cloud - New
- **THEN** it MUST still complete intro, Operation mode, and Connect log from the Skill catalog tree
