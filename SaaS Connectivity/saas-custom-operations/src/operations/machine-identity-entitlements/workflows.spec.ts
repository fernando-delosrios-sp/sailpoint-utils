import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'

const APPLY_FILE = 'Machine Identity Entitlements - Apply.json'
const SCAN_FILE = 'Machine Identity Entitlements - Scan.json'
const WORKFLOWS_DIR = join(__dirname, '../../../workflows')

interface WorkflowStep {
    actionId?: string
    attributes?: {
        method?: string
        url?: string
        jsonRequestBody?: unknown
        param_authenticationRef?: string
        requestHeaders?: Record<string, string>
        variables?: Array<{ name?: string; variableA?: unknown }>
    }
    catch?: Array<{ next?: string }>
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
        type?: string
        mode?: string
        attributes?: { 'filter.$'?: string; id?: string }
    }
}

function readWorkflow(file: string): WorkflowExport {
    return JSON.parse(readFileSync(join(WORKFLOWS_DIR, file), 'utf8')) as WorkflowExport
}

describe(SCAN_FILE, () => {
    const INVOKE_BODY = '$.callSaaSCustomOperation.body'

    it('is launched as an interactive process and opens with the explanation panel', () => {
        const workflow = readWorkflow(SCAN_FILE)

        expect(workflow.trigger.type).toBe('EVENT')
        expect(workflow.trigger.attributes?.id).toBe('idn:interactive-process-launched')
        expect(workflow.definition.start).toBe('Message About This Process')
        expect(workflow.definition.steps['Message About This Process']?.actionId).toBe('sp:interactive-message')
    })

    it('invokes machine-identity-entitlements with a per-run requestId', () => {
        const invoke = readWorkflow(SCAN_FILE).definition.steps['Call SaaS Custom Operation']?.attributes
            ?.jsonRequestBody as { type?: string; input?: Record<string, unknown> } | undefined

        expect(invoke?.type).toBe('custom:machine-identity-entitlements')
        expect(invoke?.input?.requestId).toBe('mie:{{$.trigger.interactiveProcessId}}')
        expect(invoke?.input).not.toHaveProperty('identityId')
    })

    it('reads the invoke body only through string comparisons', () => {
        const steps = readWorkflow(SCAN_FILE).definition.steps
        const invokeFailed = steps['Check Invoke Result']
        const anyWork = steps['Check Trigger Accounts Written']

        expect(invokeFailed?.choiceList?.[0]).toMatchObject({
            comparator: 'StringContains',
            'variableA.$': INVOKE_BODY,
            variableB: '"status":"failed"',
        })
        expect(anyWork?.choiceList?.[0]).toMatchObject({
            comparator: 'StringContains',
            'variableA.$': INVOKE_BODY,
            variableB: '"triggerAccountsWritten":0',
        })

        const messages = Object.values(steps)
            .filter((step) => step.actionId === 'sp:interactive-message')
            .map((step) => JSON.stringify(step.attributes ?? {}))

        for (const message of messages) {
            expect(message).not.toMatch(/\$\.callSaaSCustomOperation\.body\./)
        }
    })

    it('shows the raw invoke body only on the failure panel', () => {
        const steps = readWorkflow(SCAN_FILE).definition.steps
        const showsBody = Object.entries(steps)
            .filter(([, step]) => JSON.stringify(step.attributes ?? {}).includes(INVOKE_BODY))
            .map(([name]) => name)

        expect(showsBody).toEqual(['Message Scan Failed'])
    })

    it('ends every outcome on a panel that names it', () => {
        const steps = readWorkflow(SCAN_FILE).definition.steps

        expect(steps['Check Invoke Result']?.defaultStep).toBe('Check Trigger Accounts Written')
        expect(steps['Check Trigger Accounts Written']?.choiceList?.[0]?.nextStep).toBe('Message No Work')
        expect(steps['Check Trigger Accounts Written']?.defaultStep).toBe('Message Work Written')
        expect(steps['Message No Work']?.nextStep).toBe('End Step - Success')
        expect(steps['Message Work Written']?.nextStep).toBe('End Step - Success')
        expect(steps['Message Scan Failed']?.nextStep).toBe('End Step - Failure')
        expect(steps['Get Access Token']?.catch?.[0]?.next).toBe('Message Token Failed')
        expect(steps['Call SaaS Custom Operation']?.catch?.[0]?.next).toBe('Message Invoke Error')
    })
})

describe(APPLY_FILE, () => {
    it('Trigger filters on operationName', () => {
        const workflow = readWorkflow(APPLY_FILE)
        expect(workflow.trigger.mode).toBe('advanced')
        expect(workflow.trigger.attributes?.id).toBe('idn:account-created')
        expect(workflow.trigger.attributes?.['filter.$']).toBe(
            '$.account.attributes[?(@.operationName == "custom:machine-identity-entitlements")]'
        )
    })

    it('Delegates the union patch to the connector', () => {
        const steps = readWorkflow(APPLY_FILE).definition.steps
        const invoke = steps['Call Apply Operation']?.attributes?.jsonRequestBody as
            | { type?: string; input?: Record<string, unknown> }
            | undefined

        // A workflow body cannot zip two parallel string arrays into {sourceId, entitlementId}
        // objects, so the union is built in the connector rather than in an sp:http PATCH.
        expect(steps['Patch User Entitlements']).toBeUndefined()
        expect(steps['Get Machine Identity']).toBeUndefined()
        expect(invoke?.type).toBe('custom:machine-identity-entitlements-apply')
        expect(invoke?.input?.['machineIdentityId.$']).toBe(
            "$.trigger.account.attributes['machine-identity-entitlements:machine-identity-id']"
        )
        expect(invoke?.input?.['entitlementIds.$']).toBe(
            "$.trigger.account.attributes['machine-identity-entitlements:entitlement-ids']"
        )
        expect(invoke?.input?.['entitlementSourceIds.$']).toBe(
            "$.trigger.account.attributes['machine-identity-entitlements:entitlement-source-ids']"
        )
    })

    it('Delete trigger account off by default', () => {
        const steps = readWorkflow(APPLY_FILE).definition.steps
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
        const steps = readWorkflow(APPLY_FILE).definition.steps

        expect(steps['Call Apply Operation']?.nextStep).toBe('Check Delete Trigger Account')
        expect(steps['Delete Trigger Account']?.attributes?.method).toBe('delete')
        expect(steps['Delete Trigger Account']?.nextStep).toBe('End Step - Success')
    })
})
