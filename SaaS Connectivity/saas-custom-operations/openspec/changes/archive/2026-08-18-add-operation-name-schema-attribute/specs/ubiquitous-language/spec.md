## ADDED Requirements

### Requirement: operationName core attribute term

The glossary SHALL define **operationName core attribute** as the framework-managed STRING account attribute on the DelimitedFile result source that stores the custom command name (`context.commandType`) that last wrote the account.

#### Scenario: operationName used in specs and persist output

- **GIVEN** documentation or specs refer to the invoking custom command on a result account
- **WHEN** naming the persisted account attribute or related framework types
- **THEN** the preferred spelling SHALL be operationName
- **AND** aliases commandType attribute or operation field SHALL NOT be used in normative text without an alias entry

---

## Term entries

### Term: operationName core attribute
**Context**: custom-operation-framework
**Definition**: Mandatory framework-managed STRING attribute on the result source account schema; populated automatically on persist with the full custom command name (e.g. `custom:sod-remediation`).
**Aliases**: none
**Notes**: Not part of `OperationSignature.output`; distinct from prefixed operation output keys such as `sod-remediation:formUrl`.
