## ADDED Requirements

### Requirement: Risk situation summary term

The glossary SHALL define **risk situation summary** as the human-readable plain-text sentence pair persisted at `evaluate-access-request-risk:situation-summary`, stating the tier verdict with its **deciding rule** split and the tally of distinct objects evaluated. Normative text SHALL describe it as read by an approver rather than parsed by a workflow, and SHALL NOT call it a situation summary panel, which is reserved against the SoD **persistable email body**.

#### Scenario: Risk situation summary term

-   **GIVEN** specs or README describe the explanatory text evaluate access request risk persists
-   **WHEN** normative text names that value
-   **THEN** it SHALL use **risk situation summary**
-   **AND** SHALL NOT call it risk explanation or situation summary panel

#### Scenario: Summary is distinguished from contributing ids

-   **GIVEN** documentation relates the two explanatory attributes of the operation
-   **WHEN** normative text states where identifiers live
-   **THEN** it SHALL reserve identifiers for `evaluate-access-request-risk:contributing-ids`
-   **AND** SHALL state the **risk situation summary** carries neither names nor ids

### Requirement: Risk driver term

The glossary SHALL define **risk driver** as one evaluated access object — role, access profile, or entitlement — paired with the tier its own attributes earn and the **deciding rule** that set it. A container whose nested object carries the risk SHALL NOT be described as a risk driver at the nested object's tier.

#### Scenario: Risk driver term

-   **GIVEN** specs describe the objects that determine an access request's tier
-   **WHEN** normative text names one of them
-   **THEN** it SHALL use **risk driver**
-   **AND** SHALL NOT use contributor, risk item, or offender

#### Scenario: Container is not a driver for its contents

-   **GIVEN** a role whose own Risk metadata is absent and whose entitlement scores `High`
-   **WHEN** normative text attributes the tier
-   **THEN** it SHALL name the entitlement as the **risk driver**
-   **AND** SHALL describe the role as evaluated but not as a High risk driver

### Requirement: Deciding rule term

The glossary SHALL define **deciding rule** as the named reason a **risk driver** reached its tier: **effective privilege**, from `privilegeLevel.effective`, or **Risk metadata**, from `iscRisk`. Normative text SHALL state that only entitlements can be decided by effective privilege, that roles and access profiles are always decided by Risk metadata, and that a driver matching both SHALL be attributed to effective privilege.

#### Scenario: Deciding rule term

-   **GIVEN** specs or README explain why an access item reached its tier
-   **WHEN** normative text names that reason
-   **THEN** it SHALL use **deciding rule** with the values **effective privilege** and **Risk metadata**
-   **AND** SHALL NOT use risk source, cause, or trigger

#### Scenario: Attribution is single-valued

-   **GIVEN** an entitlement that satisfies both deciding rules
-   **WHEN** normative text attributes it
-   **THEN** it SHALL attribute the driver to effective privilege only
-   **AND** SHALL NOT describe the driver as counted under both rules
