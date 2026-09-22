import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'

const WORKFLOW_FILE = 'Access Model SOD - Remediation.json'
const WORKFLOWS_DIR = join(__dirname, '../../../workflows')
const EXPECTED_REQUEST_ID = 'access-model-sod-remediation-apply'

interface WorkflowStep {
    attributes?: {
        jsonRequestBody?: {
            type?: string
            input?: Record<string, unknown>
        }
    }
}

interface WorkflowExport {
    definition: {
        steps: Record<string, WorkflowStep>
    }
}

describe(WORKFLOW_FILE, () => {
    it('sends the operation name as requestId and leaves formInstanceId on its own field', () => {
        const parsed = JSON.parse(readFileSync(join(WORKFLOWS_DIR, WORKFLOW_FILE), 'utf8')) as WorkflowExport
        const invoke = parsed.definition.steps['Call SaaS Custom Operation']?.attributes?.jsonRequestBody

        expect(invoke?.type).toBe('custom:access-model-sod-remediation-apply')
        expect(invoke?.input?.requestId).toBe(EXPECTED_REQUEST_ID)
        expect(invoke?.input?.formInstanceId).toBe('{{$.trigger.formInstanceId}}')
        expect(invoke?.input?.formName).toBe('Access Model SOD Remediation')
    })
})
