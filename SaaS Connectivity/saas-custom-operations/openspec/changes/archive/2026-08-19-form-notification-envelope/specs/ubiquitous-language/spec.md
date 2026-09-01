## ADDED Requirements

### Requirement: Form notification envelope term

The glossary SHALL define **form notification envelope** as the workflow-facing companion to a launched standalone form instance: form URL, plain-text email subject (**form email header**), compact HTML email body (**form email body** / persistable email body), and **form email recipients**.

#### Scenario: Preferred term for the four-field companion

- **GIVEN** documentation describes the set of persist fields used by Notification workflows after form launch
- **WHEN** naming that set as a unit
- **THEN** the preferred term SHALL be **form notification envelope**
- **AND** SHALL NOT invent alternate umbrella names (e.g. form email bundle) in normative text

### Requirement: Form email header term

The glossary SHALL define **form email header** as the plain-text subject line persisted as `{slug}:form-email-header` for ISC workflow Send Email subject binding.

#### Scenario: Preferred persist key spelling for subject

- **GIVEN** specs name the email subject persist output after form launch
- **WHEN** the ubiquitous language spec is read
- **THEN** the preferred attribute suffix SHALL be `form-email-header`
