import { existsSync, readFileSync } from 'fs'
import { resolve } from 'path'
import { computeFormSeedFingerprint, formatWatermarkedDescription } from './seed-watermark'

export interface FormDefinitionSeed {
    description?: string
    formInput: Array<Record<string, unknown>>
    formElements: Array<Record<string, unknown>>
    formConditions?: Array<Record<string, unknown>>
}

export interface CreateFormDefinitionPayload {
    name: string
    description?: string
    owner: { type: string; id: string }
    formInput: Array<Record<string, unknown>>
    formElements: Array<Record<string, unknown>>
    formConditions?: Array<Record<string, unknown>>
}

function validateFormSeed(seed: FormDefinitionSeed, sourceLabel: string): FormDefinitionSeed {
    if (!seed.formElements?.length) {
        throw new Error(`Form seed is missing formElements: ${sourceLabel}`)
    }
    return seed
}

/** Loads a form definition seed from disk or validates a bundled seed object. */
export function loadFormSeed(seedPath: string): FormDefinitionSeed
export function loadFormSeed(seed: FormDefinitionSeed): FormDefinitionSeed
export function loadFormSeed(seedOrPath: string | FormDefinitionSeed): FormDefinitionSeed {
    if (typeof seedOrPath !== 'string') {
        return validateFormSeed(seedOrPath, 'bundled seed')
    }

    const resolvedPath = resolve(seedOrPath)
    if (!existsSync(resolvedPath)) {
        throw new Error(`Form seed not found: ${resolvedPath}`)
    }

    const raw = readFileSync(resolvedPath, 'utf-8')
    const parsed = JSON.parse(raw) as FormDefinitionSeed
    return validateFormSeed(parsed, resolvedPath)
}

/** Builds a create-form-definition payload from a caller-supplied seed and runtime metadata. */
export function buildCreateFormDefinitionPayload(
    formName: string,
    ownerId: string,
    seed: FormDefinitionSeed,
    description?: string
): CreateFormDefinitionPayload {
    const humanDescription = description ?? seed.description
    const fingerprint = computeFormSeedFingerprint(seed)
    return {
        name: formName,
        description: formatWatermarkedDescription(fingerprint, humanDescription),
        owner: { type: 'IDENTITY', id: ownerId },
        formInput: seed.formInput ?? [],
        formElements: seed.formElements,
        formConditions: seed.formConditions,
    }
}

