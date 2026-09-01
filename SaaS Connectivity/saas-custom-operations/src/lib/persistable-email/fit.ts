import { ISC_STRING_ATTRIBUTE_MAX_LENGTH } from '../../framework/attribute-limits'
import { truncateWithEllipsis } from './truncate'

export type PersistableSlotValues = Record<string, string>
export type PersistableSuffixValues = Record<string, string>

export interface FitPersistableHtmlOptions {
    /** Pre-escaped variable name slots shortened proportionally when over budget. */
    slots: PersistableSlotValues
    /**
     * Assembles the full HTML from current slot values and included optional suffixes.
     * Suffix keys present in `suffixes` are included; omitted keys were dropped for budget.
     */
    render: (slots: PersistableSlotValues, suffixes: PersistableSuffixValues) => string
    /** Optional suffix segments tried first, then dropped when over budget. */
    optionalSuffixes?: PersistableSuffixValues
    maxLength?: number
}

function emptySlots(slots: PersistableSlotValues): PersistableSlotValues {
    const empty: PersistableSlotValues = {}
    for (const key of Object.keys(slots)) {
        empty[key] = ''
    }
    return empty
}

function shortenSlotsProportionally(
    slots: PersistableSlotValues,
    nameBudget: number
): PersistableSlotValues {
    const keys = Object.keys(slots)
    if (keys.length === 0 || nameBudget <= 0) {
        return { ...slots }
    }

    const combinedLength = keys.reduce((sum, key) => sum + slots[key].length, 0)
    if (combinedLength === 0) {
        return { ...slots }
    }

    const shortened: PersistableSlotValues = {}
    let remaining = nameBudget

    keys.forEach((key, index) => {
        const isLast = index === keys.length - 1
        const budget = isLast
            ? Math.max(1, remaining)
            : Math.max(1, Math.floor(nameBudget * (slots[key].length / combinedLength)))
        shortened[key] = truncateWithEllipsis(slots[key], budget)
        remaining -= budget
    })

    return shortened
}

/**
 * Fits a persistable email HTML body into `maxLength` by dropping optional suffixes,
 * then proportionally truncating pre-escaped name slots, then hard-slicing as last resort.
 */
export function fitPersistableHtml(options: FitPersistableHtmlOptions): string {
    const {
        slots,
        render,
        optionalSuffixes = {},
        maxLength = ISC_STRING_ATTRIBUTE_MAX_LENGTH,
    } = options

    const suffixEntries = Object.entries(optionalSuffixes)
    const trySuffixSets: PersistableSuffixValues[] = []

    // Full set first, then drop suffixes from the end one-by-one, then none.
    for (let keep = suffixEntries.length; keep >= 0; keep -= 1) {
        const included: PersistableSuffixValues = {}
        for (let i = 0; i < keep; i += 1) {
            const [key, value] = suffixEntries[i]
            included[key] = value
        }
        trySuffixSets.push(included)
    }

    for (const suffixes of trySuffixSets) {
        const candidate = render(slots, suffixes)
        if (candidate.length <= maxLength) {
            return candidate
        }
    }

    const noSuffixes: PersistableSuffixValues = {}
    const overhead = render(emptySlots(slots), noSuffixes).length
    const nameBudget = maxLength - overhead

    let fittedSlots = slots
    if (nameBudget > 2) {
        fittedSlots = shortenSlotsProportionally(slots, nameBudget)
    }

    const truncated = render(fittedSlots, noSuffixes)
    return truncated.length <= maxLength ? truncated : truncated.slice(0, maxLength)
}
