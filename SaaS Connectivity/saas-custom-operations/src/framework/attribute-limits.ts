import { getActiveFrameworkLogger } from './logger'

/** ISC maximum length for account identity / nativeIdentity values (aggregation limit). */
export const ISC_IDENTITY_MAX_LENGTH = 128

/** ISC maximum length for declared STRING text field values on account schema attributes. */
export const ISC_STRING_ATTRIBUTE_MAX_LENGTH = 256

/**
 * Truncates a string to ISC storage limits when needed.
 * Logs `[persist] truncated <context> from N to M chars` when truncation occurs.
 */
export function truncateForIscStorage(value: string, maxLength: number, context?: string): string {
    if (value.length <= maxLength) {
        return value
    }

    const contextLabel = context ?? 'value'
    getActiveFrameworkLogger().warn(`[persist] truncated ${contextLabel} from ${value.length} to ${maxLength} chars`)
    return value.slice(0, maxLength)
}
