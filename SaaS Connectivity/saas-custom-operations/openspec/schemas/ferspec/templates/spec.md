<!--
Delta spec — one file per capability at specs/<capability>/spec.md
OpenSpec validates structure; scenarios use Gherkin steps inside the Markdown wrapper.
-->

## ADDED Requirements

### Requirement: <!-- requirement name -->
<!-- MUST contain SHALL or MUST -->

#### Scenario: <!-- scenario name -->
- **GIVEN** <!-- starting context / preconditions -->
- **WHEN** <!-- action or trigger -->
- **THEN** <!-- observable outcome -->
<!-- **AND** for additional steps in the same clause -->

---

## MODIFIED Requirements

<!--
Copy the ENTIRE requirement block from openspec/specs/<capability>/spec.md (header through
all scenarios), paste here, edit to the full desired behaviour. Partial diffs fail at archive.
Header must match exactly (whitespace-insensitive).
-->

### Requirement: <!-- exact header from canonical spec -->

#### Scenario: <!-- scenario name -->
- **GIVEN**
- **WHEN**
- **THEN**

---

## REMOVED Requirements

### Requirement: <!-- exact header to remove -->

**Reason**: <!-- why deprecated -->

**Migration**: <!-- how consumers adapt -->

---

## RENAMED Requirements

- FROM: `### Requirement: <Old Name>`
- TO: `### Requirement: <New Name>`

<!-- If content also changes, add the new block under MODIFIED using the new header. -->
