## 1. Credential boundary and authentication

- [x] 1.1 Add failing tests for loading only `ENTRO_DOCS_COOKIE` from process environment or repo-local `.env`, preserving process values and rejecting missing or empty values before any fetch
- [x] 1.2 Implement the narrow `.env` parser and cookie configuration without command-line secret arguments, shell sourcing, or value logging
- [x] 1.3 Add failing tests that a present cookie is sent only as the `Cookie` header, and that a Descope or GitBook visitor-auth login response is treated as a rejected session
- [x] 1.4 Implement one authenticated fetch adapter used for the start page and every page, with credential-safe errors that print the operator cookie steps and never echo cookie or authorization material

## 2. Protected-site discovery and conversion

- [x] 2.1 Add HTML fixtures and failing tests for same-origin link extraction, canonical URL deduplication, and exclusion of fragments, tracking queries, assets, account/authentication/logout routes, and external origins (including Descope and GitBook login hosts)
- [x] 2.2 Implement bounded page-graph discovery from `https://docs.entro.security/` with no public GitBook catalog fallback
- [x] 2.3 Add representative conversion fixtures and failing tests for headings, prose, lists, tables, code blocks, links, navigation-chrome removal, and empty-content rejection
- [x] 2.4 Implement the isolated HTML-to-markdown conversion and deterministic URL-to-output-path mapping, adding the smallest maintained dependency only if the fixture contract cannot be met with the standard library
- [x] 2.5 Preserve existing GitHub PAT redaction and add tests proving fetched content, logs, errors, fixtures, and generated artifacts contain no test cookie or authorization-header material

## 3. Atomic documentation publication

- [x] 3.1 Add failing tests proving empty discovery, missing cookie, rejected session, conversion failure, page failure, redaction failure, and index validation failure leave an existing `documentation/` tree byte-for-byte unchanged
- [x] 3.2 Refactor ingest to write pages, README, and indexes to a temporary sibling tree and validate a non-empty complete snapshot before publication
- [x] 3.3 Implement atomic replacement and cleanup of staged/backup paths on success and failure, including restoration when the final filesystem swap fails
- [x] 3.4 Add a partial-failure test proving remaining discovered pages are attempted and reported while staged output is discarded and the command exits unsuccessful

## 4. Source migration and integration

- [x] 4.1 Change the documentation-ingest default and CLI help from the GitBook catalog to `https://docs.entro.security/`, while keeping API ingest separate and independent of `ENTRO_API_KEY`
- [x] 4.2 Adapt README generation and `integration_catalog.py` inputs to deterministic protected-site paths, then verify both documentation and Skill indexes validate from a staged fixture tree
- [x] 4.3 Remove GitBook-catalog and cleaned-nav behavior from the active ingest path without deleting historical `crawl_docs.py` or root crawl blobs
- [x] 4.4 Add an end-to-end fixture test covering cookie-authenticated discovery through validated atomic publication

## 5. Verification

- [x] 5.1 Confirm canonical test command: `python -m pytest`
- [x] 5.2 Run `python -m pytest` and confirm every delta-spec scenario is covered by a named automated test
- [x] 5.3 Run `openspec validate replace-gitbook-docs-source --strict` and resolve all change validation errors
- [x] 5.4 Have the operator log in in a browser, export `ENTRO_DOCS_COOKIE`, and run live ingest locally; record only non-secret URL/page counts and confirm the published tree is non-empty, same-origin, representative, and index-valid
- [x] 5.5 Scan tracked changes for cookie values, authorization headers, `.env` content, and accidental public GitBook catalog fallback before handoff

## 6. Documentation

- [x] 6.1 Update `README.md` Stage 1, Ingest, and Secrets sections with numbered operator steps: open `https://docs.entro.security/`, complete login until docs are visible, copy the request `Cookie` header from a docs-host Network request, set `ENTRO_DOCS_COOKIE` in `.env`, rerun; also document expiry refresh, atomic publication, and no catalog fallback
- [x] 6.2 Update generated `documentation/README.md` wording and rebuild instructions so they describe the protected documentation source and cookie requirement rather than GitBook catalog or cleaned nav
- [x] 6.3 Update `ingest_docs.py --help` and inline module/function documentation for the new source, `ENTRO_DOCS_COOKIE`, exclusions, and the same operator cookie steps used in failure messages
- [x] 6.4 Confirm missing-cookie and rejected-session stderr contain those operator steps and contain no sample cookie values

## 7. Changelog

- [x] 7.1 Invoke `changelog-generator` during apply to create or update the changelog entry for this change
- [x] 7.2 Confirm the changelog covers the authenticated source migration, operator-exported session cookie, no public GitBook catalog fallback, and atomic preservation of the last valid documentation tree
