# sod-form-html

Shared HTML builders for SoD remediation ISC forms (DESCRIPTION interpolation and launch-time `formInput` strings).

For compact workflow **persistable email body** HTML (STRING ≤ 256, unquoted CTA), use `src/lib/persistable-email/` instead.

## ISC admin UI links

When loopback `apiUrl` is present, `resolveUiOrigin(apiUrl)` derives the tenant UI base URL by removing the `.api.` hostname segment. `renderIscUiLink` builds admin anchors with `target="_blank"` and `rel="noopener noreferrer"`. Offline invoke omits links (plain escaped text only).

Path templates (relative to UI origin):

| Kind | Path |
|---|---|
| Identity | `/ui/a/admin/identities/{id}/details/attributes` |
| SoD policy | `/ui/sod/policy-management/{id}/details` |
| Role | `/ui/a/admin/access/roles/landing-page/details/{id}` |
| Access profile | `/ui/a/admin/access/access-profiles/landing-page/details/{id}` |
| Entitlement | `/ui/a/admin/access/entitlements/landing-page/details/{id}` |
| Violations list | `/ui/sod/violations` |

Id path segments are URL-encoded. Link labels are HTML-escaped.
