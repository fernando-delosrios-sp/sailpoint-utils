## ADDED Requirements

### Requirement: Accounts API delegation for persist

The framework persist implementation SHALL delegate generic AccountsApi lookup and CRUD calls to `src/isc/accounts/` rather than inlining `AccountsApi` method calls or OData filter logic in framework code. Persist orchestration (attribute formatting, provisioning task polling via TaskManagementApi, read-back verification) SHALL remain in the framework.

#### Scenario: Persist lookup delegates to isc accounts

- **GIVEN** ctx.persist is invoked for an identity on the result source
- **WHEN** the framework determines whether an account already exists for that native identity
- **THEN** it SHALL use `findAccountOnSource` from `src/isc/accounts/`
- **AND** persist behavior SHALL remain unchanged from the caller perspective

#### Scenario: Framework does not duplicate account CRUD wrappers

- **GIVEN** the framework needs to create or update an account during persist
- **WHEN** the implementation performs AccountsApi create or put operations
- **THEN** it SHALL call the thin wrappers exported from `src/isc/accounts/`
- **AND** SHALL NOT call `createAccountV1` or `putAccountV1` directly outside `src/isc/accounts/`
