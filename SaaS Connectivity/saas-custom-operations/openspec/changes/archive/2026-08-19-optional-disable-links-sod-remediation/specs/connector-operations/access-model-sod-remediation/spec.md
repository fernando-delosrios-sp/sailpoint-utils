## ADDED Requirements

### Requirement: Optional disableLinks input for access-model SOD remediation

The access-model-sod-remediation operation SHALL accept an optional boolean input `disableLinks`. When `disableLinks` is `true`, the handler SHALL omit UI origin for form HTML assembly so ISC UI links are not rendered in `situationSummaryHtml` or group column HTML, even when invoke `apiUrl` would otherwise resolve a UI origin. When `disableLinks` is omitted or `false`, link behavior SHALL match existing rules (links when UI origin is available). The flag SHALL NOT remove `access-model-sod-remediation:form-url` or the remediation form CTA from `access-model-sod-remediation:form-email-body`.

#### Scenario: Omitted disableLinks keeps admin links online

- **GIVEN** invoke has resolvable `apiUrl` and input omits `disableLinks`
- **WHEN** form HTML is assembled for a violation
- **THEN** `situationSummaryHtml` and group column HTML SHALL include ISC UI links for linked entity display names

#### Scenario: disableLinks false keeps admin links online

- **GIVEN** invoke has resolvable `apiUrl` and input sets `disableLinks` to `false`
- **WHEN** form HTML is assembled for a violation
- **THEN** `situationSummaryHtml` and group column HTML SHALL include ISC UI links for linked entity display names

#### Scenario: disableLinks true omits admin links online

- **GIVEN** invoke has resolvable `apiUrl` and input sets `disableLinks` to `true`
- **WHEN** form HTML is assembled for a violation
- **THEN** entity display names in `situationSummaryHtml` and group column HTML SHALL render as plain escaped text
- **AND** those fields SHALL NOT include ISC admin UI `<a href=` anchors

#### Scenario: disableLinks does not remove form URL or email CTA

- **GIVEN** input sets `disableLinks` to `true` and a remediation form is created
- **WHEN** the handler persists child form output
- **THEN** child output SHALL still include `access-model-sod-remediation:form-url`
- **AND** `access-model-sod-remediation:form-email-body` SHALL still include the remediation form CTA link
