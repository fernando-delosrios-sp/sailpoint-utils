import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'

const operationReadme = readFileSync(join(__dirname, 'README.md'), 'utf8')
const rootReadme = readFileSync(join(__dirname, '../../../README.md'), 'utf8')

describe('ubiquitous-language documentation contracts', () => {
    it('Risk persist identity term', () => {
        expect(operationReadme).toContain('**risk persist identity**')
        expect(operationReadme).toContain('which is the invoke `requestId`')
        expect(rootReadme).toContain('nativeIdentity eq')
        expect(rootReadme).toContain('evaluate-access-request-risk:{accessRequestId}:dynamic')
    })

    it('Failure account uses the same term', () => {
        expect(operationReadme).toContain('failure accounts use the\nsame risk persist identity as successful results')
    })

    it('Wrapper discriminator term', () => {
        expect(operationReadme).toContain('**wrapper discriminator**')
        expect(operationReadme).toContain('`:submitted`, `:dynamic`, or `:dynamic-approval`')
    })

    it('Discriminator is retained inside the request id', () => {
        expect(operationReadme).toContain('wrapper discriminator')
        expect(operationReadme).toContain('evaluate-access-request-risk:{{$.trigger.accessRequestId}}:submitted')
        expect(operationReadme).toContain('evaluate-access-request-risk:{{$.trigger.accessRequestId}}:dynamic')
        expect(operationReadme).toContain('evaluate-access-request-risk:{{$.trigger.accessRequestId}}:dynamic-approval')
    })

    it('Result identity term', () => {
        expect(rootReadme).toContain("optional builder for the operation's **result identity**")
        expect(rootReadme).toContain('defaults to the invoke `requestId`')
        expect(rootReadme).toContain('Automatic failure persist')
        expect(rootReadme).toContain('writes the failed account to `ctx.resultIdentity`')
    })

    it('Result identity generalizes the per-operation terms', () => {
        expect(rootReadme).toContain('**risk persist identity**')
        expect(rootReadme).toContain('**Result identity** is the generic framework term')
        expect(rootReadme).toContain('`ctx.resultIdentity`')
    })
})
