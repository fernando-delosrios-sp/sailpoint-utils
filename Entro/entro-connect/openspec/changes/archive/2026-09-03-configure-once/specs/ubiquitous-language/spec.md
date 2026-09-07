<!--
Delta spec — glossary terms promoted from discovery.
-->

## ADDED Requirements

### Requirement: Configure once term

The glossary SHALL define Configure once with the definition in the Term entry
below. Specs that name the prior session-config step on a Tool install entry
MUST use Configure once rather than habilitator, sessionConfig, or
authPrerequisite.

#### Scenario: Specs use Configure once not habilitator

- **GIVEN** a change authors skill or ingest requirements about writing local CLI session config before `authOnce`
- **WHEN** it names that catalog object
- **THEN** it MUST use Configure once
- **AND** it MUST NOT treat Configure once as a Prep step, Typed action, or Capability probe

## Term entries

### Term: Configure once
**Context**: documentation-ingest
**Definition**: An optional Tool install catalog object (`configureOnce`) that records a non-secret check, a `suitableWhen` rule, and an operator-run command that writes local CLI session config so `authOnce` can succeed.
**Aliases**: none
**Notes**: Omitted on CLIs whose sign-in creates that config itself. Lives on the shared Tool install entry, not on a Row catalog. Not a Prep step, not a Typed action, not a Capability probe. Chat may say habilitator; specs MUST NOT. Tokens from the vendor wizard MUST NOT enter chat or the Connect log.
