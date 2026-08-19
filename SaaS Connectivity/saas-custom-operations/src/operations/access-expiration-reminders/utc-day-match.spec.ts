import { describe, expect, it } from 'vitest'
import { matchesExpirationDays, utcCalendarDaysBetween } from './utc-day-match'

describe('utcCalendarDaysBetween', () => {
    it('counts whole UTC calendar days between floored dates', () => {
        expect(utcCalendarDaysBetween('2026-08-19T23:59:59.000Z', '2026-08-20T00:00:01.000Z')).toBe(1)
        expect(utcCalendarDaysBetween('2026-08-19T12:00:00.000Z', '2026-08-21T12:00:00.000Z')).toBe(2)
    })

    it('returns 0 for the same UTC calendar day regardless of clock time', () => {
        expect(utcCalendarDaysBetween('2026-08-19T01:00:00.000Z', '2026-08-19T23:00:00.000Z')).toBe(0)
    })
})

describe('matchesExpirationDays', () => {
    const now = new Date('2026-08-19T12:00:00.000Z')

    it('matches when removeDate is exactly expirationDays UTC calendar days ahead', () => {
        expect(matchesExpirationDays('2026-08-20T22:00:00.000Z', 1, now)).toBe(true)
        expect(matchesExpirationDays('2026-08-21T00:00:00.000Z', 2, now)).toBe(true)
    })

    it('excludes non-matching day offsets', () => {
        expect(matchesExpirationDays('2026-08-21T12:00:00.000Z', 1, now)).toBe(false)
        expect(matchesExpirationDays('2026-08-19T18:00:00.000Z', 1, now)).toBe(false)
    })

    it('does not use rolling hour-based Math.ceil day math', () => {
        // ~25 hours ahead within the same next UTC calendar day → still exactly 1 day
        expect(matchesExpirationDays('2026-08-20T13:00:00.000Z', 1, now)).toBe(true)
        // Same instant-distance style would differ with ceil hours; calendar floor stays exact
        expect(matchesExpirationDays('2026-08-20T11:00:00.000Z', 1, '2026-08-19T12:00:00.000Z')).toBe(true)
    })
})
