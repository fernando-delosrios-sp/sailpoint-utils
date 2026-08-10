import { existsSync, readFileSync } from 'fs'
import { resolve } from 'path'

export interface FormDefinitionSeed {
    description?: string
    formInput: Array<Record<string, unknown>>
    formElements: Array<Record<string, unknown>>
    formConditions?: Array<Record<string, unknown>>
}

const SEED_FILENAME = 'sod-violation-remediation.seed.json'

function resolveSeedPath(explicitPath?: string): string {
    if (explicitPath) {
        return explicitPath
    }

    const candidates = [
        resolve(__dirname, '../assets/forms', SEED_FILENAME),
        resolve(__dirname, '../../assets/forms', SEED_FILENAME),
    ]

    for (const candidate of candidates) {
        if (existsSync(candidate)) {
            return candidate
        }
    }

    throw new Error(`SOD remediation seed not found (tried: ${candidates.join(', ')})`)
}

/** Loads the bundled SOD remediation form seed template from disk. */
export function loadSodRemediationSeed(seedPath?: string): FormDefinitionSeed {
    const resolvedPath = resolveSeedPath(seedPath)
    const raw = readFileSync(resolvedPath, 'utf-8')
    const parsed = JSON.parse(raw) as FormDefinitionSeed
    if (!parsed.formElements?.length) {
        throw new Error('SOD remediation seed is missing formElements')
    }
    return parsed
}

export interface CreateFormDefinitionPayload {
    name: string
    description?: string
    owner: { type: string; id: string }
    formInput: Array<Record<string, unknown>>
    formElements: Array<Record<string, unknown>>
    formConditions?: Array<Record<string, unknown>>
}

/** Builds a create-form-definition payload from the seed with a runtime form name. */
export function buildFormDefinitionFromSeed(formName: string, ownerId: string, seedPath?: string): CreateFormDefinitionPayload {
    const seed = loadSodRemediationSeed(seedPath)
    return {
        name: formName,
        description: seed.description ?? 'SOD violation remediation form',
        owner: { type: 'IDENTITY', id: ownerId },
        formInput: seed.formInput ?? [],
        formElements: seed.formElements,
        formConditions: seed.formConditions,
    }
}

