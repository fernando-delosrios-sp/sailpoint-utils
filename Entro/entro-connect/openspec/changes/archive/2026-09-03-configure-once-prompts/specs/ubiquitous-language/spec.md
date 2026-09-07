<!--
Delta spec — glossary terms promoted from discovery.
-->

## MODIFIED Requirements

### Requirement: Configure once term

The glossary SHALL define Configure once and Configure once prompt with the
definitions in the Term entries below. Specs that name the prior session-config
step on a Tool install entry MUST use Configure once rather than habilitator,
sessionConfig, or authPrerequisite. Specs that name one question the vendor
command asks, together with where the operator obtains that value, MUST use
Configure once prompt.

#### Scenario: Specs use Configure once not habilitator

- **GIVEN** a change authors skill or ingest requirements about writing local CLI session config before `authOnce`
- **WHEN** it names that catalog object
- **THEN** it MUST use Configure once
- **AND** it MUST NOT treat Configure once as a Prep step, Typed action, or Capability probe

#### Scenario: Specs use Configure once prompt not hint

- **GIVEN** a change authors requirements about the questions a Configure once command asks
- **WHEN** it names those catalog entries
- **THEN** it MUST use Configure once prompt
- **AND** it MUST NOT treat a Configure once prompt as an Operator input

## Term entries

### Term: Configure once
**Context**: documentation-ingest
**Definition**: An optional Tool install catalog object (`configureOnce`) that records a non-secret check, a `suitableWhen` rule, an operator-run command that writes local CLI session config so `authOnce` can succeed, and the Configure once prompts that command asks.
**Aliases**: none
**Notes**: Omitted on CLIs whose sign-in creates that config itself. Lives on the shared Tool install entry, not on a Row catalog. Not a Prep step, not a Typed action, not a Capability probe. Chat may say habilitator; specs MUST NOT. Tokens from the vendor wizard MUST NOT enter chat or the Connect log. When the object exists it MUST carry a non-empty `prompts` list and a `docsUrl`.

### Term: Configure once prompt
**Context**: documentation-ingest
**Definition**: One entry in a Configure once `prompts` list: `prompt`, the label the vendor command displays, and `whereToFind`, a non-secret statement of where the operator obtains that value.
**Aliases**: none
**Notes**: Listed in the order the command asks. Relayed verbatim in the Configure once request so the operator can answer without leaving the run. Answered inside the vendor CLI, so it is never an Operator input, never bound to `connectionFields`, and never written to the Connect log.
