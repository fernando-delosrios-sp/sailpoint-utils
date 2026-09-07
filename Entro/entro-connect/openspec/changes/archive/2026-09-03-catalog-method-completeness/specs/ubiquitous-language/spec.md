## ADDED Requirements

### Requirement: Catalog completeness terms

The glossary SHALL carry Documented method, Method waiver, and Fork census, and SHALL keep
them distinct from Coverage. Documents and code MUST use these terms as defined here.

- **Documented method** — a distinct way Entro's published documentation says one Add New
  Account target can be set up or authenticated. It exists in the documentation whether or
  not the curated catalog names it. A Documented method the catalog carries becomes a Setup
  method or an Authentication method; one it does not carry MUST have a Method waiver.
- **Method waiver** — an explicit catalog record that a Documented method or an integration
  documentation page is deliberately not carried as a Setup or Authentication method,
  carrying the reason it is out of scope. Absence without a waiver is a validation failure,
  not a decision.
- **Fork census** — the per-page list of Documented methods a cited page names, each bound
  to a method name or a Method waiver, and each quoting the page text that names it.

Coverage MUST continue to mean an additional surface of an Integration, never catalog
completeness. Requirement names, identifiers, and prose MUST NOT use "coverage" for this
concept; "completeness" or "census" are the terms.

#### Scenario: Documented method distinguished from Setup method

- **GIVEN** an onboarding path Entro's documentation describes
- **WHEN** the catalog does not carry it as a Setup method or Authentication method
- **THEN** it MUST still be called a Documented method
- **AND** it MUST have a Method waiver or validation MUST fail

#### Scenario: Waiver is a reasoned record

- **GIVEN** a Documented method the catalog deliberately omits
- **WHEN** that omission is recorded
- **THEN** it MUST be a Method waiver carrying a reason sentence
- **AND** it MUST NOT be described as an exception, ignore list, or skip list

#### Scenario: Coverage is not reused for completeness

- **GIVEN** a requirement or identifier about catalog completeness
- **WHEN** it is named
- **THEN** it MUST NOT use "coverage"
- **AND** Coverage MUST keep meaning an additional surface of an Integration
