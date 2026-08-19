const MS_PER_UTC_DAY = 24 * 60 * 60 * 1000

/** Floors a Date or ISO string to UTC midnight of that calendar day. */
function toUtcDayStart(value: Date | string): number {
    const date = typeof value === 'string' ? new Date(value) : value
    return Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate())
}

/**
 * Whole UTC calendar days between two timestamps (floored to UTC date).
 * Positive when `to` is after `from`. Not a rolling hour-based ceil.
 */
export function utcCalendarDaysBetween(from: Date | string, to: Date | string): number {
    return Math.floor((toUtcDayStart(to) - toUtcDayStart(from)) / MS_PER_UTC_DAY)
}

/**
 * True when `removeDate` is exactly `expirationDays` UTC calendar days after `now`
 * (default now = current time).
 */
export function matchesExpirationDays(
    removeDate: Date | string,
    expirationDays: number,
    now: Date | string = new Date()
): boolean {
    return utcCalendarDaysBetween(now, removeDate) === expirationDays
}
