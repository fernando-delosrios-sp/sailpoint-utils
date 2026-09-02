## Scope

Identity SoD launch (`custom:sod-remediation`) SHALL stop treating access profiles as parent access items: conflicting entitlements revoke as themselves even when they also sit in an AP; roles remain grantors that suppress direct entitlement revoke. Out of scope: access-model catalog operations, workflow JSON structure, persist/output keys, and detecting sticky vs AP-only assignment via extra ISC calls.

## Language

**Parent access item** (`promote`):
A role or access profile assigned to the target identity that grants a conflicting SoD entitlement and therefore appears as a grantor on the identity access path.
_Avoid_: parent, bundle, container, elevated path (except as informal shorthand)

**AP grantor** (`draft`):
A parent access item whose type is access profile. This change excludes AP grantors from identity SoD path resolution.
_Avoid_: nested AP (access-model term)

**Sticky entitlement** (`draft`):
ISC product behavior: an entitlement previously requested on the identity can remain or return after the granting access profile is revoked. Not a connector domain term; do not promote.
_Avoid_: using “sticky” in specs without naming requested entitlement assignment

**Granted-via-role** (`conflicts-with-canonical`):
Already used in sod-remediation revocability (`reason: granted-via-role`). Keep; AP analog `granted-via-access-profile` becomes unused on identity SoD paths.

**Type tag** (`conflicts-with-canonical`):
Already canonical. Access profile type tags remain valid for access-model SoD HTML; identity SoD group columns SHALL no longer emit access profile path lines.

## Decisions

Context → Revoking the access profile on a Correct path does not clear requested entitlements; they return and the violation persists. Owners still need role-level revoke when a role grants the conflicting entitlement.

Q1: Revoke AP and entitlements, or ignore APs? → Ignore APs as parent access items. Treat entitlements independently. Do not put AP ids in `groupAAccessSearch` / `groupBAccessSearch`.

Q2: Roles? → Keep. Entitlements granted via an assigned role stay not directly revocable; the role id remains the revocable search target.

Q3: Form still show AP as removed? → No. Earlier idea dropped. Form shows entitlements (and roles) only; no AP lines or AP Contains grouping on identity SoD.

Q4: Detect sticky assignment? → No extra identity-history entitlement listing. Resolver simply does not add ACCESS_PROFILE items to the path.

Q5: identity-access fetch still list APs? → Stop listing APs in `fetchIdentityAccessItemsFromSdk` / offline canned data. Only `custom:sod-remediation` consumes that helper; listing APs would be wasted loopback and a footgun.

Q6: Workflow? → No structural change. Get Access already includes entitlements. Search-string values change on next launch.

Q7: AP remains on identity after entitlement revoke? → Accepted residual. Out of scope to also revoke the AP or PATCH the AP definition.

## Open questions

None blocking. Residual AP re-grant after entitlement-only revoke is deferred as operational tenant risk, not a connector requirement.

## Scenarios discussed

- Conflicting E granted only via assigned AP → path is entitlement-only; search `id:{e}`; form shows E, not the AP.
- Conflicting E granted via assigned role (AP also contains E) → ignore AP; nest/mark E granted-via-role; search `id:{role}`.
- Mix on one side: some E via role, some E not via role → search joins role id(s) and standalone entitlement ids.
- Entitlement-only side with no AP/role (today) → unchanged.
- Elevated warning copy → role-level only; drop access-profile wording.
- Keep recommendations → no AP items in the batch from this path.
- Offline canned identity access → must not be AP-only if tests need a grantor; use a role or empty.
