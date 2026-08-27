## Scope

Flatten access-model SoD remediation form group columns so nested access profiles appear as a single line with an offending-entitlement mention (not a nested bullet tree). In scope: `renderEntitlementTree`, access-model-sod-remediation HTML launch path, specs, and tests. Out of scope: `custom:access-model-sod-correct`, catalog patch APIs, form seed JSON changes, new `formName`, and `custom:sod-remediation` flat access-path lists.

## Language

**Flat access profile line** (`promote`):
A single list row for a nested access profile on a policy side, showing the access profile name, type tag, and an inline mention of which offending entitlement(s) on that side come from the profile.
_Avoid_: nested AP tree, AP bullet group

**Offending entitlement mention** (`promote`):
The inline phrase on a flat access profile line that names the policy-side entitlement id(s) driving the violation (e.g. `— offending: payment_issue`).
_Avoid_: nested entitlement bullet, child entitlement row

**Group column HTML** (`draft`):
Pre-rendered side-by-side DESCRIPTION fields on access-model SoD remediation form launch (`groupColumnsHtmlPlain`, `groupColumnsHtmlWhenGroupARemoved`, `groupColumnsHtmlWhenGroupBRemoved`).
_Avoid_: form HTML, column preview (informal)

## Decisions

**Context:** Policy owners reviewing role violations need to see that remediating a side will remove a whole access profile from the role when the conflict is AP-granted—not trim an entitlement inside the shared AP definition. A follow-on `custom:access-model-sod-correct` operation is planned; form presentation must lead it.

**Q1 — Presentation shape for AP-granted side entitlements?**
→ Chosen: One flat `<li>` per nested AP with `— offending: <entitlement name(s)>` inline; no nested `<ul>` under the AP.

**Q2 — Direct role entitlements on a side?**
→ Chosen: Unchanged single flat entitlement line with type tag only.

**Q3 — Multiple offending entitlements from the same AP on one side?**
→ Chosen: Comma-separated names in one offending mention on the same AP line.

**Q4 — formInput `groupAIds` / `groupBIds` contract?**
→ Chosen: Unchanged entitlement id lists (detection unchanged); HTML presentation only.

**Q5 — Form definition / formName migration?**
→ Chosen: No seed or formName change; HTML is built at instance create time from updated builders. Existing ASSIGNED instances keep prior HTML until recreated.

**Q6 — Outcome panels when recipient selects `remediationSide`?**
→ Chosen: Entire AP line (or direct entitlement line) receives green/red panel styling as today—AP row is one removable unit visually.

## Open questions

None — deferred `custom:access-model-sod-correct` to a separate change.

## Scenarios discussed

- Role with direct entitlement on side A and nested AP entitlement on side B: A shows direct line; B shows flat AP line with offending mention.
- AP with two offending entitlements on the same side: one AP line, comma-separated offending names.
- Side with no matching entitlements: existing empty-state copy and outcome panels unchanged.
- Selecting `groupA` for removal: Group A lines (including AP lines on A) show red removed panel; Group B lines show green kept panel.
- Offline scan / `call:op`: updated HTML in formInput without live ISC role patch.
- ACCESS_PROFILE access item violations: nested AP bundles empty; only direct entitlement lines apply (unchanged expansion model).
