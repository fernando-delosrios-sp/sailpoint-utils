import { describe, expect, it } from 'vitest'
import { RESERVED_OUTPUT_KEYS } from './output-schema'

describe('RESERVED_OUTPUT_KEYS', () => {
    it('includes framework-managed attribute names', () => {
        expect(RESERVED_OUTPUT_KEYS.has('id')).toBe(true)
        expect(RESERVED_OUTPUT_KEYS.has('status')).toBe(true)
        expect(RESERVED_OUTPUT_KEYS.has('summary')).toBe(false)
    })
})
