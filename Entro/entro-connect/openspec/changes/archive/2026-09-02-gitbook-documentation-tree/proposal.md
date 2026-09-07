## Why

Stage 1 ingest today concatenates GitBook HTML into `integrations.md` / `integrations-crawl.md`. That blob does not match the left-hand menu, mixes leftover pages with live ones, and is hard for later provider-prep work to parse. GitBook already publishes the sidebar as `llms.txt` and per-page `.md` URLs. Capture that catalog now as a cleaned tree so distillation has a stable, navigable source.

## What Changes

**Ingest source**
- From: crawl4ai BFS of HTML, one concatenated markdown file
- To: HTTP GET of the GitBook markdown catalog and each kept page's `.md`, written under `documentation/`
- Reason: the catalog *is* the sidebar; BFS invents extra URLs
- Impact: non-breaking for later specs; ingest CLI and output layout change

**Output shape**
- From: flat crawl dumps at repo root
- To: documentation tree mirroring cleaned nav (sidebar groups as folders)
- Reason: agents and later changes need the same hierarchy operators see in GitBook
- Impact: new `documentation/` folder; existing blobs may remain unused until a later cleanup

**Nav filter**
- From: keep whatever the crawler found
- To: cleaned nav — drop Copy-of, " - Old", `gemini-instructions`, unsuffixed GCP; keep distinct/current `-1` slugs (VS Code, GCP rewrite, GHES, Slack Enterprise)
- Reason: GitBook `-1` is often a real page, not junk
- Impact: ingest filter rules; not a Provider catalog rename

## Non-goals

No provider-prep or connection-details distillation. No skills or CLI automation. No secrets handling. No rewriting in-page GitBook links, no stripping GitBook widgets, no deleting `crawl_docs.py` / `integrations*.md` in this change.

## Capabilities

### New Capabilities

- None. Documentation tree, GitBook markdown catalog, and cleaned nav belong in `documentation-ingest` plus glossary entries.

### Modified Capabilities

- `documentation-ingest`: ingest MUST produce a cleaned documentation tree from the GitBook markdown catalog, not a concatenated HTML crawl.
- `ubiquitous-language`: add Documentation tree, GitBook markdown catalog, and Cleaned nav.

## Impact

Python ingest (replace crawl4ai path for this job), new `documentation/` tree, GitBook HTTPS as the only vendor system. `docs/` (agent process) unchanged. Downstream provider-prep still reads ingest output; the path to that output changes.
