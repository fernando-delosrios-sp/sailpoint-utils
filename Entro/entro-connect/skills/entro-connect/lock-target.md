# Lock

Confirm the Integration tile and Integration path after the operator has chosen an Operation mode, before Intro or tools.

1. Open the Skill catalog index `integrations.json` in this folder. Match the operator's words to `tile` using `summary`, `integrationPathNames`, and `catalogPath` from the index only.
2. When `captureRequired` is **true**, stop before Lock. Ask the operator for current connection-form screenshots for that tile. Do not open `catalogPath`, invent paths, or run Typed actions.
3. When `integrationPathNames` has more than one name, gate which Integration path the operator chose. When it has zero or one non-implicit path, no path gate — state the path inline if named, or omit it when implicit.
4. Optional capabilities are **not** Lock dimensions. Do not pre-select them. Name available optional capabilities during Intro; obtain consent just-in-time during Prep before their instructions or Typed actions run (including automated mode).
5. Documentation-derived paths: tell the operator to provide screenshots if the live Entro form differs from the catalog.

Do not open `catalogPath`, `tool-install.json`, or any Skill-held file until this Lock is stated (except to read `captureRequired`).

**Gate the forks:** two or more candidate tiles → gate the tile first, closest match recommended; then one single-choice gate for Integration path when `integrationPathNames.length > 1`. One tile with at most one explicit path → confirm inline in a single line, no gate.

**Done when:** tile and Integration path (when applicable) are stated back as the thing itself — "Amazon Web Services, using Terraform" — and the operator has not contradicted them.
