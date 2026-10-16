# connector-operations/preventive-sod-check Delta

## ADDED Requirements

### Requirement: Concurrent pending-grant resolution

The preventive-sod-check operation MAY resolve access items for independent executing grants concurrently, MAY expand independent access items concurrently, and MAY attach missing SoD policy levels concurrently. Request-mode differential semantics SHALL remain unchanged.

#### Scenario: Request mode expands baseline once

- **GIVEN** request mode with supplied `requestedItems` and other EXECUTING grants
- **WHEN** the handler builds baseline and full predict entitlement sets
- **THEN** it SHALL expand the baseline access items once
- **AND** SHALL derive the full set by unioning supplied request items onto that baseline

#### Scenario: Baseline and full predict may run concurrently

- **GIVEN** request mode where both baseline and full entitlement sets are non-empty
- **WHEN** the handler calls SoD predict
- **THEN** it MAY issue both predict calls concurrently
- **AND** the persisted policy names SHALL still equal the differential (full minus baseline), unioned with existing policies when `inflightOnly` is false
