# Superpowers Bridge Installation

Follow these steps to complete the setup for the `superpowers-bridge` schema:

## 1. Identify Target Agent Rules
Identify which AI tools the user works with by reviewing their `openspec init` selections or simply asking them. 
Check the project root for their corresponding configuration files:
- **Claude**: `CLAUDE.md`
- **Cursor**: `.cursorrules`
- **Windsurf**: `.windsurfrules`
- **Antigravity**: `AGENTS.md`
- **OpenCode**: `AGENTS.md`

## 2. Insert Workflow Routing
For each configuration file that exists in the project:
1. Ask the user for permission to insert the workflow routing fragment.
2. Read the fragment from `openspec/schemas/superpowers-bridge/templates/adopters/CLAUDE.md.fragment.md`.
3. Append this fragment as a new section to the end of the rule file. 
   *(Note: Most tools support Markdown, but if a tool requires a specific format like JSON, adapt the content accordingly).*

## 3. Install Required Skills
Suggest or run the command to install the baseline `superpowers` skills package:
```bash
npx skills add obra/superpowers
```