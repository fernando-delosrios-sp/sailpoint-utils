## ADDED Requirements

### Requirement: Child persist names the conflicting entitlements per policy side

The access-model-sod-remediation operation SHALL persist `access-model-sod-remediation:conflicting-entitlements-group-a` and `access-model-sod-remediation:conflicting-entitlements-group-b` on each child result-source identity, each a plain-text list of the entitlements the violating access item holds on that policy side. The side names SHALL match `Group A` and `Group B` on the remediation form the access item owner sees. Each value SHALL name entitlements by display name, falling back to the entitlement id when the expansion carries no name, and SHALL read `none` for an empty side. Both SHALL contain no HTML and no links, because their consumers are an interactive panel and a person reading the account.

A side SHALL be persisted as its own attribute rather than as one combined string, so a consumer can present the two sides separately without parsing. Each value SHALL fit the ISC STRING attribute ceiling of 256 characters on its own, and when the full list would exceed it, SHALL drop whole entitlement names rather than truncate one mid-word and SHALL state the number of names dropped.

#### Scenario: Both sides named on their own attributes

-   **GIVEN** role `role-a` violates policy `policy-p` by holding entitlement `ent-1` named `Invoice Entry` on group A and `ent-2` named `Payment Release` on group B
-   **WHEN** the handler persists per-form output on child identity `` `${requestId}:role-a:policy-p` ``
-   **THEN** `access-model-sod-remediation:conflicting-entitlements-group-a` SHALL be `Invoice Entry`
-   **AND** `access-model-sod-remediation:conflicting-entitlements-group-b` SHALL be `Payment Release`

#### Scenario: Unnamed entitlement falls back to its id

-   **GIVEN** a violation whose group A entitlement `ent-9` expanded without a display name
-   **WHEN** the handler builds the group A value
-   **THEN** it SHALL be `ent-9`

#### Scenario: Long list drops whole names and counts them

-   **GIVEN** a violation whose group A side holds twenty entitlements with long display names
-   **WHEN** the handler builds the group A value
-   **THEN** it SHALL be at most 256 characters
-   **AND** SHALL end with the count of names it dropped
-   **AND** SHALL NOT contain a partial entitlement name

#### Scenario: A side spends the whole ceiling rather than half

-   **GIVEN** a violation whose group A side holds one entitlement with a 240-character display name
-   **WHEN** the handler builds the group A value
-   **THEN** it SHALL contain that name in full

### Requirement: Child persist carries access item, policy, and recipient identity

The access-model-sod-remediation operation SHALL persist `access-model-sod-remediation:access-item-id`, `access-model-sod-remediation:access-item-type`, `access-model-sod-remediation:access-item-name`, `access-model-sod-remediation:policy-id`, `access-model-sod-remediation:policy-name`, `access-model-sod-remediation:access-item-url`, `access-model-sod-remediation:policy-url`, and `access-model-sod-remediation:recipient-id` on each child result-source identity, alongside the notification fields. These values SHALL come from the violation and the resolved owner already held by the scan loop, and SHALL NOT cost an additional ISC read. Definition URLs SHALL target the ISC admin UI and SHALL distinguish role from access-profile paths.

#### Scenario: Identity fields persisted verbatim

-   **GIVEN** role `role-a` named `Accounts Payable Analyst` violates policy `policy-p` named `AP settlement vs payment release`
-   **AND** the access item owner resolves to identity `owner-1`
-   **WHEN** the handler persists per-form output
-   **THEN** `access-model-sod-remediation:access-item-name` SHALL be `Accounts Payable Analyst`
-   **AND** `access-model-sod-remediation:access-item-type` SHALL be `ROLE`
-   **AND** `access-model-sod-remediation:policy-name` SHALL be `AP settlement vs payment release`
-   **AND** `access-model-sod-remediation:access-item-url` SHALL target the definition of role `role-a`
-   **AND** `access-model-sod-remediation:policy-url` SHALL target the definition of policy `policy-p`
-   **AND** `access-model-sod-remediation:recipient-id` SHALL be `owner-1`
-   **AND** the notification fields SHALL still be persisted unchanged

