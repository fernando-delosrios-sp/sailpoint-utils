## 1. API ingest CLI

- [x] 1.1 Add PyYAML to project dependencies and a fixture OpenAPI 3 JSON with Integrations plus a non-Integrations path and a `ghp_` example
- [x] 1.2 Add `ingest_api.py`: default endpoint `https://eval-api.entro.security`, `--endpoint` with trailing slash stripped, `GET {endpoint}/v1/docs`, `Authorization` from `ENTRO_API_KEY` (raw key), write `documentation/api/openapi.yaml`
- [x] 1.3 Parse JSON, require `paths`, set `servers[0].url` to the fetch endpoint, serialize YAML, apply `ingest_docs.redact_secrets` before write
- [x] 1.4 Fail closed: missing/empty `ENTRO_API_KEY`, HTTP error, non-JSON, or missing `paths` → non-zero exit and do not replace an existing snapshot with empty YAML
- [x] 1.5 Leave `ingest_docs.py` without `/v1/docs` or `ENTRO_API_KEY`

## 2. Live snapshot

- [x] 2.1 With local `ENTRO_API_KEY` only, run `ingest_api.py` against eval (or `--endpoint`) and commit `documentation/api/openapi.yaml`
- [x] 2.2 Spot-check: OpenAPI 3; Risk and Integrations paths present; `servers[0].url` is the fetch endpoint; no live `ghp_` strings; key not in the file or git history of this change

## 3. Verification

- [x] 3.1 Confirm canonical test command: `python -m pytest`
- [x] 3.2 All delta spec scenarios covered by named automated tests (`test_successful_api_catalog_ingest`, `test_snapshot_is_the_full_catalog`, `test_missing_api_key`, `test_api_catalog_fetch_failure`, `test_example_pat_in_the_catalog_is_redacted`, `test_gitbook_ingest_stays_key_free`)

## 4. Documentation

- [x] 4.1 Update repo README: `ingest_api.py` invocation, `ENTRO_API_KEY`, default eval endpoint, `documentation/api/openapi.yaml` vs the GitBook documentation tree, never commit the key
- [x] 4.2 No vendor connector-doc rewrite (Entro product contract is the committed snapshot)
- [x] 4.3 Document CLI flags and default endpoint in `ingest_api.py` `--help`

## 5. Changelog

- [x] 5.1 Create or update changelog entry for this change via changelog-generator
- [x] 5.2 Confirm entry covers Entro OpenAPI snapshot ingest and glossary terms (not typed clients or Integration automation)
