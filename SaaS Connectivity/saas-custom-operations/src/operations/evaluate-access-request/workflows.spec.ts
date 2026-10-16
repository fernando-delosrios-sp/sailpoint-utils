import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'

const WORKFLOW_FILE = 'Access Request Pre-Check - Risk analysis and SOD.json'
const WORKFLOWS_DIR = join(__dirname, '../../../workflows')
const EXPECTED_REQUEST_ID = 'access-request-precheck:{{$.trigger.accessRequestId}}:submitted'

interface WorkflowVariable {
    name?: string
    variableA?: unknown
    'variableA.$'?: string
}

interface WorkflowStep {
    actionId?: string
    attributes?: {
        variables?: WorkflowVariable[]
        filterCriteria?: string
        operator?: string
        value?: string
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

function successors(step: WorkflowStep): string[] {
    return [
        step.nextStep,
        step.defaultStep,
        ...(step.choiceList ?? []).map((choice) => choice.nextStep),
        ...(step.catch ?? []).map((handler) => handler.next),
    ].filter((next): next is string => Boolean(next))
}

describe(WORKFLOW_FILE, () => {
    it('invokes the unified evaluate-access-request command once with SoD enabled', () => {
        const invoke = readWorkflowSteps()['Call Evaluate Access Request']?.attributes?.jsonRequestBody

        expect(invoke?.type).toBe('custom:evaluate-access-request')
        expect(invoke?.input?.accessRequestId).toBe('{{$.trigger.accessRequestId}}')
        expect(invoke?.input?.identityId).toBe('{{$.trigger.requestedFor.id}}')
        expect(invoke?.input?.inflightOnly).toBe('{{$.configuration.inflightOnly}}')
        expect(invoke?.input?.considerPrivilege).toBe('{{$.configuration.considerPrivilege}}')
        expect(invoke?.input?.evaluateSod).toBe('true')
        expect(invoke?.input?.['requestedItems.$']).toBe('$.trigger.requestedItems')
        expect(invoke?.input?.requestId).toBe(EXPECTED_REQUEST_ID)
        expect(invoke?.input?.waitForPersist).toBeUndefined()
    })

    it('defaults Inflight Only to true in Configuration', () => {
        const configuration = readWorkflowSteps()['Configuration'] as {
            attributes?: { variables?: Array<{ name?: string; variableA?: unknown }> }
        }
        const inflightOnly = configuration.attributes?.variables?.find((variable) => variable.name === 'Inflight Only')

        expect(inflightOnly?.variableA).toBe('true')
    })

    it('reads the result account instead of pattern-matching the HTTP body for tier and SoD', () => {
        const steps = readWorkflowSteps()
        const read = steps['Read Precheck Result']

        expect(steps['Check Summary Present']).toBeUndefined()
        expect(read?.actionId).toBe('sp:get-accounts')
        expect(read?.attributes?.filterCriteria).toBe('nativeIdentity')
        expect(read?.attributes?.operator).toBe('eq')
        expect(read?.attributes?.value).toBe(EXPECTED_REQUEST_ID)
        expect(read?.catch?.map((handler) => handler.next)).toEqual(['Set Evaluation Failed'])

        expect(steps['Check Tier']?.choiceList?.[0]).toEqual({
            comparator: 'StringEquals',
            nextStep: 'Set High Risk',
            'variableA.$': "$.readPrecheckResult.accounts[0].attributes['evaluate-access-request-risk:tier']",
            variableB: 'High',
        })
        expect(steps['Check Violation']?.choiceList?.[0]).toEqual({
            comparator: 'StringEquals',
            nextStep: 'Set Violation Detected',
            'variableA.$': "$.readPrecheckResult.accounts[0].attributes['preventive-sod-check:has-violation']",
            variableB: 'true',
        })
    })

    it('routes an HTTP-200 failed invoke body to the failure step before reading the account', () => {
        const steps = readWorkflowSteps()
        const checkInvoke = steps['Check Invoke Result']

        expect(steps['Call Evaluate Access Request']?.nextStep).toBe('Check Invoke Result')
        expect(checkInvoke?.choiceList).toEqual([
            {
                comparator: 'StringContains',
                nextStep: 'Set Evaluation Failed',
                'variableA.$': '$.callEvaluateAccessRequest.body',
                variableB: '"status":"failed"',
            },
        ])
        expect(checkInvoke?.defaultStep).toBe('Read Precheck Result')
    })

    it('compares the approved decision variable as a string', () => {
        const choice = readWorkflowSteps()['Check Approved']?.choiceList?.[0]

        expect(readWorkflowSteps()['Check Approved']?.actionId).toBe('sp:compare-strings')
        expect(choice?.comparator).toBe('StringEquals')
        expect(choice?.['variableA.$']).toBe('$.defineVariable.approved')
        expect(choice?.variableB).toBe('true')
    })

    it('writes approved on every route to Check Approved', () => {
        const { start, steps } = readWorkflow()
        const unwritten: string[][] = []
        const seen = new Set<string>()

        const walk = (stepName: string, written: boolean, route: string[]) => {
            const step = steps[stepName]
            if (!step) return
            const key = `${stepName}|${written}|${route.join('>')}`
            if (seen.has(key)) return
            seen.add(key)

            const nextWritten =
                written ||
                (step.actionId === 'sp:update-variable' &&
                    (step.attributes?.variables ?? []).some(
                        (variable) => variable.name === '$.defineVariable.approved'
                    ))

            if (stepName === 'Check Approved' && !nextWritten) {
                unwritten.push(route.concat(stepName))
            }

            for (const next of successors(step)) {
                walk(next, nextWritten, route.concat(stepName))
            }
        }

        walk(start, false, [])
        expect(unwritten).toEqual([])
    })

    it('leaves no step pointing at a name the workflow does not define', () => {
        const steps = readWorkflowSteps()
        const targets = Object.values(steps).flatMap((step) => successors(step))

        expect(targets.filter((target) => !(target in steps))).toEqual([])
    })
})
