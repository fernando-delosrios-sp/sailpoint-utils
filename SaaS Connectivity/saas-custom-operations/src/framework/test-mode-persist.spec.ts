import { describe, expect, it, vi } from 'vitest'
import { defineOperationSchema } from './define-operation-schema'
import { createTestModePersist } from './test-mode-persist'

describe('createTestModePersist', () => {
    it('does not call createAccount but logs inhibited persist with attributes', async () => {
        const lines: string[] = []
        const registry = new Map<string, Record<string, unknown>>()
        const schema = defineOperationSchema({ outcome: 'string' })
        const { persist } = createTestModePersist(
            {
                sourceId: 'test-mode-local',
                operationSchema: schema,
                log: (line) => lines.push(line),
            },
            registry
        )

        await persist('req-001', { outcome: 'processed' })

        expect(lines.some((line) => line.includes('[test-mode] inhibited persist identity=req-001'))).toBe(true)
        expect(lines.some((line) => line.includes('outcome') && line.includes('processed'))).toBe(true)
        expect(registry.get('req-001')?.outcome).toBe('processed')
    })

    it('logs inhibited verifyPersisted without reading ISC accounts', async () => {
        const lines: string[] = []
        const registry = new Map<string, Record<string, unknown>>()
        const { persist, verifyPersisted } = createTestModePersist(
            { sourceId: 'test-mode-local', log: (line) => lines.push(line) },
            registry
        )

        await persist('req-001', { outcome: 'a' }, undefined, { verify: false })
        await verifyPersisted(['req-001'])

        expect(lines.some((line) => line.includes('[test-mode] inhibited verifyPersisted identities=req-001'))).toBe(
            true
        )
    })

    it('does not log token values in persist output', async () => {
        const lines: string[] = []
        const { persist } = createTestModePersist(
            { sourceId: 'test-mode-local', log: (line) => lines.push(line) },
            new Map()
        )

        await persist('req-001', { outcome: 'ok' })

        for (const line of lines) {
            expect(line).not.toContain('secret-token-value')
        }
    })
})
