## MODIFIED Requirements

### Requirement: Prep resolves from locked Integration path

Integration prep steps and Typed actions MUST be drawn from the locked Integration path only. Optional capability prep and Typed actions MUST run only after just-in-time operator consent. Row-level prep without a path MUST NOT exist when paths are declared.

#### Scenario: Path-owned prep

- **GIVEN** a locked GitHub Integration path GitHub Cloud - New
- **WHEN** the configuration plan is written
- **THEN** prep steps MUST come from that path's `prepSteps`
- **AND** MUST NOT mix steps from another path on the same tile
