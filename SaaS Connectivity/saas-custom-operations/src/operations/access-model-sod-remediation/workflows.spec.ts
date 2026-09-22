import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'

const WORKFLOW_FILE = 'Access Model SOD - Analysis.json'
const WORKFLOWS_DIR = join(__dirname, '../../../workflows')
const EXPECTED_REQUEST_ID = 'access-model-sod-remediation'
const INVOKE_BODY = '$.callSaaSCustomOperation.body'

interface WorkflowStep {
    actionId?: string
    attributes?: {
        jsonRequestBody?: {
            type?: string
            input?: Record<string, unknown>
        }
        message?: string
        title?: string
        'context.$'?: string
        'input.$'?: string
        start?: string
        steps?: Record<string, WorkflowStep>
        filterCriteria?: string
        operator?: string
        value?: string
        'interactiveProcessId.$'?: string
        'ownerId.$'?: string
    }
    catch?: Array<{ next?: string }>
    choiceList?: Array<{ comparator?: string; nextStep?: string; 'variableA.$'?: string; variableB?: string }>
    defaultStep?: string
    nextStep?: string
    type?: string
}

interface WorkflowExport {
    definition: {
        start: string
        steps: Record<string, WorkflowStep>
    }
    trigger?: {
        type?: string
        attributes?: { id?: string }
    }
}

function readWorkflow(): WorkflowExport {
    return JSON.parse(readFileSync(join(WORKFLOWS_DIR, WORKFLOW_FILE), 'utf8')) as WorkflowExport
}

