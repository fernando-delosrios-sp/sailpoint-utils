import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'

const WORKFLOW_FILE = 'Access Classification.json'
const WORKFLOWS_DIR = join(__dirname, '../../../workflows')

interface WorkflowStep {
    actionId?: string
    attributes?: {
        jsonRequestBody?: unknown
    }
    choiceList?: Array<{ comparator?: string; nextStep?: string; variableB?: unknown; 'variableA.$'?: string }>
    defaultStep?: string
}

interface WorkflowExport {
    enabled?: boolean
    definition: {
        start: string
        steps: Record<string, WorkflowStep>
    }
    trigger: {
        type?: string
        attributes?: {
            cronString?: string
            frequency?: string
            timeZone?: string
        }
    }
}

function readWorkflow(file: string): WorkflowExport {
    return JSON.parse(readFileSync(join(WORKFLOWS_DIR, file), 'utf8')) as WorkflowExport
}

describe(WORKFLOW_FILE, () => {
    it('is a disabled scheduled workflow', () => {
        const workflow = readWorkflow(WORKFLOW_FILE)

        expect(workflow.enabled).toBe(false)
        expect(workflow.trigger.type).toBe('SCHEDULED')
        expect(workflow.trigger.attributes).toEqual({
            cronString: '0 2 * * *',
            frequency: 'cronSchedule',
            timeZone: 'Europe/Madrid',
        })
        expect(workflow.definition.start).toBe('Configuration')
    })

    it('invokes access-classification with a per-run requestId', () => {
        const invoke = readWorkflow(WORKFLOW_FILE).definition.steps['Call SaaS Custom Operation']?.attributes
            ?.jsonRequestBody as { type?: string; input?: Record<string, unknown> } | undefined

        expect(invoke?.type).toBe('custom:access-classification')
        expect(invoke?.input?.requestId).toBe('access-classification:{{$.getAccessToken.timestamp}}')
    })

    it('treats NDJSON status failed as workflow failure', () => {
        const check = readWorkflow(WORKFLOW_FILE).definition.steps['Check Invoke Result']

        expect(check?.choiceList?.[0]).toMatchObject({
            comparator: 'StringContains',
            'variableA.$': '$.callSaaSCustomOperation.body',
            variableB: '"status":"failed"',
            nextStep: 'End Step - Failure',
        })
        expect(check?.defaultStep).toBe('End Step - Success')
    })
})
