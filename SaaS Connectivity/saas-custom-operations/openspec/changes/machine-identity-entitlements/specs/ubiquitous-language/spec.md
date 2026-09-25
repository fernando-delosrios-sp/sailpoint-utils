# ubiquitous-language Delta

## ADDED Requirements

### Requirement: Inbound entitlements attribute term

The glossary SHALL define **inbound entitlements attribute** as the account-schema `configuration.inboundEntitlements` string naming the account attribute that holds entitlement values (STRING, single or multi) for machine-identity evaluation. Normative text SHALL NOT treat that configuration key as the entitlement ids themselves.

#### Scenario: Inbound entitlements attribute term

- **GIVEN** specs describe how a source opts an account into machine-identity entitlement evaluation
- **WHEN** normative text names the schema configuration field
- **THEN** it SHALL use **inbound entitlements attribute**
- **AND** SHALL spell the configuration key `configuration.inboundEntitlements`

### Requirement: Machine identity persist identity term

The glossary SHALL define **machine identity persist identity** as the result-source native identity holding `custom:machine-identity-entitlements` outputs for one machine identity, `{requestId}:{machineIdentityId}`. Normative text SHALL NOT call it **child persist identity** or **risk persist identity**.

#### Scenario: Machine identity persist identity term

- **GIVEN** specs or README name the result-source identity for one machine identity’s evaluation
- **WHEN** normative text names that identity
- **THEN** it SHALL use **machine identity persist identity** spelled `{requestId}:{machineIdentityId}`
- **AND** SHALL NOT reuse **child persist identity** or **risk persist identity**

### Requirement: Entitlements to add term

The glossary SHALL define **entitlements to add** as the deduped ISC entitlement refs (`entitlementId` plus `sourceId`) matched from inbound account values that are not already on the machine identity `userEntitlements`.

#### Scenario: Entitlements to add term

- **GIVEN** specs describe the persist payload for the apply workflow
- **WHEN** normative text names that list
- **THEN** it SHALL use **entitlements to add**
- **AND** SHALL NOT call inbound account strings entitlements to add

### Requirement: Trigger account term

The glossary SHALL define **trigger account** as the result-source account created by persist for `custom:machine-identity-entitlements`, which fires the bundled Account Created workflow. Normative text SHALL NOT call an **underlying account** a trigger account.

#### Scenario: Trigger account term

- **GIVEN** specs describe the result-source row that starts the apply workflow
- **WHEN** normative text names that row
- **THEN** it SHALL use **trigger account**
- **AND** SHALL NOT use underlying account or machine account as a synonym for that row

### Requirement: Underlying account term

The glossary SHALL define **underlying account** as an ISC account correlated to the machine identity, from which inbound entitlement values are read when the source schema has an **inbound entitlements attribute**.

#### Scenario: Underlying account term

- **GIVEN** specs describe source accounts belonging to a machine identity
- **WHEN** normative text names those accounts
- **THEN** it SHALL use **underlying account**
- **AND** SHALL NOT call them trigger accounts
