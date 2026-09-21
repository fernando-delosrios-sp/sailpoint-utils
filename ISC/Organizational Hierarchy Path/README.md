# Organizational Hierarchy Path

![Organizational Hierarchy Path](promo.png)

## Purpose

[Transform](https://developer.sailpoint.com/docs/extensibility/rules/cloud-rules/transform-rule) cloud rule invoked by an ISC **Rule** transform. It builds a consolidated organizational hierarchy path on each identity (e.g., `Technology>Engineering`) by walking entitlement parent links.

## Overview

Organizational hierarchies (e.g., department → division → business unit) are often flattened across sources. This **Transform** rule reconstructs the full hierarchy path by walking up a chain of entitlements, where each entitlement exposes its parent organization in a designated entitlement attribute.

The transform passes `sourceId`, hierarchy field names, `hierarchySeparator`, optional `useFinalHierarchySeparator`, and optional `debug` as rule attributes. The entitlement value is the transform `input`, supplied by the identity profile mapping (source attribute plus this transform). The rule is tenant- and source-agnostic — no code edits are required per environment. All environment specifics live in the transform.

The result is a single identity attribute value like `Technology>Engineering`, built dynamically from the entitlement graph.

## Artifacts

- `Rule - Transform - Organizational Hierarchy Path.xml` — Transform cloud rule that computes the organizational hierarchy path (or a debug summary when `debug` is true).
- `Transform.json` — Rule transform that supplies `sourceId`, entitlement field names, `hierarchySeparator`, `useFinalHierarchySeparator`, and `debug`. Identity profile mapping supplies the entitlement value as `input`.

## How It Works

1. The identity profile mapping supplies the entitlement value as transform `input` (for example OrangeHRM `orgUnit`). The transform supplies `sourceId`, field names, separator, and `debug` as rule attributes.
2. The rule reads those attributes and the entitlement value from `input`.
3. Uses these transform attributes to interpret entitlements:
   - **entitlementAccountAttribute** — the account attribute that holds the entitlement value on source accounts.
   - **parentOrganizationAttribute** — the entitlement attribute key that holds the parent organization value.
   - **entitlementDisplayAttribute** — the entitlement attribute key that holds the display name (e.g., `name`).
   - **hierarchySeparator** — the string used to join hierarchy levels (e.g., `>` or ` > `).
   - **useFinalHierarchySeparator** — optional; when `true`, appends `hierarchySeparator` after the last (leaf) level.
4. Walks **up** the entitlement chain starting from the input value: for each entitlement, calls `idn.getManagedAttributeDetails(sourceId, entitlementAccountAttribute, value, Type.Entitlement)` and reads the configured parent and display attributes from `ManagedAttributeDetails.getAttributes()`.
5. Adds each entitlement's display name (from `entitlementDisplayAttribute`) to the path.
6. Stops when an entitlement has no parent (parent attribute is null/empty) or when the maximum depth (20) is reached.
7. Reverses the path (root first, leaf last) and joins with the hierarchy separator. If `useFinalHierarchySeparator` is `true`, appends the separator after the leaf as well.
8. If `debug` is `true`, returns a single-line summary of the configuration, each hop, and the computed path instead of the path alone.

## Debug

Set the transform attribute `debug` to `"true"` in `Transform.json` (or the transform in the admin UI) while investigating a mapping. Preview or process the identity to see what the rule found.

Example output:

```
OHP debug | sourceId=6659e1f4-... | input=Engineering | entitlementAccountAttribute=orgUnit | parentOrganizationAttribute=parent2 | entitlementDisplayAttribute=name | hierarchySeparator=> | useFinalHierarchySeparator=false | 1. value=Engineering display=Engineering parent=Technology | 2. value=Technology display=Technology parent= | path=Technology>Engineering
```

| Field | Meaning |
|---|---|
| `sourceId` / `input` | Transform attribute and entitlement value used for the lookup |
| Field-name attributes | Values from the transform (`entitlementAccountAttribute`, `parentOrganizationAttribute`, `entitlementDisplayAttribute`, `hierarchySeparator`, `useFinalHierarchySeparator`) |
| `N. value=… display=… parent=…` | One hop: entitlement value looked up, display name used in the path, parent used for the next hop |
| `found=false` | `getManagedAttributeDetails` returned no entitlement for that value |
| `stop=…` | Why traversal ended early (`sourceId or input is null/empty`, `required transform attribute missing`, `cycle at …`, `maxDepth 20`) |
| `path=` | Path that would be written when debug is off, or `-` if none |

Set `debug` back to `"false"` before relying on the identity attribute in roles, policies, or certifications. Identity attributes have a length limit; a deep tree in debug mode can truncate.

## Example: OrangeHRM org unit

This pattern is used with an **OrangeHRM** source. The identity attribute **Organization** (`organization`) is mapped from account attribute `orgUnit`, with this transform applied.

### Transform configuration

| Transform attribute | Example value | Purpose |
|---|---|---|
| `sourceId` | UUID of **OrangeHRM** | Target source for entitlement lookups |
| `entitlementAccountAttribute` | `orgUnit` | Account/entitlement schema attribute used for `getManagedAttributeDetails` lookups |
| `parentOrganizationAttribute` | `parent2` | Entitlement metadata key for the parent organization value |
| `entitlementDisplayAttribute` | `name` | Entitlement metadata key for the display name |
| `hierarchySeparator` | `>` | Separator used when joining hierarchy levels |
| `useFinalHierarchySeparator` | `false` | `true` appends the separator after the leaf (`Technology>Engineering>`) |
| `debug` | `false` | `true` writes the debug summary instead of the path |

The entitlement value is **not** hard-coded in the transform. The identity profile mapping passes `orgUnit` as `input`.

### Identity profile mapping

Map the identity attribute (e.g., **Organization** / `organization`):

| Setting | Value |
|---|---|
| Source | **OrangeHRM** |
| Attribute | **orgUnit** |
| Transform | **Organizational Hierarchy Path** |

![Identity profile mapping: OrangeHRM orgUnit with Organizational Hierarchy Path transform](images/identity-profile-mapping.png)

The mapping provides the leaf entitlement value. The transform rule walks parents using the attributes in `Transform.json`.

### Entitlement parent attribute convention

Each entitlement must populate the attribute named by `parentOrganizationAttribute` with the **value** of its parent entitlement (the same value used in `getManagedAttributeDetails` lookups). Top-level entitlements should leave that attribute empty or null.

**Generic example** (`parentOrganizationAttribute` = `parent2`, `entitlementDisplayAttribute` = `name`):

| Entitlement Value | name | parent2 |
|---|---|---|
| `Technology` | Technology | *(empty — top level)* |
| `Engineering` | Engineering | `Technology` |

**Resulting hierarchy path** for an identity whose OrangeHRM `orgUnit` is `Engineering`:

`Technology>Engineering`

Display names are read from the `name` entitlement attribute via `entitlementDisplayAttribute`. Do **not** use `ManagedAttributeDetails.getName()` — it returns the schema attribute name (`orgUnit`), not the organization display name.

## Configuration

### Transform attributes

Set these on the **Rule** transform (`Transform.json` or the admin UI). They are not source connector attributes.

| Attribute | Description |
|---|---|
| `sourceId` | UUID of the source that holds the organization entitlements. |
| `entitlementAccountAttribute` | Name of the account attribute that holds the entitlement value on source accounts. |
| `parentOrganizationAttribute` | Name of the entitlement attribute key that holds the parent organization value (e.g., `parent2`). |
| `entitlementDisplayAttribute` | Name of the entitlement attribute key that holds the display name (e.g., `name`). |
| `hierarchySeparator` | Separator string for the output path (e.g., `>`, ` > `, `/`). |
| `useFinalHierarchySeparator` | Optional. `"true"` appends `hierarchySeparator` after the last level; omit or `"false"` to join levels only. |
| `debug` | Optional. `"true"` to return a path-build summary; omit or `"false"` for the path. Omitted attributes are not bound in Beanshell — the rule defaults them rather than requiring the key. |

### Setup Steps

1. Create a new **Transform** cloud rule named **Organizational Hierarchy Path** and paste in the rule XML from `Rule - Transform - Organizational Hierarchy Path.xml` (no code edits required). SailPoint must review and deploy Transform rules; an existing IdentityAttribute or Generic rule cannot be edited in place to change type.
2. Create a **Rule** transform named **Organizational Hierarchy Path** from `Transform.json`. Replace `<SOURCE_ID>` with the UUID of your target source, `<ENTITLEMENT_ACCOUNT_ATTRIBUTE>` with the account/entitlement schema attribute (e.g., `orgUnit`), `<PARENT_ORGANIZATION_ATTRIBUTE>` with the parent key on entitlements (e.g., `parent2`), and `<ENTITLEMENT_DISPLAY_ATTRIBUTE>` with the display-name key (e.g., `name`). Leave `debug` as `"false"` unless you are troubleshooting. You can find the source UUID in the source's URL in the admin UI (e.g., `https://tenant.identitynow.com/ui/admin/#/sources/6659e1f4...`).
3. Map entitlement aggregation fields so `name` and the parent key (e.g., `parent2`) are populated on each entitlement.
4. Ensure each entitlement's parent attribute contains its parent's **entitlement value**, not a display path or description string.
5. Map the identity attribute with the HR source (e.g., **OrangeHRM**), the entitlement account attribute (e.g., **orgUnit**), and transform **Organizational Hierarchy Path**.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `organization>organization` / `orgUnit>orgUnit` | Display name read from `getName()` instead of `entitlementDisplayAttribute`. Ensure `entitlementDisplayAttribute` is set on the transform (e.g., `name`) and populated on entitlements. |
| `-` (default) | Missing transform attribute, missing/blank `sourceId` or transform `input`, or identity has no value in the mapped attribute. Set `debug` to `true` to see `stop=` and hop details. |
| Truncated path | Broken parent reference — `parentOrganizationAttribute` value does not match any entitlement value on the source. |
| Wrong order | Expected behavior: path is built leaf-to-root during traversal, then reversed to root-first before joining. |
| Debug text on the identity | `debug` is still `"true"` on the transform. Set it to `"false"` and refresh the identity. |
| `NullPointerException` / `Cannot read the array length because "str" is null` | Usually thrown inside `getManagedAttributeDetails` when an entitlement value or parent reference does not resolve cleanly (for example `orgUnit=18` with no matching entitlement, or `parent_id` pointing at a missing value). Redeploy the hardened rule (lookup is try/caught). With `debug` `"true"`, look for `lookupError=` or `found=false`. Prefer string `"true"`/`"false"` for `debug` and `useFinalHierarchySeparator` on the transform. |

## Notes

- This is a **Transform** cloud rule, not an IdentityAttribute rule. Map it as a transform on the identity profile (source + attribute + transform), not as Complex Data Source alone.
- The rule is generic and reusable across sources and tenants — configure source ID and field names via the transform, and the leaf value via the identity profile mapping.
- Entitlement lookups use [`getManagedAttributeDetails`](https://developer.sailpoint.com/rule-java-docs/sailpoint/rule/ManagedAttributeDetails.html) with [`ManagedAttribute.Type.Entitlement`](https://developer.sailpoint.com/rule-java-docs/sailpoint/object/ManagedAttribute.Type.html). Display names and parent values are read from the attributes map via `entitlementDisplayAttribute` and `parentOrganizationAttribute` — not from `getName()` or `getDescription()`.
- Cycle detection is built in — if two entitlements reference each other as parents, traversal stops safely.
- Maximum traversal depth is 20 levels to prevent runaway chains.
- If any required transform attribute is missing or the transform input has no entitlement value, the rule returns `-` (the default value), unless `debug` is true, in which case it returns the summary instead.
- This rule depends on the parent organization attribute being maintained correctly on each entitlement. Any broken parent reference will truncate the path at the break.
