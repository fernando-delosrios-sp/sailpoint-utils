import { SourcesApi } from 'sailpoint-api-client'
import {
    createAccountSchema,
    createSource,
    findSourceByName,
    getAccountSchema,
    patchAccountSchema,
    SchemaAttribute,
    SchemaPayload,
} from '../isc/sources'
import { resolveTokenIdentity } from '../isc/token-identity'
import { RESERVED_OUTPUT_KEYS } from './output-schema'
import {
    IscAttributeType,
    inferSchemaAttribute,
    InferredSchemaAttribute,
    OperationField,
} from './schema-inference'

const CORE_ATTRIBUTES: SchemaAttribute[] = [
    { name: 'id', type: 'STRING', isMulti: false },
    { name: 'status', type: 'STRING', isMulti: false },
    { name: 'date', type: 'STRING', isMulti: false },
]

export const DEFAULT_RESULT_ACCOUNT_SCHEMA: SchemaPayload = {
    name: 'account',
    nativeObjectType: 'User',
    identityAttribute: 'id',
    displayAttribute: 'id',
    hierarchyAttribute: null,
    includePermissions: false,
    features: [],
    configuration: {},
    attributes: CORE_ATTRIBUTES.map((attr) => ({ ...attr, nativeName: null, schema: null })),
}

/** Resolves an ISC source ID by name without auto-provisioning (test mode). */
export async function resolveSourceByNameReadOnly(
    sourcesApi: SourcesApi,
    sourceName: string
): Promise<string | undefined> {
    const existing = await findSourceByName(sourcesApi, sourceName)
    return existing?.id
}

/** Creates a DelimitedFile result source with CSV provisioning and default account schema. */
export async function createDelimitedFileResultSource(
    sourcesApi: SourcesApi,
    sourceName: string,
    ownerId: string
): Promise<string> {
    const sourceId = await createSource(
        sourcesApi,
        {
            name: sourceName,
            description: `Auto-provisioned result source for ${sourceName}`,
            type: 'DelimitedFile',
            connector: 'delimited-file-angularsc',
            connectorClass: 'sailpoint.connector.delimitedfile.DelimitedFileConnector',
            connectorScriptName: 'delimited-file-angularsc',
            provisionAsCsv: true,
            owner: { type: 'IDENTITY', id: ownerId },
            features: ['DIRECT_PERMISSIONS', 'DISCOVER_SCHEMA', 'NO_RANDOM_ACCESS'],
        },
        { provisionAsCsv: true }
    )

    await createAccountSchema(sourcesApi, sourceId, DEFAULT_RESULT_ACCOUNT_SCHEMA)
    return sourceId
}

/** Resolves an ISC source ID by name, auto-provisioning a DelimitedFile result source when missing. */
export async function resolveSourceByName(
    sourcesApi: SourcesApi,
    sourceName: string,
    token: string
): Promise<string> {
    const existing = await findSourceByName(sourcesApi, sourceName)
    if (existing?.id) {
        return existing.id
    }

    try {
        const ownerId = resolveTokenIdentity(token)
        return await createDelimitedFileResultSource(sourcesApi, sourceName, ownerId)
    } catch (error) {
        const retried = await findSourceByName(sourcesApi, sourceName)
        if (retried?.id) {
            return retried.id
        }
        throw error
    }
}

function toAttributeDefinition(attr: InferredSchemaAttribute): SchemaAttribute {
    return {
        name: attr.name,
        nativeName: null,
        type: attr.type,
        schema: null,
        description: attr.name === 'id' ? 'The unique ID for the account' : undefined,
        isMulti: attr.isMulti,
        isEntitlement: false,
        isGroup: false,
    }
}

function collectRequiredAttributes(
    outputFields: OperationField[],
    attributeKeys: string[]
): Map<string, InferredSchemaAttribute> {
    const required = new Map<string, InferredSchemaAttribute>()

    for (const core of CORE_ATTRIBUTES) {
        required.set(core.name!, {
            name: core.name!,
            type: core.type! as IscAttributeType,
            isMulti: core.isMulti ?? false,
        })
    }

    for (const field of outputFields) {
        if (RESERVED_OUTPUT_KEYS.has(field.name)) {
            continue
        }
        required.set(field.name, inferSchemaAttribute(field))
    }

    for (const key of attributeKeys) {
        if (RESERVED_OUTPUT_KEYS.has(key) || required.has(key)) {
            continue
        }
        required.set(key, { name: key, type: 'STRING', isMulti: false })
    }

    return required
}

/**
 * Reconciles the result source account schema before persist.
 * Adds missing attributes, warns on type conflicts, and patches isMulti to true when needed.
 */
export async function ensureSourceSchema(
    sourcesApi: SourcesApi,
    sourceId: string,
    outputFields: OperationField[],
    attributeKeys: string[]
): Promise<void> {
    let schema = await getAccountSchema(sourcesApi, sourceId)
    if (!schema?.id) {
        schema = await createAccountSchema(sourcesApi, sourceId, DEFAULT_RESULT_ACCOUNT_SCHEMA)
    }

    const existingAttrs = schema.attributes ?? []
    const existingByName = new Map(existingAttrs.map((attr: SchemaAttribute) => [attr.name ?? '', attr]))
    const required = collectRequiredAttributes(outputFields, attributeKeys)
    const patches: Array<{ op: string; path: string; value?: unknown }> = []

    for (const [name, inferred] of required) {
        const existing = existingByName.get(name)
        if (!existing) {
            patches.push({
                op: 'add',
                path: '/attributes/-',
                value: toAttributeDefinition(inferred),
            })
            continue
        }

        if (existing.type && existing.type !== inferred.type) {
            console.warn(
                `[schema] Type conflict for ${name}: existing ${existing.type}, inferred ${inferred.type} — keeping existing`
            )
            continue
        }

        if (existing.isMulti === false && inferred.isMulti) {
            const index = existingAttrs.findIndex((attr: SchemaAttribute) => attr.name === name)
            if (index >= 0) {
                console.warn(`[schema] isMulti conflict for ${name}: patching to true`)
                patches.push({ op: 'replace', path: `/attributes/${index}/isMulti`, value: true })
            }
        }
    }

    await patchAccountSchema(sourcesApi, sourceId, schema.id!, patches)
}

