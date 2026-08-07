import { describe, expect, it, vi } from 'vitest'
import { readFileSync } from 'fs'
import { join } from 'path'
import { loadFixture, runFixture, runFixtureFromPath } from './run-operation-fixture'
import { writeFileSync, unlinkSync } from 'fs'
import { tmpdir } from 'os'

describe('run-operation-fixture', () => {
    it('rejects fixture missing command', () => {
        const path = join(tmpdir(), `fixture-${Date.now()}.json`)
        writeFileSync(path, JSON.stringify({ config: { testMode: true }, input: { requestId: 'x' } }))
        try {
            expect(() => loadFixture(path)).toThrow(/command/)
        } finally {
            unlinkSync(path)
        }
    })

    it('runs valid offline fixture and returns res.send payload', async () => {
        const payload = await runFixture({
            command: 'custom:example',
            config: { testMode: true },
            input: { requestId: 'fixture-run-001', message: 'hello' },
        })

        expect(payload).toEqual({ status: 'success' })
    })

    it('prints res.send payload when run completes', async () => {
        const logSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
        const payload = await runFixture({
            command: 'custom:example',
            config: { testMode: true },
            input: { requestId: 'fixture-run-002' },
        })

        expect(payload).toEqual({ status: 'success' })
        logSpy.mockRestore()
    })

    it('returns exit code 1 for fixture missing command', async () => {
        const path = join(tmpdir(), `fixture-missing-cmd-${Date.now()}.json`)
        writeFileSync(path, JSON.stringify({ config: { testMode: true }, input: { requestId: 'x' } }))
        const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
        try {
            expect(await runFixtureFromPath(path)).toBe(1)
            expect(errorSpy).toHaveBeenCalledWith(expect.stringMatching(/command/))
        } finally {
            unlinkSync(path)
            errorSpy.mockRestore()
        }
    })

    it('documents npm test:operation script in package.json', () => {
        const pkg = JSON.parse(readFileSync(join(process.cwd(), 'package.json'), 'utf-8'))
        expect(pkg.scripts['test:operation']).toContain('run-operation-fixture')
    })
})
