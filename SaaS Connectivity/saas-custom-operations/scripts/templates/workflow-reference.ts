/** Reference workflow export used as the template for generated operator guides. */
export const REFERENCE_WORKFLOW_PATH = 'workflows/SaaS Custom Operations.json'

/** Workflow object name inside {@link REFERENCE_WORKFLOW_PATH}. */
export const REFERENCE_WORKFLOW_NAME = 'SaaS Custom Operations Call'

export const WORKFLOW_STEP_NAMES = {
    configuration: 'Configuration',
    getAccessToken: 'Get Access Token',
    callOperation: 'Call SaaS Custom Operation',
    readResult: 'Read SaaS Custom Operation Result',
} as const

