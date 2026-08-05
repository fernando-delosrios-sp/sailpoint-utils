## Create `config.yaml`

Construct an `openspec/config.yaml` file with the following explicit structure if it is not present:

```yaml
schema: <selected-schema-name>
context: |
  Tech stack: <e.g., TypeScript, Node.js>
  Package manager: <e.g., pnpm>
  # Provide project context as a multiline string block...
rules:
  # Define global rules for the project
  global:
    - "Always use the `changelog-generator` skill to maintain and enforce a changelog for all changes."
  # Create a subsection mapping to each of the schema's defined artifacts
  # Each artifact section should contain a list of string rules.
  # e.g., if the schema defines 'specs' and 'tasks':
  specs:
    - <Rule 1>
    - <Rule 2>
  tasks:
    - <Rule 1>
```

### Context Building
To build a meaningful `context` section:
1. Scan the project contents to find existing design decisions, technologies, and architecture.
2. Engage in a conversation with the user to fully understand the project's goals and requirements.
3. Populate the `context` with these findings.

## Organize Specs by Domain

Organize specifications by domain — logical groupings that make sense for the system. Common patterns include:

- **By feature area**: `auth/`, `payments/`, `search/`
- **By component**: `api/`, `frontend/`, `workers/`
- **By bounded context**: `ordering/`, `fulfillment/`, `inventory/`
- **By structural groupings (e.g. monorepos)**: If the user selects a grouping pattern like "services" or "packages", DO NOT create a single placeholder like `services/spec.md`. Instead, identify the individual services/packages within that grouping (e.g., `services/auth`, `services/billing`) and create a separate spec for each one.

Help the user pre-populate the `openspec/specs/` directory with domains and initial empty spec files as needed to kickstart their workflow.