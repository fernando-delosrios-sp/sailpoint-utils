import { afterEach, describe, expect, it, vi } from 'vitest'
import {
    ISC_IDENTITY_MAX_LENGTH,
    ISC_STRING_ATTRIBUTE_MAX_LENGTH,
    truncateForIscStorage,
} from './attribute-limits'

describe('truncateForIscStorage', () => {
    afterEach(() => {
        vi.restoreAllMocks()
    })

    it('returns value unchanged when within limit', () => {
        const value = 'a'.repeat(ISC_STRING_ATTRIBUTE_MAX_LENGTH)
        expect(truncateForIscStorage(value, ISC_STRING_ATTRIBUTE_MAX_LENGTH, 'summary')).toBe(value)
    })

    it('truncates STRING values at 256 characters with warning', () => {
        const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
        const value = 'x'.repeat(ISC_STRING_ATTRIBUTE_MAX_LENGTH + 10)

        const result = truncateForIscStorage(value, ISC_STRING_ATTRIBUTE_MAX_LENGTH, 'summary')

        expect(result).toHaveLength(ISC_STRING_ATTRIBUTE_MAX_LENGTH)
        expect(result).toBe(value.slice(0, ISC_STRING_ATTRIBUTE_MAX_LENGTH))
        expect(warn).toHaveBeenCalledWith(
            expect.stringContaining(`[persist] truncated summary from ${value.length} to ${ISC_STRING_ATTRIBUTE_MAX_LENGTH} chars`)
        )
    })

    it('truncates identity at 128 characters with warning', () => {
        const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
        const value = 'i'.repeat(ISC_IDENTITY_MAX_LENGTH + 5)

        const result = truncateForIscStorage(value, ISC_IDENTITY_MAX_LENGTH, 'identity')

        expect(result).toHaveLength(ISC_IDENTITY_MAX_LENGTH)
        expect(result).toBe(value.slice(0, ISC_IDENTITY_MAX_LENGTH))
        expect(warn).toHaveBeenCalledWith(
            expect.stringContaining(`[persist] truncated identity from ${value.length} to ${ISC_IDENTITY_MAX_LENGTH} chars`)
        )
    })

    it('uses generic context label when context omitted', () => {
        const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
        const value = 'z'.repeat(300)

        truncateForIscStorage(value, ISC_STRING_ATTRIBUTE_MAX_LENGTH)

        expect(warn).toHaveBeenCalledWith(
            expect.stringContaining(`[persist] truncated value from ${value.length} to ${ISC_STRING_ATTRIBUTE_MAX_LENGTH} chars`)
        )
    })
})
