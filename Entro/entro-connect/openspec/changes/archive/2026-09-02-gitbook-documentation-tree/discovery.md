## Scope

Replace concatenated GitBook crawls with a cleaned markdown tree under `documentation/` that mirrors Entro's integration sidebar. In: fetch published `.md` pages from the GitBook catalog, filter leftovers, write one file per kept page. Out: provider-prep distillation, connection-details playbooks, skills, CLI automation, and crawl4ai as the ingest path.

## Language

**Documentation tree** (`promote`):
The local filesystem of markdown files whose folders match Entro GitBook sidebar groups (`ai-and-agents`, `cloud-and-infrastructure`, and the other published groups).
_Avoid_: crawl dump, blob, concatenated ingest, integrations.md as source of truth

**GitBook markdown catalog** (`promote`):
GitBook's published `llms.txt` plus each page's `.md` URL — the authoritative list of Integration documentation pages and their paths.
_Avoid_: HTML BFS crawl, `/pages/{hash}` card links, sitemap as the primary index

**Cleaned nav** (`promote`):
The GitBook markdown catalog after dropping leftovers (Copy-of pages, titles ending in " - Old", `gemini-instructions`, the stale unsuffixed GCP tree) while keeping `-1` slugs that are a distinct product or the current rewrite.
_Avoid_: drop-all-`-1`, faithful dump of GitBook quirks

**Documentation folder** (`draft`):
Repo-root `documentation/` — the ingest home for the documentation tree, distinct from `docs/` (agent process docs).
_Avoid_: dumping vendor pages into `docs/agents/`

## Decisions

Stage intent is documentation ingest (not skills or CLI automation).

Context → How faithful is the local tree? → **Cleaned nav** (not a byte-for-byte GitBook dump).

Context → Two GCP trees share the title. → Keep `google-cloud-platform-1` as current GCP; drop unsuffixed `google-cloud-platform/`.

Context → Where do files live? → New **documentation folder** at repo root (`documentation/`).

Context → How to fetch? → HTTP GET of the GitBook markdown catalog and page `.md` URLs, not crawl4ai BFS. Assumed after the catalog was confirmed as the sidebar; recorded here so design can specify the client.

Keep `-1` slugs when the page title is a different product (VS Code marketplace, GitHub Enterprise Server, Slack Enterprise App). Drop `copy-of-smb-file-shares-onboarding`, `active-directory-onboarding-1` (Old), and `gemini-instructions*`.

GitBook sibling layout (`foo.md` next to `foo/`) is kept as published. Absolute GitBook links may stay in the dump; relative rewrite is deferred.

## Open questions

Deferred: rewriting in-page GitBook URLs to relative paths; stripping `{% hint %}` / `{% stepper %}` widgets; gitignore vs commit of `documentation/`; retirement of `crawl_docs.py` and the existing `integrations*.md` blobs (may remain as unused leftovers until a later cleanup).

## Scenarios discussed

- Catalog fetch succeeds and writes one file per cleaned-nav path under `documentation/`.
- One page `.md` returns empty or errors: ingest records the failure and continues.
- VS Code lives at `cursor-entro-marketplace-1` — must not be dropped as a duplicate.
- Unsuffixed GCP vs `-1`: only `-1` is kept.
- Card-grid `/pages/{hash}` links are not a source of paths.
- Partial catalog (HTTP failure on `llms.txt`) must not write a silently incomplete tree as success.
