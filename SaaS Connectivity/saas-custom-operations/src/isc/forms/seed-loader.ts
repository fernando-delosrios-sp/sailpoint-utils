import { existsSync, readFileSync } from 'fs'
import { resolve } from 'path'

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

/** Loads a form definition seed template JSON file from disk. */
export function loadFormSeed(seedPath: string): FormDefinitionSeed {
    const resolvedPath = resolve(seedPath)
    if (!existsSync(resolvedPath)) {
        throw new Error(`Form seed not found: ${resolvedPath}`)
    }

    const raw = readFileSync(resolvedPath, 'utf-8')
    const parsed = JSON.parse(raw) as FormDefinitionSeed
    if (!parsed.formElements?.length) {
        throw new Error(`Form seed is missing formElements: ${resolvedPath}`)
    }
    return parsed
}

/** Builds a create-form-definition payload from a caller-supplied seed and runtime metadata. */
export function buildCreateFormDefinitionPayload(
    formName: string,
    ownerId: string,
    seed: FormDefinitionSeed,
    description?: string
): CreateFormDefinitionPayload {
    return {
        name: formName,
        description: description ?? seed.description ?? formName,
        owner: { type: 'IDENTITY', id: ownerId },
        formInput: seed.formInput ?? [],
        formElements: seed.formElements,
        formConditions: seed.formConditions,
    }
}
