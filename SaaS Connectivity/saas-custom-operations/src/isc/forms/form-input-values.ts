import { FormDefinitionSeed } from './seed-loader'

/** Returns form definition `formInput` ids declared in a seed. */
export function declaredFormInputIds(seed: FormDefinitionSeed): string[] {
    return (seed.formInput ?? [])
        .map((input) => input.id)
        .filter((id): id is string => typeof id === 'string' && id.length > 0)
}

function declaredFormInputType(seed: FormDefinitionSeed, id: string): string | undefined {
    const entry = (seed.formInput ?? []).find((input) => input.id === id)
    return typeof entry?.type === 'string' ? entry.type : undefined
}

/**
 * ISC ARRAY formInput values must be objects (FormInstanceInputArrayElement), not raw strings.
 * Select-style arrays use label/value/sublabel; plain id lists use label=value for each entry.
 */
export function normalizeArrayFormInputElements(value: unknown): unknown {
    if (!Array.isArray(value)) {
        return value
    }

    return value.map((item) => {
        if (typeof item === 'string') {
            return { label: item, value: item }
        }

        if (item && typeof item === 'object') {
            const entry = item as { label?: string; value?: string; sublabel?: string }
            const normalized: Record<string, string> = {
                label: String(entry.label ?? entry.value ?? ''),
                value: String(entry.value ?? entry.label ?? ''),
            }
            if (entry.sublabel) {
                normalized.sublabel = entry.sublabel
            }
            return normalized
        }

        return item
    })
}

/**
 * Keeps only values for ids declared on the form definition seed.
 * ISC rejects or corrupts instances when create-time `formInput` includes undeclared keys.
 */
export function pickDeclaredFormInputValues(
    seed: FormDefinitionSeed,
    values: Record<string, unknown>
): Record<string, unknown> {
    const result: Record<string, unknown> = {}

    for (const id of declaredFormInputIds(seed)) {
        if (!(id in values)) {
            continue
        }

        const value = values[id]
        if (value === undefined || value === null) {
            continue
        }

        if (declaredFormInputType(seed, id) === 'ARRAY' && Array.isArray(value)) {
            result[id] = normalizeArrayFormInputElements(value)
            continue
        }

        result[id] = value
    }

    return result
}
