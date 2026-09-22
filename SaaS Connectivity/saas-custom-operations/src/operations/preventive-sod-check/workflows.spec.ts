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
    actionId?: string
    attributes?: {
        filterCriteria?: string
        operator?: string
        value?: string
        variables?: WorkflowVariable[]
        jsonRequestBody?: {
            type?: string
            input?: Record<string, unknown>
            output?: Record<string, unknown>
        }
    }
    catch?: Array<{ next?: string }>
    choiceList?: Array<{ comparator?: string; nextStep?: string; 'variableA.$'?: string; variableB?: unknown }>
    defaultStep?: string
    nextStep?: string
}

interface WorkflowExport {
    definition: {
        start: string
        steps: Record<string, WorkflowStep>
    }
}

function readWorkflow(): WorkflowExport['definition'] {
    const parsed = JSON.parse(readFileSync(join(WORKFLOWS_DIR, WORKFLOW_FILE), 'utf8')) as WorkflowExport
    return parsed.definition
}

function readWorkflowSteps(): Record<string, WorkflowStep> {
    return readWorkflow().steps
}

/** Every step a run can move to from `step`, across plain, choice, default, and catch transitions. */
function successors(step: WorkflowStep): string[] {
    return [
        step.nextStep,
        step.defaultStep,
        ...(step.choiceList ?? []).map((choice) => choice.nextStep),
        ...(step.catch ?? []).map((handler) => handler.next),
    ].filter((next): next is string => Boolean(next))
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
     * Update Variable stores a boolean as the string "true" or "false". Assigning an unquoted literal
     * does not keep it a boolean in workflow state, so the two decision variables are only ever read
     * back with StringEquals — BooleanEquals silently takes the default branch on every run.
     */
    it('compares the decision variables as strings, since Update Variable stringifies them', () => {
        const steps = readWorkflowSteps()

        for (const [step, variable] of [
            ['Check Approved', '$.defineVariable.approved'],
            ['Check Violation', '$.defineVariable.sodHasViolation'],
        ]) {
            const choice = steps[step]?.choiceList?.[0]
            expect(steps[step]?.actionId, `${step} action`).toBe('sp:compare-strings')
            expect(choice?.comparator, `${step} comparator`).toBe('StringEquals')
            expect(choice?.['variableA.$'], `${step} reads ${variable}`).toBe(variable)
            expect(choice?.variableB, `${step} compares against the stringified literal`).toBe('true')
        }
    })

    /**
     * A decision variable read before any step has written it would still be the boolean that Define
     * Variable set, which StringEquals would miss. Every route from the start step to the choice step
     * that reads a decision variable must pass through a step that writes it.
     */
    it('writes each decision variable on every route to the step that reads it', () => {
        const { start, steps } = readWorkflow()

        for (const [reader, name] of [
            ['Check Approved', '$.defineVariable.approved'],
            ['Check Violation', '$.defineVariable.sodHasViolation'],
        ]) {
            const unwritten: string[][] = []
            const seen = new Set<string>()

            const walk = (stepName: string, written: boolean, route: string[]) => {
                const step = steps[stepName]
                if (!step) return
                if (stepName === reader) {
                    if (!written) unwritten.push(route)
                    return
                }

                const writes =
                    written || (step.attributes?.variables?.some((variable) => variable.name === name) ?? false)
                const key = `${stepName}:${writes}`
                if (seen.has(key)) return
                seen.add(key)

                for (const next of successors(step)) walk(next, writes, [...route, next])
            }

            walk(start, false, [start])
            expect(unwritten, `routes reaching ${reader} without writing ${name}`).toEqual([])
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

    /**
     * A path substitution in the request body renders the decision as the string "true", which the
     * trigger rejects. The send is split so each branch can carry the literal in the body.
     */
    it('sends the decision to the trigger as a literal boolean', () => {
        const steps = readWorkflowSteps()

        for (const [step, decision] of [
            ['Callback Approved', true],
            ['Callback Denied', false],
        ] as const) {
            const output = steps[step]?.attributes?.jsonRequestBody?.output
            expect(output?.approved).toBe(decision)
            expect(output?.['approved.$']).toBeUndefined()
        }
    })

    it('picks the callback that matches the decision variable', () => {
        const steps = readWorkflowSteps()
        const choice = steps['Check Approved']?.choiceList?.[0]

        expect(choice?.['variableA.$']).toBe('$.defineVariable.approved')
        expect(choice?.nextStep).toBe('Callback Approved')
        expect(steps['Check Approved']?.defaultStep).toBe('Callback Denied')
        for (const step of ['Set Violation Detected', 'Set Evaluation Failed']) {
            expect(steps[step]?.nextStep).toBe('Check Approved')
        }
        expect(steps['Check Violation']?.defaultStep).toBe('Check Approved')
    })

    /**
     * The risk summary already opens with the tier, so a comment that also states it reads
     * "Risk tier Low. Low".
     */
    it('never states the risk tier alongside the summary that repeats it', () => {
        const steps = readWorkflowSteps()

        for (const step of ['Set Low Risk', 'Set Medium Risk', 'Set High Risk', 'Set Violation Detected']) {
            const message = steps[step]?.attributes?.variables?.find((variable) =>
                variable.name?.endsWith('message')
            )?.variableA as string
            expect(message, `${step} has a comment`).toBeTruthy()
            expect(message, `${step} repeats the tier`).not.toMatch(
                /Risk tier (Low|Medium|High)\.? \{\{\$\.defineVariable\.riskSummary\}\}/
            )
        }
    })

    /** A SoD denial can follow a risk step that already said the request passed. */
    it('replaces the risk comment on a violation instead of appending to it', () => {
        const steps = readWorkflowSteps()
        const message = steps['Set Violation Detected']?.attributes?.variables?.find((variable) =>
            variable.name?.endsWith('message')
        )?.variableA as string

        expect(message).not.toContain('{{$.defineVariable.message}}')
        expect(message).toContain('{{$.defineVariable.sodSummary}}')
    })
})
