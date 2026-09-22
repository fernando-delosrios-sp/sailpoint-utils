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

    it('Risk situation summary term', () => {
        expect(operationReadme).toContain('The **risk situation summary** is plain text for an approver')
        expect(operationReadme).not.toContain('risk explanation')
        expect(operationReadme).not.toContain('situation summary panel')
    })

    it('Summary is distinguished from contributing ids', () => {
        expect(operationReadme).toContain('Names and ids do not appear in the risk situation summary')
        expect(operationReadme).toContain(
            'Use\n`evaluate-access-request-risk:contributing-ids` when a machine-readable identifier list is needed'
        )
    })

    it('Risk driver term', () => {
        expect(operationReadme).toContain('A **risk driver**')
        expect(operationReadme).not.toContain('contributor')
        expect(operationReadme).not.toContain('risk item')
        expect(operationReadme).not.toContain('offender')
    })

    it('Container is not a driver for its contents', () => {
        expect(operationReadme).toContain(
            'if a clean role\ncontains a High entitlement, the entitlement is the High risk driver'
        )
        expect(operationReadme).toContain('the role appears only in the\nevaluated tally')
    })

    it('Deciding rule term', () => {
        expect(operationReadme).toContain('**deciding rule** says why')
        expect(operationReadme).toContain('**effective privilege**')
        expect(operationReadme).toContain('**Risk metadata**')
        expect(operationReadme).toContain('roles and access profiles are\nalways decided by Risk metadata')
    })

    it('Attribution is single-valued', () => {
        expect(operationReadme).toContain('A driver matching both rules is attributed to effective privilege only')
    })
})
