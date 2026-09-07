<!--
Delta spec — Authentication route joins the Configure once terms.
-->

## MODIFIED Requirements

### Requirement: Configure once term

The glossary SHALL define Configure once, Configure once prompt, and
Authentication route with the definitions in the Term entries below. Specs that
name the prior session-config step on a Tool install entry MUST use Configure
once rather than habilitator, sessionConfig, or authPrerequisite. Specs that
name one question the vendor command asks, together with where the operator
obtains that value, MUST use Configure once prompt. Specs that name one of the
several ways a single Configuration tool can be authenticated MUST use
Authentication route, and MUST NOT call it an Authentication method, which is
Entro's credential type on an Add New Account target.

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

#### Scenario: Specs use Authentication route not auth method

- **GIVEN** a change authors requirements about the alternative ways to authenticate one Configuration tool
- **WHEN** it names one entry in a Configure once `methods` list
- **THEN** it MUST use Authentication route
- **AND** it MUST NOT use Authentication method, which names Entro's credential type on a row

## Term entries

### Term: Configure once
**Context**: documentation-ingest
**Definition**: An optional Tool install catalog object (`configureOnce`) holding the Authentication routes by which an operator can get that Configuration tool authenticated.
**Aliases**: none
**Notes**: Omitted on CLIs whose sign-in creates their own session config. Lives on the shared Tool install entry, not on a Row catalog. Not a Prep step, not a Typed action, not a Capability probe. Chat may say habilitator; specs MUST NOT. Credentials from a route's command MUST NOT enter chat or the Connect log. When the object exists it MUST carry a non-empty `methods` list.

### Term: Authentication route
**Context**: documentation-ingest
**Definition**: One entry in a Configure once `methods` list: a named way to get a Configuration tool authenticated, carrying `whenToPick`, its own non-secret presence `check` and `suitableWhen`, an operator-run `command`, its Configure once prompts, its Credential boundary, its `docsUrl`, and an `authOnce` that MAY be null when the route has no sign-in step.
**Aliases**: none
**Notes**: Distinct from Authentication method, which is Entro's credential type on an Add New Account target; an Authentication route is about the operator's local CLI session. Routes on one tool may differ in Credential boundary — for `aws`, long-lived keys in the shared credentials file versus the vendor CLI token cache. The skill selects a route when exactly one check is suitable and otherwise gates the choice, marking none of them recommended, because which route applies depends on the operator's organization.

### Term: Configure once prompt
**Context**: documentation-ingest
**Definition**: One entry in an Authentication route's `prompts` list: `prompt`, the label the vendor command displays, `whereToFind`, a non-secret statement of where the operator obtains that value, and optional `secret`, marking a value that is typed straight into the vendor CLI.
**Aliases**: none
**Notes**: Listed in the order the route's command asks. Relayed verbatim in the Configure once request so the operator can answer without leaving the run. Answered inside the vendor CLI, so it is never an Operator input, never bound to `connectionFields`, and never written to the Connect log. A `secret` prompt is relayed by label and source only and MUST NOT be requested or accepted in chat.
