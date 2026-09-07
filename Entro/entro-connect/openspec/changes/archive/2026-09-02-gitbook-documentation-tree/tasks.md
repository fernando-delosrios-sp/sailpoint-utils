## 1. Catalog parse and cleaned nav

- [x] 1.1 Add pytest (or unittest) fixtures of a mini `llms.txt` covering leftovers, unsuffixed GCP, `google-cloud-platform-1`, and `cursor-entro-marketplace-1`
- [x] 1.2 Implement GitBook markdown catalog parse (markdown links only; ignore `/pages/{hash}`)
- [x] 1.3 Implement cleaned nav: drop `gemini-instructions*`, Copy-of, titles ending ` - Old`, unsuffixed `google-cloud-platform`; keep other `-1` slugs including GCP `-1` and VS Code
- [x] 1.4 Map kept URLs to paths under `documentation/` using the segment after `/integrations/` (sibling `.md` + folder)

## 2. Ingest CLI

- [x] 2.1 Add `ingest_docs.py` using stdlib HTTPS GET with a browser-like User-Agent; do not use crawl4ai
- [x] 2.2 Abort with unsuccessful exit when the catalog GET fails; do not report success for an empty tree
- [x] 2.3 On per-page failure, record the URL, continue, write successful pages, exit unsuccessful if any page failed
- [x] 2.4 On success, write page files plus `documentation/README.md` listing kept pages in catalog order (with kept/dropped counts)
- [x] 2.5 Leave `crawl_docs.py` and existing `integrations*.md` files in place

## 3. Live ingest

- [x] 3.1 Run ingest against `https://entro.gitbook.io/integrations/llms.txt` and commit the resulting `documentation/` tree
- [x] 3.2 Spot-check: sidebar groups present; no gemini-instructions, Copy-of SMB, AD Old, or unsuffixed GCP; VS Code and GCP `-1` present

## 4. Verification

- [x] 4.1 Confirm canonical test command: `python -m pytest`
- [x] 4.2 All delta spec scenarios covered by named automated tests (`test_catalog_drives_page_list`, `test_catalog_fetch_failure`, `test_successful_tree_write`, `test_leftovers_excluded`, `test_distinct_dash1_slugs_kept`, `test_partial_page_failure`)

## 5. Documentation

- [x] 5.1 Add a short ingest how-to (CLI invocation, `documentation/` vs `docs/`) in repo README if one exists, otherwise a `documentation/README.md` header plus script `--help`
- [x] 5.2 No API/connector doc updates (no Entro contract change)
- [x] 5.3 Document CLI flags and default catalog URL in `ingest_docs.py` `--help`

## 6. Changelog

- [x] 6.1 Create or update changelog entry for this change via changelog-generator
- [x] 6.2 Confirm entry covers documentation-ingest tree output and glossary terms (not provider-prep or automation)
