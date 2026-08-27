## ADDED Requirements

### Requirement: disableLinks input vocabulary

The project glossary SHALL define **disableLinks** as the optional boolean custom-operation input that suppresses ISC UI links in remediation form HTML for a single invoke when set to true.

#### Scenario: disableLinks term

- **GIVEN** specs or README describe opting out of admin deep links on `custom:access-model-sod-remediation` or `custom:sod-remediation`
- **WHEN** normative text names that input
- **THEN** it SHALL use **disableLinks**
- **AND** SHALL define it as suppressing ISC UI links in form HTML without removing form URL or email remediation CTA outputs
