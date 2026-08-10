import { describe, expect, it } from 'vitest'
import { formatPayloadOutputSummary, formatSpreadJson } from './payload-output'

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

describe('formatPayloadOutputSummary', () => {
    it('includes invoke header, simulated persist, response, and primary output sections', () => {
        process.env.NO_COLOR = '1'
        const formatted = formatPayloadOutputSummary({
            type: 'custom:sod-remediation',
            requestId: 'offline-001',
            testMode: true,
            inhibitedPersists: [
                {
                    identity: 'offline-001',
                    status: 'success',
                    attributes: {
                        id: 'offline-001',
                        formUrl: 'https://example.com/form/1',
                        situationSummary: 'SOD Violation Remediation Required',
                    },
                },
            ],
            response: { status: 'success' },
        })

        expect(formatted).toContain('Local invoke')
        expect(formatted).toContain('type=custom:sod-remediation')
        expect(formatted).toContain('Simulated persist (testMode=true)')
        expect(formatted).toContain('Persisted operation output (primary identity)')
        expect(formatted).toContain('"formUrl": "https://example.com/form/1"')
        expect(formatted).toContain('Operation response (ctx.res.send)')
        delete process.env.NO_COLOR
    })
})
