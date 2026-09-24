# MelonHRM HR source

Synthetic HR account feed for a SailPoint **Web Services** source. One PostgreSQL table, 15 identities, same attribute names as a typical JDBC HR aggregation so an identity profile can map this source the same way as OrangeHRM.

The dataset is built for Identity Fusion NG against the `emea-tes-team` OrangeHRM baseline: five MelonHRM-only people, four natural account-name correlations, two reciprocal deferred matches, two automatic matches, and two manual-review candidates (one true positive, one false positive).

## Population

| Group | Count | Description |
| --- | --- | --- |
| New non-match | 5 | MelonHRM-only people with no OrangeHRM/Fusion baseline candidate (`elena.varga`, `hugo.moretti`, `keiko.sato`, `amara.diallo`, `noah.lindberg`) |
| Natural correlation | 4 | Same account name as an existing OrangeHRM account (`jerry.bennett`, `aaron.nichols`, `jane.grant`, `carolyn.perry`) |
| Deferred reciprocal | 2 | Non-matching to baseline; match each other (`nadia.petrova` ↔ `nadya.petrova`) |
| Automatic match | 2 | Fuzzy first-name overlays expected to auto-merge (`deb.wood` → `debra.wood`, `randall.knight` → `randy.knight`) |
| Manual true positive | 1 | Fuzzy overlay for manual accept (`patti.jones` → `patricia.jones`) |
| Manual false positive | 1 | Name-like lookalike for manual reject (`kate.simmons` vs `catherine.simmons`) |

### Managers

Exactly two managers are referenced:

- `MEL0001` / `elena.varga` — MelonHRM-only root (non-match)
- `MEL0006` / `jerry.bennett` — naturally correlated manager reporting to Elena

Every other identity reports to one of those two.

### Title variance on positive matches

For natural correlations, automatic matches, and the true-positive manual match, MelonHRM `title` is **different but semantically similar** to the OrangeHRM candidate title (for example `Senior Executive` → `Chief Executive`). Reciprocal deferred pairs share the same title with each other. New non-matches and the false-positive manual case are unconstrained by that rule.

### Countries and contact data

`country` stores the **full country name** (`Belgium`, `Singapore`, `United States`, `Japan`, `Germany`), not ISO codes.

OrangeHRM carries no birth date, national identifier, or phone data. This feed populates `mobile`, `telephone`, and `zipcode` for part of the population so contact data never implies a match by itself.

One identity is a contractor with contract dates (`noah.lindberg`). Overlay / positive-match people reuse `@sailpointdemo.com` personal addresses; MelonHRM-only people use `@melonmail.example`.

## Artifacts

- `melonhrm.sql` — self-contained script: creates `public."MelonHRM"` and inserts the 15 rows. Run it on any PostgreSQL database (including the Supabase SQL editor).
- `isc/account-schema.json` — account schema for the SailPoint source.
- `fixtures/orangehrm-counterparts.csv` — expected Fusion outcome for every MelonHRM identity (scenario, candidate, disposition, manual decision, and title comparison).
- `supabase/` — optional local pgTAP project that loads `melonhrm.sql`.

## Account table

`public."MelonHRM"` is one flattened table. Values follow a JDBC-style HR feed:

- `username` is lowercase ASCII `givenName.familyName` with spaces and accents stripped.
- `manager` is the manager's `employee_id`.
- `term` is the string `'true'` or `'false'`, not a boolean.
- `empstatus` is the numeric status id and `type` is its name (`5` Active Employee, `6` Active Contractor, `7` Inactive Employee).
- Every attribute is text.
- `contractStartDate` and `contractEndDate` keep those names so they match the SailPoint schema.
- The table name and the `givenName`, `familyName`, `contractStartDate`, and `contractEndDate` columns are mixed case, so every reference to them must be double-quoted. Unquoted, PostgreSQL folds them to lower case and the query fails.

## Load the table

Paste or run `melonhrm.sql` against PostgreSQL:

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f melonhrm.sql
```

The script drops and recreates `public."MelonHRM"`, so it is safe to re-run. On Supabase it also enables RLS and grants `SELECT` only to `service_role` when that role exists. On vanilla PostgreSQL those grants are skipped.

If you use hosted Supabase, run the same file in the SQL editor. Create a dedicated `sb_secret_...` key for the connector. Store it only in the source credential configuration; never commit or log it.

Verify the REST feed (replace the project URL and key):

```bash
curl --fail-with-body \
  'https://<project-ref>.supabase.co/rest/v1/MelonHRM?select=*&order=employeenumber.asc' \
  -H 'apikey: <supabase-secret-key>' \
  -H 'Accept: application/json'
```

Supabase secret keys belong in the `apikey` header, not `Authorization: Bearer`. New tables are not always exposed to the Data API automatically; the script grants `service_role` for that.

## Configure the SailPoint source

Create an authoritative **Web Services** source named `MelonHRM` with:

- Base URL: `https://<project-ref>.supabase.co` (or any HTTP endpoint that returns the table)
- Account aggregation method: `GET`
- Context URL: `/rest/v1/MelonHRM?select=*&order=employeenumber.asc`
- Header: `apikey: <supabase-secret-key>`
- Response root: `$`
- Account ID and identity attribute: `employee_id`
- Account display attribute: `username`

Use `isc/account-schema.json` for the account schema:

- First name: `givenName`, last name: `familyName`, preferred name: `nickname`
- Display name / account name: `username`
- Work email: `email`, personal email: `other_email`
- Job title: `title`, department: `department`, location: `city` and `country`
- Employment type: `type`, lifecycle input: `term`
- Manager native identity: `manager`

The dataset is below Supabase's default response limit, so this demo needs no pagination.

## Expected Fusion outcomes

`fixtures/orangehrm-counterparts.csv` is a verification aid, not something to import. Keep MelonHRM and OrangeHRM as distinct authoritative sources and let Identity Fusion NG decide. Ordinary account correlation that pre-merges on employee id defeats the Fusion test.

Columns:

| Column | Meaning |
| --- | --- |
| `scenario` | `non_match`, `natural_correlation`, `deferred_reciprocal`, `automatic_match`, `manual_true_positive`, or `manual_false_positive` |
| `candidate_*` | Expected counterpart when one exists (OrangeHRM or the reciprocal MelonHRM row) |
| `expected_disposition` | `non-matched`, `correlated`, `deferred`, `auto`, or `review` |
| `expected_manual_decision` | `accept` / `reject` for review scenarios; empty otherwise |
| `melon_title` / `candidate_title` | Title comparison for positive matches |

The five MelonHRM-only non-matches and the false-positive reject path should produce new identities when accepted as such.

## Local verification

Start Docker, then from this directory:

```bash
npx supabase start
npx supabase db reset
npx supabase test db
```

The tests assert that `public."MelonHRM"` exposes the account attribute list, returns 15 identities in the 5/4/2/2/1/1 scenario mix, uses full country names, has exactly one root (`MEL0001`), references only `MEL0001` and `MEL0006` as managers, and keeps positive-match titles different from their OrangeHRM candidates.
