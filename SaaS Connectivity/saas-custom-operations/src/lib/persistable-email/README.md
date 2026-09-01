# persistable-email

Shared builders for **persistable email body** HTML: compact snippets for DelimitedFile/STRING account attributes and ISC workflow Send Email bodies.

## STRING limit

Bodies must fit `ISC_STRING_ATTRIBUTE_MAX_LENGTH` (256). Use `fitPersistableHtml` to shorten pre-escaped name slots proportionally and drop optional suffixes before a last-resort hard slice.

## Unquoted href CTA

`renderUnquotedHrefCta(url, label)` emits `<a href=${escapedUrl}>${escapedLabel}</a>` — href is HTML-escaped and **not** wrapped in quotes (DelimitedFile / `provisionAsCsv`-safe when the URL has no spaces).

## Boundary vs sod-form-html

| Concern | Library |
|---|---|
| Compact workflow email / STRING persist bodies | `persistable-email` |
| In-form DESCRIPTION / formInput panel HTML | `sod-form-html` |

`sod-form-html` re-exports `escapeHtml` from this kit so escape tables do not drift.
