import { ConnectorError } from '@sailpoint/connector-sdk'
import { SourcesApi } from 'sailpoint-api-client'
import {
    createAccountSchema,
    createSource,
    findSourceByName,
    getAccountSchema,
    isHttpNotFound,
    patchAccountSchema,
    SchemaAttribute,
    SchemaPayload,
    SourcePayload,
} from '../isc/sources'
import { resolveTokenIdentity } from '../isc/token-identity'
import {
    BASE_CORE_ATTRIBUTES,
    baseSchemaAttributeDefinition,
    buildBaseAccountSchema,
    collectBaseSchemaAttributes,
} from './base-account-schema'
import { listRegisteredOperationSchemas } from './operation-schema-registry'
import { RESERVED_OUTPUT_KEYS } from './output-schema'
import {
    IscAttributeType,
    inferSchemaAttribute,
    InferredSchemaAttribute,
    OperationField,
} from './schema-inference'

const RESULT_SOURCE_TYPE = 'DelimitedFile'

export const DEFAULT_RESULT_ACCOUNT_SCHEMA: SchemaPayload = buildBaseAccountSchema([])

function assertDelimitedFileResultSource(source: SourcePayload, sourceName: string): void {
    if (source.type !== RESULT_SOURCE_TYPE) {
        throw new ConnectorError(
            `Result source "${sourceName}" is type "${source.type}", not ${RESULT_SOURCE_TYPE}. ` +
                `Persist requires a DelimitedFile result store. Use a sourceName that does not match your connector source (for example "${sourceName} Results").`
        )
    }
}

/** Resolves an ISC source ID by name without auto-provisioning (test mode). */
export async function resolveSourceByNameReadOnly(
    sourcesApi: SourcesApi,
    sourceName: string
): Promise<string | undefined> {
    const existing = await findSourceByName(sourcesApi, sourceName)
    if (existing?.id) {
        assertDelimitedFileResultSource(existing, sourceName)
        return existing.id
    }
    return undefined
}

function registeredOutputFields(): OperationField[] {
    return listRegisteredOperationSchemas().flatMap((schema) => schema.outputFields)
}

function buildSchemaAttributePatches(
    schema: SchemaPayload,
    required: Map<string, InferredSchemaAttribute>
): Array<{ op: string; path: string; value?: unknown }> {
    const existingAttrs = schema.attributes ?? []
    const existingByName = new Map(existingAttrs.map((attr: SchemaAttribute) => [attr.name ?? '', attr]))
    const patches: Array<{ op: string; path: string; value?: unknown }> = []

    if (schema.identityAttribute !== 'id') {
        patches.push({ op: 'replace', path: '/identityAttribute', value: 'id' })
    }
    if (schema.displayAttribute !== 'id') {
        patches.push({ op: 'replace', path: '/displayAttribute', value: 'id' })
    }
    if (schema.nativeObjectType !== 'User') {
        patches.push({ op: 'replace', path: '/nativeObjectType', value: 'User' })
    }
    if (schema.name !== 'account') {
        patches.push({ op: 'replace', path: '/name', value: 'account' })
    }

    for (const [name, inferred] of required) {
        const existing = existingByName.get(name)
        if (!existing) {
            patches.push({
                op: 'add',
                path: '/attributes/-',
                value: baseSchemaAttributeDefinition(inferred),
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

    return patches
}

/** Applies the base account schema (union of registered operation outputs) on a newly created result source. */
export async function applyBaseAccountSchema(sourcesApi: SourcesApi, sourceId: string): Promise<void> {
    const baseSchema = buildBaseAccountSchema(registeredOutputFields())
    let schema = await getAccountSchema(sourcesApi, sourceId)

    if (!schema?.id) {
        await createAccountSchema(sourcesApi, sourceId, baseSchema)
        return
    }

    const required = collectBaseSchemaAttributes(registeredOutputFields())
    const patches = buildSchemaAttributePatches(schema, required)
    await patchAccountSchema(sourcesApi, sourceId, schema.id, patches)
}

/** Creates a DelimitedFile result source with CSV provisioning and the base account schema. */
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

    await applyBaseAccountSchema(sourcesApi, sourceId)
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
        assertDelimitedFileResultSource(existing, sourceName)
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

function collectRequiredAttributes(
    outputFields: OperationField[],
    attributeKeys: string[]
): Map<string, InferredSchemaAttribute> {
    const required = new Map<string, InferredSchemaAttribute>()

    for (const core of BASE_CORE_ATTRIBUTES) {
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
        try {
            schema = await createAccountSchema(sourcesApi, sourceId, DEFAULT_RESULT_ACCOUNT_SCHEMA)
        } catch (error) {
            if (isHttpNotFound(error)) {
                console.warn(
                    `[schema] account schema unavailable for source ${sourceId} (404 on create) — skipping reconciliation`
                )
                return
            }
            throw error
        }
    }

    const required = collectRequiredAttributes(outputFields, attributeKeys)
    const patches = buildSchemaAttributePatches(schema, required)

    try {
        await patchAccountSchema(sourcesApi, sourceId, schema.id!, patches)
    } catch (error) {
        if (isHttpNotFound(error)) {
            console.warn(
                `[schema] account schema patch unavailable for source ${sourceId} (404) — continuing persist`
            )
            return
        }
        throw error
    }
}
