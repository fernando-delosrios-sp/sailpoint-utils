## ADDED Requirements

### Requirement: Risk persist identity term

The glossary SHALL define **risk persist identity** as the result-source account identity holding `custom:evaluate-access-request-risk` outputs, `evaluate-access-request-risk:{requestId}`. Normative text SHALL use the same term for the identity the bundled Risk Approval workflows read back and for the identity the framework failure path writes.

#### Scenario: Risk persist identity term

- **GIVEN** specs or README describe where evaluate access request risk writes its outputs
- **WHEN** normative text names the account identity
- **THEN** it SHALL use **risk persist identity** spelled `evaluate-access-request-risk:{requestId}`
- **AND** SHALL NOT describe the persist identity as bare `{requestId}`

#### Scenario: Failure account uses the same term

- **GIVEN** specs describe the `failed` account written when risk evaluation cannot complete
- **WHEN** normative text names that account's identity
- **THEN** it SHALL use **risk persist identity**
- **AND** SHALL NOT describe the failure account as living on a separate identity from the success account

### Requirement: Wrapper discriminator term

The glossary SHALL define **wrapper discriminator** as the trailing segment each bundled Risk Approval workflow appends to the access request id when building `requestId` — `:submitted`, `:dynamic`, or `:dynamic-approval` — so the three wrappers scoring one access request do not overwrite each other's result account.

#### Scenario: Wrapper discriminator term

- **GIVEN** specs or README explain why three workflows scoring the same access request do not collide
- **WHEN** normative text names the trailing segment that separates them
- **THEN** it SHALL use **wrapper discriminator**
- **AND** SHALL list the three values `:submitted`, `:dynamic`, and `:dynamic-approval`

#### Scenario: Discriminator is retained inside the prefixed identity

- **GIVEN** specs describe how the **risk persist identity** is built
- **WHEN** normative text relates the prefix to the **wrapper discriminator**
- **THEN** it SHALL state the discriminator is preserved inside the prefixed identity
- **AND** SHALL NOT describe the prefix as replacing the discriminator

### Requirement: Result identity term

The glossary SHALL define **result identity** as the framework-resolved result-source identity a custom operation writes, exposed as `ctx.resultIdentity`, built by the operation's optional `resultIdentity` declaration and defaulting to the invoke `requestId`. **Risk persist identity**, **apply persist identity**, and **child persist identity** are specific result identities.

#### Scenario: Result identity term

- **GIVEN** framework specs describe the identity used for automatic failed account persist
- **WHEN** normative text names that identity
- **THEN** it SHALL use **result identity**
- **AND** SHALL state it defaults to the invoke `requestId` when the operation declares no builder

#### Scenario: Result identity generalizes the per-operation terms

- **GIVEN** documentation relates the framework seam to individual operations
- **WHEN** normative text refers to a specific operation's account identity
- **THEN** it SHALL keep using that operation's own term, such as **risk persist identity** or **apply persist identity**
- **AND** SHALL reserve **result identity** for the framework-level concept
