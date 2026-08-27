## ADDED Requirements

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
