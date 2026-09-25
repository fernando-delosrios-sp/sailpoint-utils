import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'

const WORKFLOW_FILE = 'Machine Identity Entitlements - Apply.json'
const WORKFLOWS_DIR = join(__dirname, '../../../workflows')

interface WorkflowStep {
    actionId?: string
    attributes?: {
        method?: string
        url?: string
        jsonRequestBody?: unknown
        variables?: Array<{ name?: string; variableA?: unknown }>
    }
    choiceList?: Array<{ comparator?: string; nextStep?: string; variableB?: unknown; 'variableA.$'?: string }>
    defaultStep?: string
    nextStep?: string
}

interface WorkflowExport {
    definition: {
        start: string
        steps: Record<string, WorkflowStep>
    }
    trigger: {
        mode?: string
        attributes?: { 'filter.$'?: string; id?: string }
    }
}

function readWorkflow(): WorkflowExport {
    return JSON.parse(readFileSync(join(WORKFLOWS_DIR, WORKFLOW_FILE), 'utf8')) as WorkflowExport
}

describe(WORKFLOW_FILE, () => {
    it('Trigger filters on operationName', () => {
        const workflow = readWorkflow()
        expect(workflow.trigger.mode).toBe('advanced')
        expect(workflow.trigger.attributes?.id).toBe('idn:account-created')
        expect(workflow.trigger.attributes?.['filter.$']).toBe('operationName == custom:machine-identity-entitlements')
    })

    it('Patch unions user entitlements', () => {
        const steps = readWorkflow().definition.steps
        const getStep = steps['Get Machine Identity']
        const patchStep = steps['Patch User Entitlements']
        const body = JSON.stringify(patchStep?.attributes?.jsonRequestBody ?? {})

        expect(getStep?.attributes?.method).toBe('get')
        expect(getStep?.nextStep).toBe('Patch User Entitlements')
        expect(patchStep?.attributes?.method).toBe('patch')
        expect(body).toContain('getMachineIdentity.body.userEntitlements')
        expect(body).toContain('machine-identity-entitlements:entitlement-ids')
        expect(body).not.toMatch(/"path":\s*"\/userEntitlements"[\s\S]*"value"\s*:\s*\[\s*\{/)
    })

    it('Delete trigger account off by default', () => {
        const steps = readWorkflow().definition.steps
        const deleteVariable = steps.Configuration?.attributes?.variables?.find(
            (variable) => variable.name === 'Delete Trigger Account'
        )
        const check = steps['Check Delete Trigger Account']

        expect(deleteVariable?.variableA).toBe('false')
        expect(check?.defaultStep).toBe('End Step - Success')
        expect(check?.choiceList?.[0]?.nextStep).toBe('Delete Trigger Account')
        expect(check?.choiceList?.[0]?.variableB).toBe('true')
    })

    it('Delete trigger account after successful patch', () => {
        const steps = readWorkflow().definition.steps

        expect(steps['Patch User Entitlements']?.nextStep).toBe('Check Delete Trigger Account')
        expect(steps['Delete Trigger Account']?.attributes?.method).toBe('delete')
        expect(steps['Get Machine Identity']?.nextStep).not.toBe('Delete Trigger Account')
        expect(steps['Delete Trigger Account']?.nextStep).toBe('End Step - Success')
    })
})
