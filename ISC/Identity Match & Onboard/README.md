# Identity Match & Onboard

## Purpose

Reference implementation for ISC **interactive identity onboarding** with a **duplicate check** before account creation. An operator collects personal details, ISC searches for similar identities, and the flow either creates a source account or confirms an existing match — all using native workflows, forms, and the Accounts API.

## Overview

The **Identity Match & Onboard** workflow is launched from an interactive process. It:

1. Collects first name, last name, work email, location, and manager.
2. Searches ISC for identities with a fuzzy name match or exact email.
3. If matches exist, presents a review form to pick an existing identity or mark the person as new.
4. Creates a source account via `POST /accounts/v1`, or shows the matched identity with a deep link to their attributes page in the ISC admin UI.

Forms use HTML **DESCRIPTION** widgets for operator guidance. The duplicate-review form lists name and email only; the full profile link appears after a match is confirmed.

A demo recording of the end-to-end flow is included as [`Identity Match & Onboard.mov`](Identity%20Match%20%26%20Onboard.mov).

## Artifacts

| File | Type | Purpose |
|---|---|---|
| `Workflow - Identity Match & Onboard.json` | Workflow export | Interactive onboarding workflow |
| `Forms - Identity Match & Onboard.json` | Form export (array) | Both forms — use for VS Code form import |
| `Identity Match & Onboard.mov` | Demo video | Walkthrough of the interactive experience |

> **Form import format:** The SailPoint VS Code extension expects form exports as a **JSON array** (`[{ version, self, object }, …]`), not a single object. Import `Forms - Identity Match & Onboard.json` to load both forms at once. All fields (including DESCRIPTION widgets) must be nested inside a **SECTION** element. HTML ampersands must be escaped as `&amp;`.

### Exported objects

- **Workflow:** `Identity Match & Onboard`
- **Form definitions:** `Identity Match & Onboard - Details input`, `Identity Match & Onboard - Identity deduplication`

## Architecture

```mermaid
flowchart TD
  startNode[Collect details] --> config[Set configuration]
  config --> search[Search matching identities]
  search --> hasHits{Hits greater than 0?}
  hasHits -->|no| createAcct[Create account]
  hasHits -->|yes| review[Review possible duplicates]
  review --> exists{Identity exists?}
  exists -->|no| createAcct
  exists -->|yes| loadMatch[Load matched identity]
  loadMatch --> showMatch[Show matched identity]
  createAcct --> showCreated[Confirm account created]
  showMatch --> doneNode[Success]
  showCreated --> doneNode
```

## Workflow steps

| Step | Operator | What it does |
|---|---|---|
| Collect Details | Interactive form | Details input form |
| Set Configuration | — | Builds search query, display name, sanitized username, tenant URLs |
| Search Identities | — | `sp:get-identities` with identity search query |
| Check Duplicate Count | — | Branches on match count |
| Review Duplicates | Interactive form | Deduplication form (only when matches found) |
| Check Identity Exists | — | Branches on the “This is a new hire” toggle — true when the toggle is No |
| Create Account | — | `POST /accounts/v1` with OAuth |
| Load Matched Identity | — | `sp:get-identity` for selected duplicate |
| Show Matched Identity | Interactive message | Summary + ISC admin link |
| Show Account Created | Interactive message | Confirmation summary |
| End Success | — | Workflow complete |

**Trigger:** `idn:interactive-process-launched` (interactive process event).

## Forms

### Details input

Collects:

| Field | Type | Source |
|---|---|---|
| First name | TEXT | User input |
| Last name | TEXT | User input |
| Work email | EMAIL | User input; required + email format |
| Location | TEXT | User input |
| Manager | SELECT | `SEARCH_V2` on identities, query `isManager:true` |

The manager field stores the identity **uid** (`attributes.uid`). Display name and email are shown via `attributes.displayName` and `attributes.email`.

### Identity deduplication

Shown only when the search returns one or more matches. The form is **decision-first**: choose whether this is a new hire, then (if not) pick the matching person.

| Field | Type | Notes |
|---|---|---|
| This is a new hire | TOGGLE | Leads the form. Yes = create a new record; No = choose a match |
| Matching person | SELECT | Shown only when the toggle is No. Populated from search results (label: name, sublabel: email, value: id) |

Path-specific DESCRIPTION widgets:

- **New hire** (toggle Yes): confirms a new directory record will be created
- **Match helper** (toggle No): short prompt above the person picker

**Form conditions:**

