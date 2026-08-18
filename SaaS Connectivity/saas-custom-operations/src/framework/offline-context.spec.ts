import { readFileSync, readdirSync } from 'node:fs'
import { join } from 'node:path'
import { ConnectorError } from '@sailpoint/connector-sdk'
import { describe, expect, it } from 'vitest'
import { isOfflineContext } from './offline-context'

const OFFLINE_BRANCHING_OPERATIONS = [
    'access-model-sod-remediation',
    'access-model-sod-remediation-apply',
    'governance-group-emails',
    'preventive-sod-check',
    'sod-remediation',
]

describe('isOfflineContext', () => {
    it('returns true when both connection fields are absent', () => {
        expect(isOfflineContext({ apiUrl: '', token: '' })).toBe(true)
    })

    it('returns true when both connection fields are blank', () => {
        expect(isOfflineContext({ apiUrl: '  ', token: '\t' })).toBe(true)
    })

    it('returns false when both connection fields are present', () => {
        expect(
            isOfflineContext({
                apiUrl: 'https://tenant.api.identitynow.com',
                token: 'pat-token',
            })
        ).toBe(false)
    })

    it('rejects partial config when apiUrl is set and token is absent', () => {
        expect(() =>
            isOfflineContext({ apiUrl: 'https://tenant.api.identitynow.com', token: '' })
        ).toThrow(ConnectorError)
        expect(() =>
            isOfflineContext({ apiUrl: 'https://tenant.api.identitynow.com', token: '' })
        ).toThrow(/Incomplete connection config/)
    })

    it('rejects partial config when token is set and apiUrl is absent', () => {
        expect(() => isOfflineContext({ apiUrl: '', token: 'pat-token' })).toThrow(ConnectorError)
        expect(() => isOfflineContext({ apiUrl: '', token: 'pat-token' })).toThrow(
            /Incomplete connection config/
        )
    })
})

describe('operations use shared offline helper', () => {
    it('uses isOfflineContext instead of local apiUrl/token predicates', () => {
        const operationsDir = join(__dirname, '../operations')
        const localPredicate = /!\s*ctx\.apiUrl\s*(\|\||&&)\s*!?\s*ctx\.token/

        for (const slug of OFFLINE_BRANCHING_OPERATIONS) {
            const source = readFileSync(join(operationsDir, slug, 'index.ts'), 'utf8')

            expect(source, slug).toContain('isOfflineContext(ctx)')
            expect(source, slug).not.toMatch(localPredicate)
        }
    })

    it('covers every operation handler that branches on offline mode', () => {
        const operationsDir = join(__dirname, '../operations')
        const offlineBranchingSlugs = readdirSync(operationsDir, { withFileTypes: true })
            .filter((entry) => entry.isDirectory() && !['_template', 'example'].includes(entry.name))
            .map((entry) => entry.name)
            .filter((slug) => {
                const source = readFileSync(join(operationsDir, slug, 'index.ts'), 'utf8')
                return /\boffline\b/.test(source)
            })

        expect(offlineBranchingSlugs.sort()).toEqual([...OFFLINE_BRANCHING_OPERATIONS].sort())
    })
})
