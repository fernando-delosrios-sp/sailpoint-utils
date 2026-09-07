## Context

Stage 1 ingest must turn Entro's published Integration docs into a durable local source. Today `crawl_docs.py` BFS-crawls HTML into concatenated files that do not match the GitBook left-hand menu. GitBook already exposes that menu as `https://entro.gitbook.io/integrations/llms.txt` and each page as `{url}.md`. This design follows discovery: cleaned nav into repo-root `documentation/`, HTTP GET only, no crawl4ai for this path.

## Architecture

[Container diagram](./diagrams/gitbook-documentation-tree.drawio)

Operator runs a Python ingest CLI. The CLI GETs the GitBook markdown catalog, applies cleaned-nav filters, GETs each remaining page `.md`, and writes the documentation tree under `documentation/`. GitBook is the only external system.

## Goals / Non-Goals

**Goals:**

- Produce a documentation tree whose folders match GitBook sidebar groups.
- Use the GitBook markdown catalog as the only page index.
- Apply cleaned nav so leftovers do not land in `documentation/`.
- Survive per-page fetch failures; fail the run if the catalog itself cannot be fetched.

**Non-Goals:**

- Distilling provider-prep or connection details.
- Skills, Provider automation, or secrets handling.
- Rewriting in-page GitBook links or stripping `{% hint %}` / `{% stepper %}`.
- Deleting `crawl_docs.py` or `integrations*.md` in this change.

## Decisions

### D1: Fetch via published markdown, not a browser crawler
- **Choice**: stdlib HTTP GET of `llms.txt` and each kept `{page}.md` (browser-like User-Agent; GitBook returns 403 to a bare Python UA).
- **Reason**: the catalog is the sidebar; crawl4ai BFS invents `/pages/{hash}` and duplicate HTML/`.md` URLs.
- **Considered alternatives**: keep crawl4ai and split the blob; scrape the live sidebar DOM. Rejected as slower and less aligned with published paths.

### D2: Output root is `documentation/`
- **Choice**: repo-root `documentation/`, distinct from `docs/` (agent process docs).
- **Reason**: operator asked for a documentation folder; ingest source must not mix with agent routing docs.
- **Considered alternatives**: `docs/ingest/`, `vendor/entro-integrations/`. Rejected after the folder decision.

### D3: Preserve GitBook sibling paths
- **Choice**: write files using the path after `/integrations/` (e.g. `amazon-web-services.md` beside `amazon-web-services/`).
- **Reason**: matches the published URL tree and the left-hand menu nesting.
- **Considered alternatives**: flatten to `foo/README.md`. Deferred; extra mapping with no ingest benefit.

### D4: Cleaned nav filter (not drop-all `-1`)
- **Choice**: drop `gemini-instructions*`; drop paths/titles with `copy-of` / `Copy of`; drop titles ending ` - Old`; drop unsuffixed `google-cloud-platform.md` and `google-cloud-platform/` (keep `google-cloud-platform-1`). Keep other `-1` slugs (VS Code marketplace, GHES token page, Slack Enterprise).
- **Reason**: GitBook `-1` often names a distinct page or the current rewrite.
- **Considered alternatives**: faithful dump; drop every `-1` path. Rejected — would drop VS Code or keep stale GCP.

### D5: New ingest script; leave old crawl in place
- **Choice**: add `ingest_docs.py` (or equivalent) that writes `documentation/` plus a generated `documentation/README.md` from the cleaned catalog. Do not delete `crawl_docs.py` in this change.
- **Reason**: rollback stays trivial; crawl blobs can be removed later.
- **Considered alternatives**: rewrite `crawl_docs.py` in place. Rejected to avoid mixing two strategies in one file.

### D6: Commit the tree
- **Choice**: commit `documentation/` so later agents can read it without a live fetch.
- **Reason**: ingest output is source material for distillation; a gitignored dump is invisible to the rest of the repo.
- **Considered alternatives**: gitignore the tree. Deferred gitignore vs commit was an open question; committing matches “agents can read it”.

### D7: Exit codes
- **Choice**: catalog GET failure → abort, write nothing as success. Per-page failure → record URL, continue, non-zero exit if any page failed.
- **Reason**: matches existing ingest “don’t abort the whole run on one page” plus “don’t claim a silent partial catalog”.

## Risks / Trade-offs

[Risk] GitBook retitles or re-slugs pages; cleaned-nav heuristics miss a leftover or drop a live page. -> Mitigation: filter is explicit (path prefixes + title suffixes); README lists kept vs dropped counts for review after each run.

[Risk] `google-cloud-platform-1` stays the current GCP tree only until GitBook collapses slugs. -> Mitigation: filter names that path; revisit when the unsuffixed tree disappears from `llms.txt`.

[Trade-off] Vendor markdown (widgets, absolute links) stays raw in `documentation/`. -> Reason: distillation is a later change; ingest spec already forbids dumping crawl into skills.

[Trade-off] Two ingest scripts exist until cleanup. -> Reason: this change must not expand into deleting historical blobs.

## Migration Plan

1. Add ingest CLI and tests (catalog parse, cleaned-nav filter, path mapping, failure handling).
2. Run ingest against GitBook; write `documentation/`.
3. Point later work at `documentation/`; leave `integrations.md` / `integrations-crawl.md` unused.
4. Rollback: delete `documentation/` and the new script; old crawl files still present.

Acceptance: ingest from a fixture catalog produces the expected tree; a live run (when network is available) writes sidebar groups under `documentation/` without gemini-instructions, Copy-of SMB, AD Old, or unsuffixed GCP.

## Open Questions

Deferred to a later change: relative link rewrite, widget stripping, retirement of `crawl_docs.py` and concatenated crawl files.
