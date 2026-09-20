# MelonHRM HR source

Synthetic HR account feed for a SailPoint **Web Services** source. One PostgreSQL table, 30 identities, same attribute names as a typical JDBC HR aggregation so an identity profile can map this source the same way as OrangeHRM.

The dataset is built for Identity Fusion NG: 15 overlays of the OrangeHRM subtree under Jerry Bennett, 4 lookalikes that share a name but report elsewhere, and 11 people who exist only here.

## Population

| Group | Count | Description |
| --- | --- | --- |
| Exact overlay | 8 | Same person as an OrangeHRM account; same name, personal email, title, department, city, and manager |
| Fuzzy overlay | 7 | Same person with a first-name variation (`Randall`/`Randy`, `Deb`/`Debra`, `María`/`Maria`), carrying the OrangeHRM spelling in `nickname` |
| Lookalikes | 4 | Share a full name with a real OrangeHRM account but are a different person, reporting to a different manager |
| MelonHRM-only | 11 | No OrangeHRM record at all |

Matching is **manager-closed** for the 15 overlays: whenever an identity has an OrangeHRM counterpart, its manager has one too. The lookalikes break that rule.

OrangeHRM carries no birth date, national identifier, or phone data. This feed populates `mobile`, `telephone`, and `zipcode` for part of the population, spread across all four groups so contact data never implies a match.

Two identities have no location, one is terminated (`term = 'true'`), and three are contractors with contract dates. Overlay people reuse `@sailpointdemo.com` personal addresses; MelonHRM-only people use `@melonmail.example`.

## Artifacts

- `melonhrm.sql` — self-contained script: creates `public."MelonHRM"` and inserts the 30 rows. Run it on any PostgreSQL database (including the Supabase SQL editor).
- `isc/account-schema.json` — account schema for the SailPoint source.
- `fixtures/orangehrm-counterparts.csv` — expected Fusion outcome for each identity that touches an OrangeHRM account.
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

`fixtures/orangehrm-counterparts.csv` is a verification aid, not something to import. Keep MelonHRM and OrangeHRM as distinct authoritative sources and let Identity Fusion NG decide. Ordinary account correlation that pre-merges on employee id defeats the test (`MEL0007` against `1b2a3a`).

The 11 MelonHRM-only identities are absent from the file; they should always produce new identities.

## Local verification

Start Docker, then from this directory:

```bash
npx supabase start
npx supabase db reset
npx supabase test db
```

The tests assert that `public."MelonHRM"` exposes the account attribute list, returns 30 identities, and gives every identity except `MEL0001` exactly one manager.