- `newIdentity = true` → hide match helper + person picker; picker optional
- `newIdentity = false` → hide new-hire confirmation; require person picker

After a match is confirmed, the **Already in the directory** message includes a profile link:

```
{ISC UI URL}/ui/a/admin/identities/{identityId}/details/attributes
```

## Duplicate search

The **Identity Query** variable combines fuzzy name and exact email:

```
(attributes.firstname:{firstName}~2 AND attributes.lastname:{lastName}~2) OR attributes.email:"{email}"
```

The `~2` operator allows approximate name matches. Email is matched exactly. Tune the query if your tenant indexes different attribute names.

## Username generation

**Account Name** is derived from `firstName.lastName` and sanitized with Define Variable **Replace** transforms:

1. Remove spaces.
2. Remove characters outside `[A-Za-z0-9.]`.
3. Lowercase A–Z (26 individual replace steps — ISC workflows have no native `toLower`).

Accented characters are stripped rather than transliterated. Adjust transforms if your naming policy differs.

## Account creation

The **Create Account** HTTP step posts to:

```
{ISC API URL}/accounts/v1
```

Request body attribute keys match this **Accounts Source** schema:

| Form / variable | Account attribute | Notes |
|---|---|---|
| Configuration | `sourceId` | Target source UUID (API field, not a schema attribute) |
| Account Name (derived) | `id`, `name` | Unique account id and username (same generated value) |
| First name | `givenName` | |
| Last name | `familyName` | |
| Work email | `e-mail` | Hyphenated schema name |
| Location | `location` | |
| Manager | `manager` | Identity **uid** (`attributes.uid`) |

`groups` is an entitlement attribute and is not set by this workflow.

`manager` is the selected manager identity **uid**, suitable for manager correlation on a delimited-file source.

> **Important:** The Accounts API creates a record **in ISC** on the named source. It does not provision downstream connector targets. On connector sources, aggregation may remove API-created accounts that do not exist on the target. Flat-file sources are the typical use case.

## Installation

Import order matters. The workflow references form definition IDs, so forms must exist in the tenant first.

1. Import **`Forms - Identity Match & Onboard.json`** (both form definitions).
2. Import **`Workflow - Identity Match & Onboard.json`**.
3. Complete the tenant configuration below (source id, API/UI URLs, OAuth).
4. Enable the workflow and link it to your interactive process.

## Configuration

### Tenant values (Set Configuration step)

| Variable | Example | Purpose |
|---|---|---|
| ISC API URL | `https://{tenant}.api.identitynow-demo.com` | Accounts API base URL |
| ISC UI URL | `https://{tenant}.identitynow-demo.com` | Base URL for post-match profile links |
| Accounts Source | Source UUID | Replace `xxx` with your target source id |

### OAuth

Configure OAuth credentials on the **Create Account** HTTP step (`paramID`, client id/secret, token URL). The client needs permission to create accounts on the target source.

### Prerequisites

- Manager search uses `isManager:true` so operators only see identities flagged as managers.
- A delimited-file (or compatible) **Accounts Source** with attributes aligned to the HTTP body.
- An **interactive process** that launches this workflow.
- Identity profile on the source if you expect identities to be created after aggregation.

### Post-import checklist

- [ ] Forms imported before the workflow.
- [ ] Replace `Accounts Source` placeholder (`xxx`) with your source UUID.
- [ ] Set **ISC API URL** and **ISC UI URL** for your tenant.
- [ ] Bind OAuth on the Create Account HTTP step.
- [ ] Enable the workflow and link it to your interactive process.
- [ ] Confirm account schema attribute names match the HTTP body (`id`, `name`, `givenName`, `familyName`, `e-mail`, `location`, `manager`).
- [ ] Test: no-match path creates account; match path shows review form and identity link.

## Limitations

- **Match path is informational** — selecting an existing identity does not correlate accounts, request access, or update records.
- **No HTTP error branch** — failed account creation is not handled in this sample.
- **Fuzzy name search** can over-match; there is no birthdate or employee-id tie-breaker.
- **Match confirmation** includes a reliable profile link using the loaded identity id (`…/identities/{id}/details/attributes`).
- **OAuth `paramID`** is tenant-specific and left empty in the export.

## Related patterns

- [Dynamic forms and user data collection](../Dynamic%20forms%20and%20user%20data%20collection/) — Accounts API persistence and `SEARCH_V2` form dropdowns.
- [Generic Manager Correlation](../Generic%20Manager%20Correlation/) — manager lookup and correlation across sources.
