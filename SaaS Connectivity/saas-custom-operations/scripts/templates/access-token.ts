import { REFERENCE_WORKFLOW_NAME, REFERENCE_WORKFLOW_PATH, WORKFLOW_STEP_NAMES } from './workflow-reference'

/** Renders the shared OAuth access-token guide for workflow integration. */
export function renderAccessTokenGuide(): string {
    return `# Access Token Guide

Structure derived from \`${REFERENCE_WORKFLOW_PATH}\` (workflow **${REFERENCE_WORKFLOW_NAME}**: **${WORKFLOW_STEP_NAMES.configuration}** → **${WORKFLOW_STEP_NAMES.getAccessToken}**).

## ${WORKFLOW_STEP_NAMES.configuration}

Add a **Define Variable** step (\`sp:define-variable\`) with these variables:

| Variable name | Example value | Referenced as |
|---|---|---|
| API URL | \`https://your-tenant.api.identitynow.com\` | \`{{$.configuration.aPIURL}}\` |
| SaaS Custom Operations Source Name | \`SaaS Custom Operations\` | \`{{$.configuration.saaSCustomOperationsSourceName}}\` |
| SaaS Custom Operations Connector ID | \`{{CONNECTOR_ID}}\` | \`{{$.configuration.saaSCustomOperationsConnectorID}}\` |

Replace example values with your tenant's API URL, dummy result source name, and deployed connector ID. The framework resolves \`sourceName\` at runtime and auto-creates the DelimitedFile source when missing.

## ${WORKFLOW_STEP_NAMES.getAccessToken}

Add an **HTTP Request** step (\`sp:http\`) immediately after Configuration:

| Setting | Value |
|---|---|
| Method | POST |
| URL | \`{{$.configuration.aPIURL}}/oauth/token\` |
| Content type | form |
| Authentication | Basic (OAuth client ID / secret) |
| Body | \`grant_type=client_credentials\` |

Configure Basic auth with your ISC OAuth client credentials (PAT or client with connector invoke scopes). The reference workflow uses a stored auth reference — replace \`paramID\` / \`refID\` values with your tenant's credential reference.

## Using the token

Reference the token in subsequent invoke steps:

\`\`\`
Authorization: Bearer {{$.getAccessToken.body.access_token}}
\`\`\`

Also pass the token in the invoke body \`config.token\` field (see \`workflow-invocation.md\`).
`
}
