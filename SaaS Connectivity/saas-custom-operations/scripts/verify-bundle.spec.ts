import { describe, expect, it } from 'vitest'
import { verifyBundle } from './verify-bundle'

describe('verify-bundle', () => {
    it('dist/index.js registers every connector-spec command', async () => {
        await expect(verifyBundle()).resolves.toBeUndefined()
    })
})
