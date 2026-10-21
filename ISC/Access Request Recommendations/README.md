# Access Request Recommendations

## Purpose

Lists every identity that has AI access request recommendations, one row per recommendation, as a CSV (and optional HTML table).

There is no bulk endpoint for this and recommendations are not in the Search index, so a saved search or report cannot produce the list. The Access Request Recommender answers **one identity at a time**; this script iterates the identities, calls the recommender for each, and keeps the ones that come back with something to act on.

All tenant calls go through the [`sail` CLI](https://developer.sailpoint.com/docs/tools/cli), which supplies auth from its own configured environments. No PSSailpoint module or client credentials are needed.

Read-only: nothing in the tenant is created, changed, or marked viewed.

## Artifacts

| File | Purpose |
| --- | --- |
| [`Get-AccessRequestRecommendations.ps1`](Get-AccessRequestRecommendations.ps1) | Entry script: scope identities, fetch recommendations, write CSV / HTML |

## How it works

1. **Environment** — `sail env list` supplies the tenant list; every call passes `--env`.
2. **Scope** — `POST /search/v1` on the `identities` index for `-SearchQuery` (default `*`), page 250, `id` and `displayName` only.
3. **Fetch** — `GET /ai-access-request-recommendations/v1` per identity, `limit` 15 by default, with translation messages.
4. **Filter** — drops items already `ignored` or `requested`, and identities left with none, matching the Request Center UI.
5. **Write** — one CSV row per surviving recommendation; optional self-contained HTML table.

## Prerequisites

- PowerShell 7+ (`pwsh`)
- The `sail` CLI on `PATH` (`sail -h`), installed for example with `brew install sailpoint-oss/tap/sailpoint-cli`
- At least one configured `sail` environment (`sail env list`), authenticated
- A token that can read identities (search) and access request recommendations

The script is self-contained: it imports nothing else from this repo, so the single `.ps1` can be copied anywhere and run from there.

## Usage

```powershell
cd "ISC/Access Request Recommendations"

# Interactive: prompts for environment, scope, and outputs
./Get-AccessRequestRecommendations.ps1

# Every identity in a named environment
./Get-AccessRequestRecommendations.ps1 -Environment emea-tes-team

# Narrow the iteration, and write an HTML table too
./Get-AccessRequestRecommendations.ps1 `
    -Environment emea-tes-team `
    -SearchQuery 'manager.name:* AND attributes.department:Finance' `
    -HtmlPath ./recommendations.html
```

## Interactive prompts

Run with no parameters and the script asks for anything not passed as a parameter:

| Prompt | Default | Notes |
| --- | --- | --- |
| Select an ISC environment | active environment | Menu of name + API URL + active marker; skipped when only one exists |
| Search expression over the identities index | `*` | Blank means every identity |
| Recommendations per identity (1-15) | `15` | Validated |
| Include the explanation text | yes | |
| Cap the number of identities scanned | `0` (all) | Safety cap for a first run |
| CSV output path | `./access-request-recommendations-<timestamp>.csv` | |
| Also write a self-contained HTML table | no | Follows with an HTML path prompt |

Anything passed as a parameter is not asked again. `-NonInteractive` skips all prompts and uses the defaults, for automation.

## Parameters

| Parameter | Default | Description |
| --- | --- | --- |
| `-Environment` | active environment | Named environment from `sail env list` |
| `-SailpointConfigPath` | `~/.sailpoint/config.yaml` | CLI catalog, read only for the active environment |
| `-SearchQuery` | `*` | ISC search expression over the identities index |
| `-LimitPerIdentity` | `15` | Max recommendations per identity (API cap 15) |
| `-SkipTranslationMessages` | off | Do not request explanation messages |
| `-OutputPath` | `./access-request-recommendations-<timestamp>.csv` | CSV path |
| `-HtmlPath` | — | Optional self-contained HTML table path |
| `-MaxIdentities` | `0` (no cap) | Safety cap on identities iterated |
| `-ThrottleMs` | `0` | Pause between per-identity calls |
| `-MaxRetries` | `4` | Retries for a throttled (HTTP 429) call |
| `-TimeoutSeconds` | `30` | Per-call ceiling for a `sail` invocation |
| `-NonInteractive` | off | Skip the prompts and use defaults |

## Output

CSV columns:

| Column | Meaning |
| --- | --- |
| `Identity` | Identity display name |
| `IdentityId` | Identity id passed to the recommender |
| `AccessName` | Recommended access item name |
| `AccessType` | `ROLE`, `ACCESS_PROFILE`, or `ENTITLEMENT` |
| `SourceName` | Source of an entitlement recommendation (blank for roles and access profiles) |
| `AccessId` | Access item id |
| `Viewed` | Whether the recommendation has been marked viewed |
| `Explanation` | Translation message / interpretation text |

The console prints identities scanned, identities with a recommendation, recommendation count, failures, and output paths. Identities whose call failed are listed (first 20) rather than aborting the run.

## Notes

- **`sail` always exits 0**, even on a 404 or 429, so the script reads the `Status:` line rather than the exit code. It calls `sail api` as one process per request with a `-TimeoutSeconds` ceiling, so a single hung call cannot stall the run.
- **Cost** is one API call per identity. `-SearchQuery 'manager.name:*'` is a cheap scope: the recommender only serves identities that have a manager. (`exists:manager` is not valid search syntax here.)
- **What comes back** is already bounded by the recommender's own config — score threshold (default 0.5) and restriction attribute. Read it with `sail api get /ai-access-request-recommendations/v1/config -H "X-SailPoint-Experimental: true" --env <name>`. An empty result usually means those, or that a demo tenant has no recommendation data yet, not that the script failed.
- **Explanations**: the readable sentence is `messages[].interpretation` ("83% of people like you on your team have this access."). `translationMessages[].values` only carries the interpolation inputs ("83") and is a last-resort fallback. Entitlement recommendations currently return an empty interpretation, so their explanation is blank.
- **Rate limits**: `sail` is one process per call; throttled calls are retried up to `-MaxRetries`; use `-ThrottleMs` to slow the loop on a busy tenant.
- **Paging** stops at the 10,000-record search offset ceiling. Narrow the expression, or switch the paging to `searchAfter`, on a larger tenant.
- The endpoint is experimental; the script sends `X-SailPoint-Experimental: true`.
