# ubiquitous-language Delta

## ADDED Requirements

### Requirement: Inbound entitlements attribute term

The glossary SHALL define **machine-account user-entitlements attribute** as the source `connectorAttributes.userEntitlements` string naming the machine-account `connectorAttributes` field that holds entitlement values (STRING, single or multi) for machine-identity evaluation. Normative text SHALL NOT treat that configuration key as the entitlement ids themselves.

#### Scenario: Inbound entitlements attribute term

- **GIVEN** specs describe how a source opts an account into machine-identity entitlement evaluation
- **WHEN** normative text names the schema configuration field
- **THEN** it SHALL use **inbound entitlements attribute**
- **AND** SHALL spell the configuration key `connectorAttributes.userEntitlements`

### Requirement: Scan summary identity term

The glossary SHALL define **scan summary identity** as the result-source native identity holding aggregate `custom:machine-identity-entitlements` results for one invoke, `{requestId}`. Normative text SHALL NOT call it **machine identity persist identity**, **child persist identity**, or **risk persist identity**.

#### Scenario: Scan summary identity term

- **GIVEN** specs or README name the result-source identity for one scan
- **WHEN** normative text names that identity
- **THEN** it SHALL use **scan summary identity** spelled `{requestId}`
- **AND** SHALL NOT reuse a per-identity persist identity term

### Requirement: Entitlements to add term

The glossary SHALL define **entitlements to add** as the deduped ISC entitlement refs (`entitlementId` plus `sourceId`) matched from inbound account values that are not already on the machine identity `userEntitlements`.

#### Scenario: Entitlements to add term

- **GIVEN** specs describe matched refs not yet present on a machine identity
- **WHEN** normative text names that list
- **THEN** it SHALL use **entitlements to add**
- **AND** SHALL NOT call inbound account strings entitlements to add

### Requirement: Scan summary account term

The glossary SHALL define **scan summary account** as the single result-source account persisted after all machine-identity patch attempts, containing aggregate counts and failure diagnostics. Normative text SHALL NOT call it a **trigger account**, **machine account**, or **underlying account**.

#### Scenario: Scan summary account term

- **GIVEN** specs describe the result-source row recording a completed scan
- **WHEN** normative text names that row
- **THEN** it SHALL use **scan summary account**
- **AND** SHALL NOT imply that the row triggers per-identity apply work

### Requirement: Underlying account term

The glossary SHALL define **underlying account** as an ISC account correlated to the machine identity, from which inbound entitlement values are read when the source schema has an **inbound entitlements attribute**.

#### Scenario: Underlying account term

- **GIVEN** specs describe source accounts belonging to a machine identity
- **WHEN** normative text names those accounts
- **THEN** it SHALL use **underlying account**
- **AND** SHALL NOT call them scan summary accounts
