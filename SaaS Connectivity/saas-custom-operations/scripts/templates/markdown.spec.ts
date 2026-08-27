import { describe, expect, it } from 'vitest'
import { renderAccessTokenGuide } from './access-token'
import { OperationMeta } from './types'
import { renderWorkflowInvocationGuide } from './workflow-invocation'

const exampleOp: OperationMeta = {
    command: 'custom:example',
    modulePath: '/fake/example-operation.ts',
    input: [{ name: 'message', optional: true, type: 'string' }],
    output: [
        { name: 'summary', optional: false, type: 'string' },
        { name: 'step', optional: true, type: 'string' },
    ],
    childIdentities: ['${ctx.requestId}:detail'],
}

describe('renderAccessTokenGuide', () => {
    it('contains OAuth placeholders and token endpoint from reference workflow', () => {
        const md = renderAccessTokenGuide()
        expect(md).toContain('workflows/SaaS Custom Operations.json')
        expect(md).toContain('SaaS Custom Operations Call')
        expect(md).toContain('Configuration')
        expect(md).toContain('Get Access Token')
        expect(md).toContain('{{$.configuration.aPIURL}}/oauth/token')
        expect(md).toContain('grant_type=client_credentials')
        expect(md).toContain('{{$.getAccessToken.body.access_token}}')
        expect(md).not.toContain('company22986-poc')
        expect(md).not.toContain('170f7a14192043b49ce429fed77f6c9e')
        expect(md).toContain('SaaS Custom Operations Source Name')
        expect(md).toContain('{{$.configuration.saaSCustomOperationsSourceName}}')
        expect(md).not.toContain('Source ID')
        expect(md).not.toContain('saaSCustomOperationsSourceID')
    })
})

describe('renderWorkflowInvocationGuide', () => {
    it('contains per-operation invoke section with expected fields', () => {
        const md = renderWorkflowInvocationGuide([exampleOp])
        expect(md).toContain('custom:example')
        expect(md).toContain(
            '{{$.configuration.aPIURL}}/beta/platform-connectors/{{$.configuration.saaSCustomOperationsConnectorID}}/invoke'
        )
        expect(md).toContain('"requestId"')
        expect(md).toContain('"message"')
        expect(md).toContain('summary')
        expect(md).toContain('nativeIdentity')
        expect(md).toContain('Read SaaS Custom Operation Result')
        expect(md).toContain('"sourceName": "{{$.configuration.saaSCustomOperationsSourceName}}"')
        expect(md).not.toContain('"sourceId"')
    })

    it('links to access-token.md without duplicating full OAuth section', () => {
        const md = renderWorkflowInvocationGuide([exampleOp])
        expect(md).toContain('[access-token.md](./access-token.md)')
        expect(md).not.toContain('grant_type=client_credentials')
    })

    it('documents child identity read when detected', () => {
        const md = renderWorkflowInvocationGuide([exampleOp])
        expect(md).toContain('Child identities')
        expect(md).toContain('{{requestId}}:detail')
    })
})

