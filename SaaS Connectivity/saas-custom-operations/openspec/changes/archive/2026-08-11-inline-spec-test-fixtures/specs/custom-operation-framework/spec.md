## ADDED Requirements

### Requirement: Inline Vitest unit test fixtures

Vitest unit tests co-located as `*.spec.ts` under `src/` SHALL define mock return values, stub entities, and expected payload objects inline within the spec file. The project SHALL NOT add sibling modules whose primary purpose is supplying data to unit tests (for example `offline-data.ts`, `fixtures.ts`, or `test-data.ts` imported only or primarily by `*.spec.ts` files).

#### Scenario: Spec file contains its own mock data

- **GIVEN** a developer adds or updates a Vitest test for a module under `src/`
- **WHEN** the test needs canned API responses or entity shapes
- **THEN** the mock data SHALL be declared in the co-located `*.spec.ts` file using inline literals, module-level constants, or `vi.fn()` setup in the same file
- **AND** the test SHALL NOT import from a dedicated fixture-only sibling module

#### Scenario: No new test-fixture sibling files

- **GIVEN** a code review or contribution adds unit test coverage
- **WHEN** test data would previously have been placed in a separate file for spec consumption
- **THEN** the contribution SHALL co-locate that data in the spec file instead
- **AND** SHALL NOT introduce new `*-data.ts` or `fixtures.ts` files under `src/` for Vitest-only use

## MODIFIED Requirements

_(none)_

## REMOVED Requirements

_(none)_

## RENAMED Requirements

_(none)_
