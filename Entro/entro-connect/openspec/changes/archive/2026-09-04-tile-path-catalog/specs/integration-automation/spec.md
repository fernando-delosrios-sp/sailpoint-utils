## MODIFIED Requirements

### Requirement: Lock confirms Integration and path

Connect Lock SHALL confirm the Integration tile and, when the index lists more than one Integration path name, which path the operator chose. Lock MUST NOT confirm `targetSelection`, Setup method, Authentication method, or optional capabilities. When `captureRequired` is true on the index entry, Connect MUST stop before Lock and request connection-form screenshots.

#### Scenario: AWS Lock names path

- **GIVEN** an operator connecting Amazon Web Services
- **WHEN** Lock completes
- **THEN** the stated lock MUST name the tile and the Integration path (for example Terraform)
- **AND** MUST NOT name optional capabilities

#### Scenario: Capture-required tile stops early

- **GIVEN** an operator chooses a capture-required tile
- **WHEN** Orientation completes
- **THEN** Connect MUST request screenshots
- **AND** MUST NOT proceed to Intro or tools

### Requirement: Optional capability consent is just-in-time

When Prep reaches an optional capability the locked path supports, Connect MUST ask the operator whether to enable it before running that capability's instructions or Typed actions. Automated mode MUST pause for the same consent. Bundled scripts that grant optional permissions MUST disclose what they include and MUST NOT claim selective enforcement the script cannot perform.

#### Scenario: AWS optional capability during Prep

- **GIVEN** a locked Amazon Web Services path with Vault management as an optional capability
- **WHEN** Prep would configure vault observability
- **THEN** Connect MUST obtain operator consent immediately before that step
- **AND** MUST skip the step when the operator declines
