# Organizational Hierarchy Path

IdentityAttribute rule for SailPoint ISC that builds a consolidated organizational hierarchy path for an identity by traversing entitlement parent relationships stored in the description field.

## Overview

Organizational hierarchies (e.g., department → division → business unit) are often flattened across sources. This rule reconstructs the full hierarchy path by walking up a chain of entitlements, where each entitlement's **description** field contains the name of its parent entitlement.

The result is a single identity attribute value like `Corporate > Finance > AP > Payroll`, built dynamically from the entitlement graph.

## Artifacts

- `Rule - IdentityAttribute - Organizational Hierarchy Path.xml` — IdentityAttribute rule that computes the organizational hierarchy path.

## How It Works

1. Reads three source attribute configurations from the source identified by `SOURCE_ID`:
   - **identityAttribute** — the identity attribute that holds the entitlement reference (e.g., `organization`).
   - **entitlementAccountAttribute** — the account attribute that holds the entitlement value on source accounts.
   - **hierarchySeparator** — the string used to join hierarchy levels (e.g., ` > ` or `/`).
2. Retrieves the entitlement value from the identity using the configured `identityAttribute`.
3. Walks **up** the entitlement chain: for each entitlement, looks up its managed attribute details and reads the **description** field to find the parent entitlement name.
4. Adds each entitlement's display name to the path.
5. Stops when an entitlement has no parent (description is null/empty) or when the maximum depth (20) is reached.
6. Reverses the path (root first, leaf last) and joins with the hierarchy separator.

## Entitlement Description Convention

Each entitlement's **description** field must contain the **name of its parent entitlement**. Top-level entitlements should have an empty or null description.

**Example entitlement setup:**

| Entitlement Value | Display Name | Description (Parent) |
|---|---|---|
| `corp` | Corporate | *(empty — top level)* |
| `finance` | Finance | `corp` |
| `ap` | Accounts Payable | `finance` |
| `payroll` | Payroll | `ap` |

**Resulting hierarchy path for an identity with entitlement `payroll`:**

`Corporate > Finance > Accounts Payable > Payroll`

## Configuration

### Source Attributes

Define the following source attributes on the target source in IdentityNow (via the admin UI):

| Attribute | Description |
|---|---|
| `identityAttribute` | Name of the identity attribute that references the entitlement value (e.g., `organization`). |
| `entitlementAccountAttribute` | Name of the account attribute that holds the entitlement value on source accounts. |
| `hierarchySeparator` | Separator string for the output path (e.g., ` > `, `/`, `\`). |

### Setup Steps

1. Create a new IdentityAttribute rule named **Organizational Hierarchy Path** and paste in the rule XML from `Rule - IdentityAttribute - Organizational Hierarchy Path.xml`.
2. **Replace `SOURCE_ID`** in the rule source with the UUID of your target source. You can find this in the source's URL in the admin UI (e.g., `https://tenant.identitynow.com/ui/admin/#/sources/6659e1f4...`).
3. Configure the three source attributes (`identityAttribute`, `entitlementAccountAttribute`, `hierarchySeparator`) on your source.
4. Populate each entitlement's **description** field with the name of its parent entitlement. Leave top-level entitlement descriptions empty.
5. Create a new identity attribute that uses this rule and map it in your identity profile.

## Notes

- The `SOURCE_ID` constant is hardcoded and **must be updated** for each tenant/environment.
- Cycle detection is built in — if two entitlements reference each other as parents, traversal stops safely.
- Maximum traversal depth is 20 levels to prevent runaway chains.
- If any required source attribute is missing or the identity has no entitlement value, the rule returns `-` (the default value).
- This rule depends on entitlement descriptions being maintained correctly. Any broken parent reference will truncate the path at the break.
