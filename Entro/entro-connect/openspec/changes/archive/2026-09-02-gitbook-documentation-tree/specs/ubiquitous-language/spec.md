<!--
Delta spec — glossary terms promoted from discovery.
-->

## ADDED Requirements

### Requirement: Documentation ingest path terms

The glossary SHALL define Documentation tree, GitBook markdown catalog, and Cleaned nav with the definitions in Term entries below.

#### Scenario: Ingest specs use canonical tree terms

- **GIVEN** a change authors documentation-ingest requirements
- **WHEN** it names the local file layout, the published index, or the leftover filter
- **THEN** it MUST use Documentation tree, GitBook markdown catalog, and Cleaned nav rather than crawl dump, HTML BFS index, or drop-all-`-1`

## Term entries

### Term: Documentation tree
**Context**: documentation-ingest
**Definition**: The local filesystem of markdown files whose folders match Entro GitBook sidebar groups.
**Aliases**: none
**Notes**: Lives under the documentation folder (`documentation/`). Do not treat concatenated crawl files as the documentation tree.

### Term: GitBook markdown catalog
**Context**: documentation-ingest
**Definition**: GitBook's published `llms.txt` plus each page's `.md` URL — the authoritative list of Integration documentation pages and their paths.
**Aliases**: none
**Notes**: Not an HTML BFS crawl, `/pages/{hash}` card links, or the sitemap as the primary index.

### Term: Cleaned nav
**Context**: documentation-ingest
**Definition**: The GitBook markdown catalog after dropping leftovers (Copy-of pages, titles ending in " - Old", `gemini-instructions`, the stale unsuffixed GCP tree) while keeping `-1` slugs that are a distinct product or the current rewrite.
**Aliases**: none
**Notes**: Do not drop every `-1` path; GitBook uses that suffix for distinct pages (for example VS Code marketplace) and for the current GCP tree (`google-cloud-platform-1`).
