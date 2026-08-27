<!--
Delta spec template for a change.

This template demonstrates 4 types of delta sections. Use them as needed:
- ADDED / MODIFIED / REMOVED / RENAMED
File name and location: openspec/changes/<change-name>/specs/<capability>/spec.md
(`<capability>` aligns with the openspec/specs/<capability>/ directory name)

Hard formatting rules (OpenSpec will validate):
- Requirement sentences MUST contain `SHALL` or `MUST`
- Each Requirement MUST have at least one `#### Scenario:`
- Scenario MUST use level-4 (`####`); level-3 or bullets will silently fail
- Scenarios MUST use Gherkin format: **GIVEN** / **WHEN** / **THEN**
  (use **AND** for additional steps within the same clause)
-->

## ADDED Requirements

<!-- New behaviors. List the new Requirements that this change will add to the capability. -->

### Requirement: <!-- requirement name -->
<!-- requirement text — MUST contain SHALL or MUST -->

#### Scenario: <!-- scenario name -->
- **GIVEN** <!-- starting context / preconditions -->
- **WHEN** <!-- action or trigger -->
- **THEN** <!-- observable outcome -->
<!-- Optional additional steps:
- **AND** <!-- another precondition, action, or outcome in the same clause -->
-->

---

## MODIFIED Requirements

<!--
Modify existing Requirements. **MUST use the exact normalized header as in openspec/specs/<capability>/spec.md** (case-sensitive match after trimming), otherwise the delta apply during archive will fail because it cannot find the corresponding requirement.

**MUST paste the complete modified content** (not just a diff), because OpenSpec archive applies MODIFIED by full text replacement.
-->

### Requirement: <!-- exact header as in the existing spec -->
<!-- Complete modified requirement text — MUST contain SHALL or MUST -->

#### Scenario: <!-- scenario name (can be new or modified) -->
- **GIVEN** <!-- starting context / preconditions -->
- **WHEN** <!-- action or trigger -->
- **THEN** <!-- observable outcome -->
<!-- Optional additional steps:
- **AND** <!-- another precondition, action, or outcome in the same clause -->
-->

---

## REMOVED Requirements

<!--
Remove existing Requirements. MUST include Reason and Migration instructions so the reviewer understands why it's being deprecated and how existing consumers should migrate.
-->

### Requirement: <!-- Header to remove, exactly the same as existing spec -->

**Reason**: <!-- Why it is being deprecated -->

**Migration**: <!-- How existing callers/dependents should adjust -->

---

## RENAMED Requirements

<!--
Rename a Requirement header. Fixed format: FROM / TO using code-fence headers.
If both name and content are changing, list the name change in RENAMED, and **simultaneously** write the complete new content under MODIFIED using the **new** header.

Apply order during archive: RENAMED -> REMOVED -> MODIFIED -> ADDED
-->

- FROM: `### Requirement: <Old Name>`
- TO: `### Requirement: <New Name>`

