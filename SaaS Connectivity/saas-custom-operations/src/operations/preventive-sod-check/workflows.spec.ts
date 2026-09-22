import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'

const WORKFLOW_FILE = 'Access Request Pre-Check - Risk analysis and in-flight SOD.json'
const WORKFLOWS_DIR = join(__dirname, '../../../workflows')

/**
 * The operation persists under the `requestId` it is handed, so the invoke input and the Get Accounts
 * filter are the only two places that identity appears. They are asserted against each other here.
 */
const EXPECTED_REQUEST_ID = 'preventive-sod-check:{{$.trigger.accessRequestId}}:submitted'

interface WorkflowVariable {
    name?: string
    variableA?: unknown
    'variableA.$'?: string
}

interface WorkflowStep {
    attributes?: {
        filterCriteria?: string
        operator?: string
        value?: string
        variables?: WorkflowVariable[]
        jsonRequestBody?: {
            type?: string
            input?: Record<string, unknown>
        }
    }
    choiceList?: Array<{ comparator?: string; nextStep?: string; 'variableA.$'?: string }>
    defaultStep?: string
    nextStep?: string
}

interface WorkflowExport {
    definition: {
        steps: Record<string, WorkflowStep>
    }
}

function readWorkflowSteps(): Record<string, WorkflowStep> {
    const parsed = JSON.parse(readFileSync(join(WORKFLOWS_DIR, WORKFLOW_FILE), 'utf8')) as WorkflowExport
    return parsed.definition.steps
}

describe(WORKFLOW_FILE, () => {
    it('invokes the preventive SoD check in request mode', () => {
        const invoke = readWorkflowSteps()['Call Preventive Sod Check']?.attributes?.jsonRequestBody

        expect(invoke?.type).toBe('custom:preventive-sod-check')
        expect(invoke?.input?.accessRequestId).toBe('{{$.trigger.accessRequestId}}')
        expect(invoke?.input?.inflightOnly).toBe('{{$.configuration.inflightOnly}}')
        expect(invoke?.input?.requestId).toBe(EXPECTED_REQUEST_ID)
    })

    it('defaults Inflight Only to true in Configuration', () => {
        const configuration = readWorkflowSteps()['Configuration'] as {
            attributes?: { variables?: Array<{ name?: string; variableA?: unknown }> }
        }
        const inflightOnly = configuration.attributes?.variables?.find((variable) => variable.name === 'Inflight Only')

        expect(inflightOnly?.variableA).toBe('true')
    })

    it('reads the result back on the identity it was persisted under', () => {
        const steps = readWorkflowSteps()
        const readSodResult = steps['Read Sod Result']

        expect(readSodResult?.attributes?.filterCriteria).toBe('nativeIdentity')
        expect(readSodResult?.attributes?.operator).toBe('eq')
        expect(readSodResult?.attributes?.value).toBe(
            steps['Call Preventive Sod Check']?.attributes?.jsonRequestBody?.input?.requestId
        )
    })

    it('retries a missing SoD result once before giving up', () => {
        const steps = readWorkflowSteps()

        expect(steps['Read Sod Result']?.nextStep).toBe('Check Sod Result')
        expect(steps['Check Sod Result']?.defaultStep).toBe('Wait For Sod Result')
        expect(steps['Wait For Sod Result']?.nextStep).toBe('Read Sod Result Retry')
        expect(steps['Read Sod Result Retry']?.nextStep).toBe('Check Sod Result Retry')
    })

    it('treats a SoD result still missing after the retry as a failed evaluation', () => {
        const retryCheck = readWorkflowSteps()['Check Sod Result Retry']

        expect(retryCheck?.choiceList?.[0]?.comparator).toBe('IsPresent')
        expect(retryCheck?.defaultStep).toBe('Set Evaluation Failed')
    })

    it('reads the retry back on the same identity as the first read', () => {
        const steps = readWorkflowSteps()

        expect(steps['Read Sod Result Retry']?.attributes?.value).toBe(steps['Read Sod Result']?.attributes?.value)
    })

    it('tests presence on the summary, which is written even when no violation is found', () => {
        const steps = readWorkflowSteps()

        for (const step of ['Check Sod Result', 'Check Sod Result Retry']) {
            const presence = steps[step]?.choiceList?.[0]
            expect(presence?.['variableA.$']).toContain('preventive-sod-check:situation-summary')
            expect(presence?.['variableA.$']).not.toContain('has-violation')
        }
    })

    it('branches on the copied variable so a retry read reaches the violation step', () => {
        const steps = readWorkflowSteps()

        expect(steps['Check Violation']?.choiceList?.[0]?.['variableA.$']).toBe('$.defineVariable.sodHasViolation')
        expect(steps['Set Sod Violation True']?.nextStep).toBe('Check Tier')
        expect(steps['Set Sod Violation False']?.nextStep).toBe('Check Tier')
    })

    /**
     * Get Accounts hands attribute values back as strings, so copying the flag with `variableA.$` would
     * make the decision variable "true" and BooleanEquals would miss the violation. Every boolean that
     * feeds the callback is assigned as an unquoted literal instead.
     */
    it('never copies a decision boolean out of a read', () => {
        const steps = readWorkflowSteps()
        const decisionBooleans = ['$.defineVariable.approved', '$.defineVariable.sodHasViolation']

        for (const [stepName, step] of Object.entries(steps)) {
            for (const variable of step.attributes?.variables ?? []) {
                if (!decisionBooleans.includes(variable.name ?? '')) continue
                expect(variable['variableA.$'], `${stepName} copies ${variable.name} from a path`).toBeUndefined()
                expect(typeof variable.variableA, `${stepName} sets ${variable.name}`).toBe('boolean')
            }
        }
    })

    it('reads the violation flag off the account, where it is a real boolean', () => {
        const steps = readWorkflowSteps()

        for (const [step, read] of [
            ['Check Sod Violation Flag', '$.readSodResult'],
            ['Check Sod Violation Flag Retry', '$.readSodResultRetry'],
        ]) {
            const choice = steps[step]?.choiceList?.[0]
            expect(choice?.comparator).toBe('BooleanEquals')
            expect(choice?.['variableA.$']).toBe(`${read}.accounts[0].attributes['preventive-sod-check:has-violation']`)
            expect(steps[step]?.defaultStep).toBe('Set Sod Violation False')
        }
    })
})
