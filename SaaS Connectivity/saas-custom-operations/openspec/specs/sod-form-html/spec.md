# sod-form-html Specification

## Purpose
TBD - created by archiving change unify-sod-form-html. Update Purpose after archive.
## Requirements
### Requirement: SoD form HTML shared library

The connector SHALL provide shared SoD remediation form HTML builders under `src/lib/sod-form-html/`. The library SHALL assemble HTML strings for ISC form DESCRIPTION interpolation and SHALL NOT invoke ISC APIs or encode operation persist logic.

#### Scenario: Type tag rendering

- **GIVEN** an access object kind of `ROLE`, `ACCESS_PROFILE`, or `ENTITLEMENT`
- **WHEN** a line is rendered through the shared library
- **THEN** the output SHALL include an inline pill-style span identifying the kind
- **AND** SHALL NOT prefix the display name with `Role:` or `Access Profile:` text

#### Scenario: Outcome panel wrapping

- **GIVEN** list HTML content and outcome `keep` or `remove`
- **WHEN** the library wraps content in an outcome panel
- **THEN** the output SHALL use a green background for `keep` and a red background for `remove`
- **AND** SHALL include a left accent border consistent with the outcome color

#### Scenario: Plain variant has no panel

- **GIVEN** list HTML content and variant `plain`
- **WHEN** the library assembles a side HTML variant
- **THEN** the output SHALL NOT include an outcome panel background wrapper

#### Scenario: Icon suffix formatting

- **GIVEN** zero or more emoji markers for a line
- **WHEN** the library formats an icon suffix
- **THEN** multiple markers SHALL be space-separated (e.g. `⭐ ✅`)
- **AND** SHALL NOT concatenate markers without intervening spaces

#### Scenario: Emoji legend block

- **WHEN** `renderEmojiLegend` is invoked
- **THEN** the output SHALL decode revocability, keep recommendation, and privileged icons with explanatory text
- **AND** SHALL be suitable for appending once to a block-level HTML summary

#### Scenario: Side variant assembly

- **GIVEN** rendered list body HTML for one policy side
- **WHEN** the library builds side variants
- **THEN** it SHALL return `plain`, `asKept`, and `asRemoved` HTML strings
- **AND** `asKept` and `asRemoved` SHALL differ only by outcome panel styling

#### Scenario: HTML escape helper

- **WHEN** user-controlled names are embedded in HTML output
- **THEN** the library SHALL escape `&`, `<`, `>`, and `"` characters

### Requirement: Access model entitlement tree flat access profile lines

The sod-form-html library SHALL render nested access profiles in `renderEntitlementTree` as a single flat list row per profile when the profile contributes one or more side-matching entitlement ids. Each row SHALL include the access profile display name, an access profile type tag, an offending entitlement mention naming the matching entitlement display names, and an entitlement type tag. The library SHALL NOT emit nested `<ul>` elements under an access profile row.

#### Scenario: Flat access profile line with one offending entitlement

- **GIVEN** expansion includes nested access profile `ap-x` named `SAP Suite` with entitlement `ent-c` named `Accounts Payable`
- **AND** side entitlement ids include `ent-c`
- **WHEN** `renderEntitlementTree` builds list body HTML
- **THEN** the output SHALL include one `<li>` for `SAP Suite` with an access profile type tag
- **AND** SHALL include an offending mention containing `Accounts Payable`
- **AND** SHALL NOT include a nested `<ul>` under the access profile row

#### Scenario: Multiple offending entitlements on one access profile line

- **GIVEN** nested access profile `ap-x` has side-matching entitlements `ent-1` and `ent-2`
- **WHEN** `renderEntitlementTree` builds list body HTML
- **THEN** the output SHALL include one access profile row
- **AND** the offending mention SHALL name both entitlements in comma-separated form

#### Scenario: Direct role entitlement line unchanged

- **GIVEN** a side-matching entitlement id granted directly on the role (not under a nested access profile row)
- **WHEN** `renderEntitlementTree` builds list body HTML
- **THEN** the output SHALL include a single entitlement row with an entitlement type tag
- **AND** SHALL NOT include an offending mention phrase
