import { describe, expect, it } from 'vitest'
import { formatFixtureOutputSummary, formatSpreadJson } from './fixture-output'

describe('formatSpreadJson', () => {
    it('inserts blank lines between top-level object properties', () => {
        const formatted = formatSpreadJson({ status: 'success', outcome: 'ok' })
        expect(formatted).toBe(`{
    "status": "success",

    "outcome": "ok"
}`)
    })

    it('pretty-prints arrays without extra spacing rules', () => {
        const formatted = formatSpreadJson([{ identity: 'req-001' }])
        expect(formatted).toContain('"identity": "req-001"')
    })
})

describe('formatFixtureOutputSummary', () => {
    it('includes inhibited persist and response sections', () => {
        process.env.NO_COLOR = '1'
        const formatted = formatFixtureOutputSummary({
            inhibitedPersists: [
                {
                    identity: 'offline-001',
                    status: 'success',
                    attributes: { id: 'offline-001', summary: 'hello' },
                },
            ],
            response: { status: 'success' },
        })

        expect(formatted).toContain('Inhibited persist outputs (would-be ISC accounts)')
        expect(formatted).toContain('Operation response (ctx.res.send)')
        expect(formatted).toContain('"summary": "hello"')
        expect(formatted).toContain('"status": "success"')
        delete process.env.NO_COLOR
    })
})
