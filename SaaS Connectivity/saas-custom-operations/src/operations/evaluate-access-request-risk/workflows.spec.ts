import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'

const WORKFLOWS_DIR = join(__dirname, '../../../workflows')

/**
 * `failureStep` is where a workflow must land when it cannot obtain a tier. A missing tier means the
 * request was never scored, so it can never share a step with a tier the scorer actually returned.
 */
const BUNDLED_RISK_WORKFLOWS = [
    {
        file: 'Access Request Pre-Check - Risk analysis and in-flight SOD.json',
        requestIdTemplate: 'evaluate-access-request-risk:{{$.trigger.accessRequestId}}:submitted',
        failureStep: 'Set Evaluation Failed',
        tierSteps: ['Set High Risk', 'Set Medium Risk', 'Set Low Risk'],
    },
    {
        file: 'Dynamic Approver - Risk analysis.json',
        requestIdTemplate: 'evaluate-access-request-risk:{{$.trigger.accessRequestId}}:dynamic',
        failureStep: 'Set Default Approver',
        tierSteps: ['Set High Approver', 'Set Medium Approver', 'Set Low Approver'],
    },
    {
        file: 'Dynamic Approval Workflow - Risk analysis.json',
        requestIdTemplate: 'evaluate-access-request-risk:{{$.trigger.accessRequestId}}:dynamic-approval',
        failureStep: 'Approval Policy Evaluation Failed',
        tierSteps: ['Approval Policy High', 'Approval Policy Medium', 'Approval Policy Low'],
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
    catch?: Array<{ next?: string }>
    choiceList?: Array<{
        comparator?: string
        nextStep?: string
        'variableA.$'?: string
        variableB?: string
    }>
    defaultStep?: string
    nextStep?: string
}

interface WorkflowExport {
    definition: {
        steps: Record<string, WorkflowStep>
    }
}

function readWorkflow(file: string): WorkflowExport {
    return JSON.parse(readFileSync(join(WORKFLOWS_DIR, file), 'utf8')) as WorkflowExport
}

describe.each(BUNDLED_RISK_WORKFLOWS)('$file', ({ file, requestIdTemplate, failureStep, tierSteps }) => {
    it('parses as JSON', () => {
        expect(() => readWorkflow(file)).not.toThrow()
    })

    it('calls the risk operation with the expected requestId template', () => {
        const steps = readWorkflow(file).definition.steps

        expect(steps['Call Evaluate Risk']?.attributes?.jsonRequestBody?.input?.requestId).toBe(requestIdTemplate)
    })

    it('reads the risk result back on the same requestId', () => {
        const steps = readWorkflow(file).definition.steps
        const readRiskResult = steps['Read Risk Result']
        const requestId = steps['Call Evaluate Risk']?.attributes?.jsonRequestBody?.input?.requestId

        expect(readRiskResult?.attributes?.filterCriteria).toBe('nativeIdentity')
        expect(readRiskResult?.attributes?.operator).toBe('eq')
        expect(readRiskResult?.attributes?.value).toBe(requestIdTemplate)
        expect(readRiskResult?.attributes?.value).toBe(requestId)
    })

    it('routes an absent tier to the failure step rather than the High step', () => {
        const steps = readWorkflow(file).definition.steps
        const [highStep] = tierSteps

        expect(steps[failureStep]).toBeDefined()
        expect(failureStep).not.toBe(highStep)
        expect(steps['Check Tier Low']?.defaultStep).toBe(failureStep)
    })

    it('routes every broken risk call to the failure step', () => {
        const steps = readWorkflow(file).definition.steps

        for (const stepName of ['Get Access Token', 'Call Evaluate Risk', 'Read Risk Result']) {
            expect(steps[stepName]?.catch?.map((handler) => handler.next)).toEqual([failureStep])
        }
    })

    it('routes an HTTP-200 failed invoke body to the failure step before reading the result', () => {
        const steps = readWorkflow(file).definition.steps
        const checkInvoke = steps['Check Invoke Result']

        expect(steps['Call Evaluate Risk']?.nextStep).toBe('Check Invoke Result')
        expect(checkInvoke?.choiceList).toEqual([
            {
                comparator: 'StringContains',
                nextStep: failureStep,
                'variableA.$': '$.callEvaluateRisk.body',
                variableB: '"status":"failed"',
            },
        ])
        expect(checkInvoke?.defaultStep).toBe('Read Risk Result')
    })

    it('leaves no step pointing at a name the workflow does not define', () => {
        const steps = readWorkflow(file).definition.steps
        const targets = Object.values(steps).flatMap((step) => [
            step.nextStep,
            step.defaultStep,
            ...(step.catch ?? []).map((handler) => handler.next),
            ...(step.choiceList ?? []).map((choice) => choice.nextStep),
        ])

        expect(targets.filter((target) => target && !(target in steps))).toEqual([])
    })
})
