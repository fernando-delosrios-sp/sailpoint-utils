import { existsSync, readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'

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
        const anyWork = steps['Check Identities Updated']

        expect(invokeFailed?.choiceList?.[0]).toMatchObject({
            comparator: 'StringContains',
            'variableA.$': INVOKE_BODY,
            variableB: '"status":"failed"',
        })
        expect(anyWork?.choiceList?.[0]).toMatchObject({
            comparator: 'StringContains',
            'variableA.$': INVOKE_BODY,
            variableB: '"identitiesUpdated":0',
        })
        expect(steps['Check Partial Result']?.choiceList?.[0]).toMatchObject({
            comparator: 'StringContains',
            'variableA.$': INVOKE_BODY,
            variableB: '"identitiesFailed":0',
        })

        const messages = Object.values(steps)
            .filter((step) => step.actionId === 'sp:interactive-message')
            .map((step) => JSON.stringify(step.attributes ?? {}))

        for (const message of messages) {
            expect(message).not.toMatch(/\$\.callSaaSCustomOperation\.body\./)
        }
    })

    it('shows the raw invoke body on partial and failure panels', () => {
        const steps = readWorkflow(SCAN_FILE).definition.steps
        const showsBody = Object.entries(steps)
            .filter(([, step]) => JSON.stringify(step.attributes ?? {}).includes(INVOKE_BODY))
            .map(([name]) => name)

        expect(showsBody).toEqual(['Message Partial', 'Message Scan Failed'])
    })

    it('ends every outcome on a panel that names it', () => {
        const steps = readWorkflow(SCAN_FILE).definition.steps

        expect(steps['Check Invoke Result']?.defaultStep).toBe('Check Identities Updated')
        expect(steps['Check Identities Updated']?.choiceList?.[0]?.nextStep).toBe('Message No Work')
        expect(steps['Check Identities Updated']?.defaultStep).toBe('Check Partial Result')
        expect(steps['Check Partial Result']?.choiceList?.[0]?.nextStep).toBe('Message Work Applied')
        expect(steps['Check Partial Result']?.defaultStep).toBe('Message Partial')
        expect(steps['Message No Work']?.nextStep).toBe('End Step - Success')
        expect(steps['Message Work Applied']?.nextStep).toBe('End Step - Success')
        expect(steps['Message Partial']?.nextStep).toBe('End Step - Success')
        expect(steps['Message Scan Failed']?.nextStep).toBe('End Step - Failure')
        expect(steps['Get Access Token']?.catch?.[0]?.next).toBe('Message Token Failed')
        expect(steps['Call SaaS Custom Operation']?.catch?.[0]?.next).toBe('Message Invoke Error')
    })

    it('Standalone apply path is absent', async () => {
        const { OPERATION_HANDLERS } = await import('../auto-registry')
        const spec = await import('../../../connector-spec.json')
        expect(OPERATION_HANDLERS).not.toHaveProperty('custom:machine-identity-entitlements-apply')
        expect(spec.default.commands).not.toContain('custom:machine-identity-entitlements-apply')
        expect(existsSync(join(WORKFLOWS_DIR, 'Machine Identity Entitlements - Apply.json'))).toBe(false)
    })
})
