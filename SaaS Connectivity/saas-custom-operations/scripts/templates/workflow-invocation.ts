import { OperationMeta } from './types'
import { REFERENCE_WORKFLOW_NAME, REFERENCE_WORKFLOW_PATH, WORKFLOW_STEP_NAMES } from './workflow-reference'

function renderInputFields(op: OperationMeta): string {
    const lines = ['              "requestId": "{{requestId}}"']
    for (const field of op.input) {
        lines.push(`              "${field.name}": "{{${field.name}}}"`)
    }
    return lines.join(',\n')
}

function renderOperationSection(op: OperationMeta): string {
    const inputExample = renderInputFields(op)
    const outputFields = op.output.map((f) => f.name).join(', ') || '(none declared)'

    let section = `## ${op.command}

Structure derived from **${WORKFLOW_STEP_NAMES.callOperation}** and **${WORKFLOW_STEP_NAMES.readResult}** in workflow **${REFERENCE_WORKFLOW_NAME}** (\`${REFERENCE_WORKFLOW_PATH}\`).

### ${WORKFLOW_STEP_NAMES.callOperation}

HTTP action (\`sp:http\`):

| Setting | Value |
|---|---|
| Method | POST |
| URL | \`{{$.configuration.aPIURL}}/beta/platform-connectors/{{$.configuration.saaSCustomOperationsConnectorID}}/invoke\` |
| Content type | json |
| Authentication | none (token in header) |

**Headers:**

\`\`\`
Authorization: Bearer {{$.getAccessToken.body.access_token}}
\`\`\`

Obtain the token using [access-token.md](./access-token.md) — do not duplicate OAuth steps here.

**Body (\`jsonRequestBody\`):**

\`\`\`json
{
    "connectorRef": "{{$.configuration.saaSCustomOperationsConnectorID}}",
    "tag": "latest",
    "type": "${op.command}",
    "input": {
${inputExample}
    },
    "config": {
        "apiUrl": "{{$.configuration.aPIURL}}",
        "sourceName": "{{$.configuration.saaSCustomOperationsSourceName}}",
        "token": "{{$.getAccessToken.body.access_token}}"
    }
}
\`\`\`

### ${WORKFLOW_STEP_NAMES.readResult}

Add a **Get Accounts** step (\`sp:get-accounts\`) after invoke completes:

| Setting | Value |
|---|---|
| Get accounts by | filters |
| Filter criteria | \`nativeIdentity\` |
| Operator | \`eq\` |
| Value | \`{{requestId}}\` (same value passed in invoke \`input.requestId\`) |
| Result selector | \`$.readSaaSCustomOperationResult.accounts[*].attributes\` |

**Output fields:** ${outputFields}, \`status\`, \`date\`
`

    if (op.childIdentities.length > 0) {
        section += `\n### Child identities\n\nThis operation also persists to additional account identities. Add extra **Get Accounts** steps:\n\n`
        for (const pattern of op.childIdentities) {
            const resolved = pattern.replace(/\$\{ctx\.requestId\}/g, '{{requestId}}')
            section += `- Filter \`nativeIdentity eq "${resolved}"\`\n`
        }
    }

    return section
}

/** Renders per-operation workflow invocation instructions. */
export function renderWorkflowInvocationGuide(operations: OperationMeta[]): string {
    const sections = operations.map(renderOperationSection).join('\n---\n\n')

    return `# Workflow Invocation Guide

Per-operation steps for invoking custom operations and reading persisted results.

Reference workflow: **${REFERENCE_WORKFLOW_NAME}** in \`${REFERENCE_WORKFLOW_PATH}\`

> **Authentication:** See [access-token.md](./access-token.md) for **${WORKFLOW_STEP_NAMES.configuration}** and **${WORKFLOW_STEP_NAMES.getAccessToken}** setup. Do not duplicate OAuth steps in each section below.

${sections || '_No registered operations found._'}
`
}

