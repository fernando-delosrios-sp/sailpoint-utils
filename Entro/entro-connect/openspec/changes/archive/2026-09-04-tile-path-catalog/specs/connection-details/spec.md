## MODIFIED Requirements

### Requirement: Connection details bind to locked path

The Connection details field map MUST be the locked Integration path's `connectionFields` plus shared tile fields and Worker Group (Connector). Fields MUST NOT be merged from other paths on the same tile or from optional capabilities unless the operator enabled that capability during Prep.

#### Scenario: Path-specific credentials

- **GIVEN** a locked Google GCP path Console manual — Private Key Integration
- **WHEN** Connection details are written
- **THEN** the Private Key JSON field MUST appear
- **AND** Workload Identity Federation fields MUST NOT appear
