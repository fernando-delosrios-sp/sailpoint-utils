import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'
import { riskPersistIdentity } from './constants'

const WORKFLOWS_DIR = join(__dirname, '../../../workflows')

/**
 * Expected templates are spelled out here rather than derived, so the pairing assertion below is
 * checked against known-good data instead of re-running the builder on both sides.
 */
const BUNDLED_RISK_WORKFLOWS = [
    {
        file: 'Risk Approval - Auto Approve or Deny.json',
        requestIdTemplate: '{{$.trigger.accessRequestId}}:submitted',
        readFilterValue: 'evaluate-access-request-risk:{{$.trigger.accessRequestId}}:submitted',
    },
    {
        file: 'Risk Approval - Dynamic Approver.json',
        requestIdTemplate: '{{$.trigger.accessRequestId}}:dynamic',
        readFilterValue: 'evaluate-access-request-risk:{{$.trigger.accessRequestId}}:dynamic',
    },
    {
        file: 'Risk Approval - Dynamic approval workflow.json',
        requestIdTemplate: '{{$.trigger.accessRequestId}}:dynamic-approval',
        readFilterValue: 'evaluate-access-request-risk:{{$.trigger.accessRequestId}}:dynamic-approval',
    },
] as const

interface WorkflowStep {
    attributes?: {
        filterCriteria?: string
        operator?: string
        value?: string
        jsonRequestBody?: {
            input?: Record<string, unknown>
        }
    }
}

interface WorkflowExport {
    definition: {
        steps: Record<string, WorkflowStep>
    }
}

function readWorkflow(file: string): WorkflowExport {
    return JSON.parse(readFileSync(join(WORKFLOWS_DIR, file), 'utf8')) as WorkflowExport
}

describe.each(BUNDLED_RISK_WORKFLOWS)('$file', ({ file, requestIdTemplate, readFilterValue }) => {
    it('parses as JSON', () => {
        expect(() => readWorkflow(file)).not.toThrow()
    })

    it('calls the risk operation with the expected requestId template', () => {
        const steps = readWorkflow(file).definition.steps

        expect(steps['Call Evaluate Risk']?.attributes?.jsonRequestBody?.input?.requestId).toBe(requestIdTemplate)
    })

    it('reads the risk result back on the prefixed identity', () => {
        const readRiskResult = readWorkflow(file).definition.steps['Read Risk Result']

        expect(readRiskResult?.attributes?.filterCriteria).toBe('nativeIdentity')
        expect(readRiskResult?.attributes?.operator).toBe('eq')
        expect(readRiskResult?.attributes?.value).toBe(readFilterValue)
    })

    it('reads back exactly the identity the handler writes', () => {
        const steps = readWorkflow(file).definition.steps
        const requestId = steps['Call Evaluate Risk']?.attributes?.jsonRequestBody?.input?.requestId

        expect(steps['Read Risk Result']?.attributes?.value).toBe(riskPersistIdentity(String(requestId)))
    })
})