## MODIFIED Requirements

### Requirement: Child persist account idempotency

The access-model-sod-remediation operation SHALL skip form launch for a violation when a result-source account already exists on the operation source for child persist identity `` `${requestId}:{accessItemId}:{policyId}` ``. The handler SHALL NOT search form instances for scan idempotency. When skipping, the handler SHALL increment `access-model-sod-remediation:forms-skipped` in the final `ctx.res.send` summary.

When skipping, the handler SHALL refresh the existing child account's descriptive attributes — the access item, policy, and recipient identity fields and the per-side entitlement values — from the current scan, and SHALL carry the stored notification fields over unchanged so the account keeps pointing at the live form. A refresh SHALL NOT create a form instance and SHALL NOT notify the access item owner, which holds because the notification workflow triggers on account creation. A failed refresh SHALL NOT fail the scan.

#### Scenario: Existing child account skips the form and refreshes the record

-   **GIVEN** invoke `requestId` `scan-001` detects violation for access item `role-r` and policy `policy-p`
-   **AND** a result-source account already exists with native identity `scan-001:role-r:policy-p`
-   **WHEN** the scan evaluates that violation on the same invoke or a retry with `requestId` `scan-001`
-   **THEN** the handler SHALL NOT create a form instance for that violation
-   **AND** SHALL increment `access-model-sod-remediation:forms-skipped` in the final `ctx.res.send` summary
-   **AND** SHALL persist identity `scan-001:role-r:policy-p` with the descriptive attributes of the current scan

#### Scenario: Refresh preserves the stored notification fields

-   **GIVEN** an existing child account whose `access-model-sod-remediation:form-url` points at form instance `instance-7`
-   **WHEN** the scan skips that violation and refreshes the record
-   **THEN** the persisted `access-model-sod-remediation:form-url` SHALL still point at `instance-7`
-   **AND** `access-model-sod-remediation:form-email-header`, `access-model-sod-remediation:form-email-body`, and `access-model-sod-remediation:form-email-recipients` SHALL be carried over from the stored account

#### Scenario: Renamed access item is corrected on the next scan

-   **GIVEN** an existing child account persisted when role `role-r` was named `Old Name`
-   **AND** the role is now named `New Name`
-   **WHEN** a later scan skips that violation
-   **THEN** `access-model-sod-remediation:access-item-name` SHALL be `New Name`

#### Scenario: Failed refresh does not fail the scan

-   **GIVEN** a skipped violation whose refresh persist throws
-   **WHEN** the scan continues
-   **THEN** the handler SHALL log the failure and SHALL complete the remaining access items
-   **AND** SHALL still report the violation under `access-model-sod-remediation:forms-skipped`

#### Scenario: Different parent request does not skip

-   **GIVEN** invoke `requestId` `scan-002` detects violation for access item `role-r` and policy `policy-p`
-   **AND** a result-source account exists with native identity `scan-001:role-r:policy-p`
-   **WHEN** the scan runs with `requestId` `scan-002`
-   **THEN** the handler SHALL create a new form instance for the violation
-   **AND** SHALL NOT increment `access-model-sod-remediation:forms-skipped` for that violation solely because of the `scan-001` child account

#### Scenario: No form instance search for idempotency

-   **GIVEN** a connected scan evaluates one or more violations
-   **WHEN** child persist account idempotency runs
-   **THEN** the handler SHALL NOT call `searchFormInstancesByTenantV1` for dedupe purposes

#### Scenario: Offline bypass unchanged

-   **GIVEN** invoke runs in offline or test mode without live account lookup
-   **WHEN** the scan evaluates violations
-   **THEN** the handler SHALL NOT perform child persist account lookup for idempotency
-   **AND** SHALL follow existing offline fixture behavior
