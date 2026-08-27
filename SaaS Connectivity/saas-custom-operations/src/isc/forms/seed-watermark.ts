import { createHash } from 'crypto'
import { FormDefinitionSeed } from './seed-loader'

export const FORM_SEED_WATERMARK_PREFIX = '@form-seed-sha256:'

/** Canonical JSON with sorted object keys for stable fingerprinting. */
export function canonicalJson(value: unknown): string {
    if (value === null || typeof value !== 'object') {
        return JSON.stringify(value)
    }
    if (Array.isArray(value)) {
        return `[${value.map((entry) => canonicalJson(entry)).join(',')}]`
    }
    const record = value as Record<string, unknown>
    const keys = Object.keys(record).sort()
    return `{${keys.map((key) => `${JSON.stringify(key)}:${canonicalJson(record[key])}`).join(',')}}`
}

export interface FormDefinitionStructuralFields {
    formInput?: Array<Record<string, unknown>>
    formElements: Array<Record<string, unknown>>
    formConditions?: Array<Record<string, unknown>>
}

/** SHA-256 fingerprint of seed structural fields (excludes human description). */
export function computeFormSeedFingerprint(seed: FormDefinitionStructuralFields): string {
    const structural = {
        formInput: seed.formInput ?? [],
        formElements: seed.formElements,
        formConditions: seed.formConditions ?? [],
    }
    return createHash('sha256').update(canonicalJson(structural), 'utf8').digest('hex')
}

/** First-line watermark plus optional human-readable description text. */
export function formatWatermarkedDescription(fingerprint: string, humanDescription?: string): string {
    const watermarkLine = `${FORM_SEED_WATERMARK_PREFIX}${fingerprint}`
    const trimmed = humanDescription?.trim()
    if (!trimmed) {
        return watermarkLine
    }
    return `${watermarkLine}\n${trimmed}`
}

/** Parses `@form-seed-sha256:<hex>` from the first line of a form definition description. */
export function parseFormSeedWatermark(description: string | undefined): string | undefined {
    if (!description) {
        return undefined
    }
    const firstLine = description.split('\n')[0]?.trim() ?? ''
    const match = firstLine.match(/^@form-seed-sha256:([a-f0-9]{64})$/)
    return match?.[1]
}
