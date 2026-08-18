import { describe, expect, it, vi } from 'vitest'
import { createFrameworkLogger } from './logger'
import { defineOperationSchema } from './define-operation-schema'
import { createTestModePersist } from './test-mode-persist'

function captureLogger() {
    const lines: string[] = []
    const logger = createFrameworkLogger({
        requestId: 'req-test',
        consoleImpl: {
            log: (line) => lines.push(line),
            warn: (line) => lines.push(line),
            error: (line) => lines.push(line),
        },
    })
    return { lines, logger }
}

describe('createTestModePersist', () => {
    it('does not call createAccount but logs inhibited persist with attributes', async () => {
        const { lines, logger } = captureLogger()
        const registry = new Map<string, Record<string, unknown>>()
        const schema = defineOperationSchema({ outcome: 'string' })
        const { persist } = createTestModePersist(
            {
                sourceId: 'test-mode-local',
                operationSchema: schema,
                logger,
            },
            registry
        )

        await persist('req-001', { outcome: 'processed' })

        expect(lines.some((line) => line.includes('[test-mode] inhibited persist identity=req-001 status=success'))).toBe(
            true
        )
        expect(lines.some((line) => line.includes('outcome') && line.includes('processed'))).toBe(true)
        expect(registry.get('req-001')?.outcome).toBe('processed')
    })

    it('logs inhibited verifyPersisted without reading ISC accounts', async () => {
        const { lines, logger } = captureLogger()
        const registry = new Map<string, Record<string, unknown>>()
        const { persist, verifyPersisted } = createTestModePersist(
            { sourceId: 'test-mode-local', logger },
            registry
        )

        await persist('req-001', { outcome: 'a' }, undefined, { verify: false })
        await verifyPersisted(['req-001'])

        expect(lines.some((line) => line.includes('[test-mode] inhibited verifyPersisted identities=req-001'))).toBe(
            true
        )
    })

    it('records inhibited failed persist with details in attributes', async () => {
        const { lines, logger } = captureLogger()
        const registry = new Map<string, Record<string, unknown>>()
        const { persist } = createTestModePersist(
            { sourceId: 'test-mode-local', logger },
            registry
        )

        await persist('req-fail', undefined, 'failed', { verify: false, details: 'form create failed' })

        expect(lines.some((line) => line.includes('[test-mode] inhibited persist identity=req-fail status=failed'))).toBe(
            true
        )
        expect(registry.get('req-fail')).toMatchObject({
            status: 'failed',
            details: 'form create failed',
        })
    })

    it('does not log token values in persist output', async () => {
        const { lines, logger } = captureLogger()
        const { persist } = createTestModePersist(
            { sourceId: 'test-mode-local', logger },
            new Map()
        )

        await persist('req-001', { outcome: 'ok' })

        for (const line of lines) {
            expect(line).not.toContain('secret-token-value')
        }
    })
})
