# ISC artifacts — Access Model Change Management

Workflow imported into the tenant by the installer.

| File | Purpose |
|------|---------|
| [Workflow - AMCM Approval.json](Workflow%20-%20AMCM%20Approval.json) | Single external trigger → routes on `$.trigger.kind` (`change`, `restore`, `drift`) → governance group → `repository_dispatch` |

There is **one** ISC workflow and **one** external trigger for all three
request types. GitHub Actions tells the workflow which path to take by setting
`kind: "change"`, `kind: "restore"`, or `kind: "drift"` in the trigger payload
(see [`template/scripts/approval.mjs`](../template/scripts/approval.mjs)); the
workflow's first choice step ("Change or Restore") branches on that field.

Approvals use the native `sp:generic-approval` action, so decisions are made in
the ISC **Approvals** inbox. `sp:forms` is not used: it can only address a single
identity, not a governance group.

## Approval order

1. The configured governance group approves or rejects the request. The same
   group is the only approver for a change, a restore, and a drift sync.
2. The decision is posted back to GitHub with `repository_dispatch`.

## Placeholders

Replace before or during install:

| Placeholder | Meaning |
|-------------|---------|
| `YOUR_OWNER_IDENTITY_ID` | Workflow owner identity id |
| `YOUR_OWNER_IDENTITY_NAME` | Workflow owner **alias** — ISC rejects the display name and `attributes.uid` here |
| `YOUR_GOVERNANCE_GROUP_ID` | Approver for changes, restores, and drift sync |
| `YOUR_GITHUB_OWNER/YOUR_GITHUB_REPO` | Target repository, substituted into the dispatch URL |
| `YOUR_GITHUB_DISPATCH_TOKEN` | Full `Authorization` header value the HTTP callback sends, e.g. `Bearer ghp_xxx` — the installer prepends `Bearer ` to the PAT you provide |
| `"YOUR_APPROVAL_TIMEOUT_DAYS"` | Days before an unanswered approval expires (quoted so the file stays valid JSON; replaced with a bare number) |

Admins can later edit the **Configuration** step of the workflow to change the
dispatch target or the token without re-running the installer.

Every `sp:http` dispatch step sends this token as a literal `Authorization`
request header, not via `basicAuthPassword`/`authenticationType: basic`. ISC
only accepts a `$.secrets.<id>` reference in `basicAuthPassword` — a value
that can only be created through the workflow UI's secret picker and is
stripped out by the `/workflows` write API — so a `$.configuration.*`-sourced
value there fails every call with `the secret is not in correct JSON format`.
A plain `Authorization.$` entry in `requestHeaders` has no such restriction.

## Install order

The external trigger's OAuth client must be created **while the workflow is
disabled** — ISC answers `not allowed: failed to patch workflow because it is
enabled` otherwise. The installer therefore upserts the workflow, creates the
trigger client, and only then enables the workflow with a JSON Patch on
`/enabled` (there is no `/enable` endpoint).

The client secret is returned only at creation time and the API offers no list
or delete endpoint for these clients, so **each installer run leaves another
valid client on the workflow**. Prune the old ones from the workflow's Trigger
panel in the ISC UI after a re-install.

## Callback events

The workflow emits three distinct `event_type` values so
[`approval-callback.yml`](../template/.github/workflows/approval-callback.yml)
can route each decision to the right job:

| `event_type` | When |
|--------------|------|
| `isc-change-decision` | Change approval finished (`approved` / `rejected` / `expired`) |
| `isc-restore-decision` | Restore approval finished |
| `isc-drift-decision` | Drift approval finished (`approved` copies ISC into git, `rejected` restores ISC to match git, `expired` changes nothing) |

Payloads include `decision`, content/plan/drift hash, PR or source-ref metadata,
optional `comment`, and `executionId` for GitHub-side verification. The drift
payload carries only `driftHash` (not the full added/changed/deleted lists —
`drift-decision` re-detects drift live against ISC and compares hashes, so
there's no need to round-trip potentially large path lists through ISC).
