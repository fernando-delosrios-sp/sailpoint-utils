import { FormDefinitionSeed } from './seed-loader'

/** Returns form definition `formInput` ids declared in a seed. */
export function declaredFormInputIds(seed: FormDefinitionSeed): string[] {
    return (seed.formInput ?? [])
        .map((input) => input.id)
        .filter((id): id is string => typeof id === 'string' && id.length > 0)
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

        if (id === 'controlOptions' && Array.isArray(value)) {
            result[id] = value.map((option) => {
                const entry = option as { label?: string; value?: string; sublabel?: string }
                const normalized: Record<string, string> = {
                    label: String(entry.label ?? ''),
                    value: String(entry.value ?? ''),
                }
                if (entry.sublabel) {
                    normalized.sublabel = entry.sublabel
                }
                return normalized
            })
            continue
        }

        result[id] = value
    }

    return result
}