describe(WORKFLOW_FILE, () => {
    it('is launched as an interactive process and opens with the explanation panel', () => {
        const workflow = readWorkflow()

        expect(workflow.trigger?.type).toBe('EVENT')
        expect(workflow.trigger?.attributes?.id).toBe('idn:interactive-process-launched')
        expect(workflow.definition.start).toBe('Message About This Process')
        expect(workflow.definition.steps['Message About This Process']?.actionId).toBe('sp:interactive-message')
    })

    it('invokes the access-model SoD scan with a stable requestId', () => {
        const invoke = readWorkflow().definition.steps['Call SaaS Custom Operation']?.attributes?.jsonRequestBody

        expect(invoke?.type).toBe('custom:access-model-sod-remediation')
        expect(invoke?.input?.requestId).toBe(EXPECTED_REQUEST_ID)
        expect(invoke?.input?.formName).toBe('Access Model SOD Remediation')
    })

    /**
     * The invoke answers `text/plain` NDJSON, so the body is a string in workflow state. A JSONPath into
     * it silently renders as literal `{{...}}` text, which is why both reads are string comparisons.
     */
    it('reads the invoke body only through string comparisons', () => {
        const steps = readWorkflow().definition.steps
        const invokeFailed = steps['Check Invoke Result']
        const anyConflicts = steps['Check Violations Found']

        expect(invokeFailed?.choiceList?.[0]).toMatchObject({
            comparator: 'StringContains',
            'variableA.$': INVOKE_BODY,
            variableB: '"status":"failed"',
        })
        expect(anyConflicts?.choiceList?.[0]).toMatchObject({
            comparator: 'StringContains',
            'variableA.$': INVOKE_BODY,
            variableB: '"access-model-sod-remediation:violations-found":0',
        })

        const messages = Object.values(steps)
            .filter((step) => step.actionId === 'sp:interactive-message')
            .map((step) => step.attributes?.message ?? '')

        for (const message of messages) {
            expect(message).not.toMatch(/\$\.callSaaSCustomOperation\.body\./)
        }
    })

    /** The raw stream is error text, useful only where the scan reports a failure it alone explains. */
    it('shows the raw invoke body only on the failure panel', () => {
        const steps = readWorkflow().definition.steps
        const showsBody = Object.entries(steps)
            .filter(([, step]) => (step.attributes?.message ?? '').includes(INVOKE_BODY))
            .map(([name]) => name)

        expect(showsBody).toEqual(['Message Scan Failed'])
    })

    it('ends every outcome on a panel that names it', () => {
        const steps = readWorkflow().definition.steps

        expect(steps['Check Invoke Result']?.defaultStep).toBe('Check Violations Found')
        expect(steps['Check Violations Found']?.choiceList?.[0]?.nextStep).toBe('Message No Conflicts')
        expect(steps['Check Violations Found']?.defaultStep).toBe('Get Result Source')
        expect(steps['Message No Conflicts']?.nextStep).toBe('End Step - Success')
        expect(steps['Loop Conflicts']?.nextStep).toBe('End Step - Success')
        expect(steps['Message Scan Failed']?.nextStep).toBe('End Step - Failure')
        expect(steps['Get Access Token']?.catch?.[0]?.next).toBe('Message Token Failed')
        expect(steps['Call SaaS Custom Operation']?.catch?.[0]?.next).toBe('Message Invoke Error')
    })

    /**
     * Get Accounts filters on source id with `eq` only, so the whole result source is read and the loop
     * input narrows it to this operation's records.
     */
    it('reads the conflict records back from the result source', () => {
        const steps = readWorkflow().definition.steps

        expect(steps['Read Conflict Records']?.attributes).toMatchObject({
            filterCriteria: 'sourceId',
            operator: 'eq',
            value: '{{$.getResultSource.body[0].id}}',
        })
        expect(steps['Get Result Source']?.catch?.[0]?.next).toBe('Message Conflicts Unavailable')
        expect(steps['Read Conflict Records']?.catch?.[0]?.next).toBe('Message Conflicts Unavailable')
        expect(steps['Message Conflicts Unavailable']?.nextStep).toBe('End Step - Success')
    })

    /**
     * Outer workflow state is not visible inside a loop, so the interactive process and its launcher only
     * reach the per-conflict panel through the loop context.
     */
    it('renders one panel per conflict record that has a form', () => {
        const loop = readWorkflow().definition.steps['Loop Conflicts']
        const inner = loop?.attributes?.steps ?? {}

        expect(loop?.actionId).toBe('sp:loop:iterator')
        expect(loop?.attributes?.['context.$']).toBe('$.trigger')
        expect(loop?.attributes?.['input.$']).toBe(
            `$.readConflictRecords.accounts[?(@.attributes.operationName == 'custom:${EXPECTED_REQUEST_ID}')]`
        )
        expect(loop?.attributes?.start).toBe('Check Conflict Record')

        expect(inner['Check Conflict Record']?.choiceList?.[0]).toMatchObject({
            comparator: 'IsPresent',
            nextStep: 'Message Conflict',
            'variableA.$': `$.loop.loopInput.attributes['${EXPECTED_REQUEST_ID}:conflicting-entitlements-group-a']`,
        })
        expect(inner['Check Conflict Record']?.defaultStep).toBe('End Step - Success')

        const panel = inner['Message Conflict']
        expect(panel?.actionId).toBe('sp:interactive-message')
        expect(panel?.attributes?.['interactiveProcessId.$']).toBe('$.loop.context.interactiveProcessId')
        expect(panel?.attributes?.['ownerId.$']).toBe('$.loop.context.launchedBy.id')
        expect(panel?.attributes?.title).toBe(
            `{{$.loop.loopInput.attributes['${EXPECTED_REQUEST_ID}:access-item-name']}}`
        )
        expect(inner['End Step - Success']?.type).toBe('success')
    })

    /** Catalog definitions are useful to the launcher; the owner-only remediation form is not. */
    it('links the access item and policy definitions, but not the remediation form', () => {
        const loop = readWorkflow().definition.steps['Loop Conflicts']
        const message = loop?.attributes?.steps?.['Message Conflict']?.attributes?.message ?? ''

        for (const field of [
            'access-item-name',
            'access-item-type',
            'policy-name',
            'conflicting-entitlements-group-a',
            'conflicting-entitlements-group-b',
        ]) {
            expect(message).toContain(`{{$.loop.loopInput.attributes['${EXPECTED_REQUEST_ID}:${field}']}}`)
        }
        expect(message).toContain(`{{$.loop.loopInput.attributes['${EXPECTED_REQUEST_ID}:form-email-recipients'][0]}}`)
        expect(message).toContain(`href="{{$.loop.loopInput.attributes['${EXPECTED_REQUEST_ID}:access-item-url']}}"`)
        expect(message).toContain(`href="{{$.loop.loopInput.attributes['${EXPECTED_REQUEST_ID}:policy-url']}}"`)
        expect(message).not.toContain(`${EXPECTED_REQUEST_ID}:form-url`)
    })

    /** Each policy side gets its own column and its own accent, so a reader sees two sets, not one list. */
    it('columns the two policy sides in different colours', () => {
        const message =
            readWorkflow().definition.steps['Loop Conflicts']?.attributes?.steps?.['Message Conflict']?.attributes
                ?.message ?? ''
        const columns = message.match(/<td width="50%"[\s\S]*?<\/td>/g) ?? []

        expect(columns).toHaveLength(2)
        expect(columns[0]).toContain('Group A')
        expect(columns[0]).toContain(`${EXPECTED_REQUEST_ID}:conflicting-entitlements-group-a`)
        expect(columns[1]).toContain('Group B')
        expect(columns[1]).toContain(`${EXPECTED_REQUEST_ID}:conflicting-entitlements-group-b`)

        const accent = (column: string): string | undefined => /border-left:5px solid (#[0-9a-f]{6})/.exec(column)?.[1]
        expect(accent(columns[0])).toBeDefined()
        expect(accent(columns[0])).not.toBe(accent(columns[1]))
    })
})
