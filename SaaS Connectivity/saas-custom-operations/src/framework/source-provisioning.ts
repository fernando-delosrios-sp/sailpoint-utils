import { ConnectorError } from '@sailpoint/connector-sdk'
import { SourcesApi } from 'sailpoint-api-client'
import { RESERVED_OUTPUT_KEYS } from './output-schema'
import { inferSchemaAttribute, InferredSchemaAttribute, OperationField } from './schema-inference'

interface SourceOwner {
    type: string
    id: string
}

interface SourcePayload {
    id?: string
    name: string
    description?: string
    type: string
    connectorClass?: string
    connectorScriptName?: string
    provisionAsCsv?: boolean
    owner: SourceOwner
    features?: string[]
}

interface SchemaAttribute {
    name?: string
    nativeName?: string | null
    type?: string
    schema?: null
    description?: string
    isMulti?: boolean
    isEntitlement?: boolean
    isGroup?: boolean
}

interface SchemaPayload {
    id?: string
    name?: string
    nativeObjectType?: string
    identityAttribute?: string
    displayAttribute?: string
    hierarchyAttribute?: string | null
    includePermissions?: boolean
    features?: string[]
    configuration?: Record<string, unknown>
    attributes?: SchemaAttribute[]
}

interface JsonPatchOperation {
    op: string
    path: string
    value?: unknown
}

const CORE_ATTRIBUTES: InferredSchemaAttribute[] = [
    { name: 'id', type: 'STRING', isMulti: false },
    { name: 'status', type: 'STRING', isMulti: false },
    { name: 'date', type: 'STRING', isMulti: false },
]

const DEFAULT_ACCOUNT_SCHEMA: SchemaPayload = {
    name: 'account',
    nativeObjectType: 'User',
    identityAttribute: 'id',
    displayAttribute: 'id',
    hierarchyAttribute: null,
    includePermissions: false,
    features: [],
    configuration: {},
    attributes: CORE_ATTRIBUTES.map(toAttributeDefinition),
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

/** Decodes identity ID from a JWT access token payload (PAT or OAuth). */
export function resolveTokenIdentity(token: string): string {
    const parts = token.split('.')
    if (parts.length >= 2) {
        try {
            const payloadJson = Buffer.from(parts[1], 'base64url').toString('utf-8')
            const payload = JSON.parse(payloadJson) as Record<string, unknown>
            const identityId = payload.identity_id ?? payload.identityId ?? payload.sub
            if (typeof identityId === 'string' && identityId.length > 0) {
                return identityId
            }
        } catch {
            // fall through to error below
        }
    }

    throw new ConnectorError('Unable to resolve token identity for source owner')
}

async function listSourceByName(sourcesApi: SourcesApi, sourceName: string): Promise<SourcePayload | undefined> {
    const response = await sourcesApi.listSourcesV1({ filters: `name eq "${sourceName}"` })
    return response.data?.[0] as SourcePayload | undefined
}

/** Creates a DelimitedFile result source with CSV provisioning enabled. */
export async function createDelimitedFileSource(
    sourcesApi: SourcesApi,
    sourceName: string,
    ownerId: string
): Promise<string> {
    const source: SourcePayload = {
        name: sourceName,
        description: `Auto-provisioned result source for ${sourceName}`,
        type: 'DelimitedFile',
        connectorClass: 'sailpoint.connector.delimitedfile.DelimitedFileConnector',
        connectorScriptName: 'delimited-file-angularsc',
        provisionAsCsv: true,
        owner: { type: 'IDENTITY', id: ownerId },
        features: ['DIRECT_PERMISSIONS', 'DISCOVER_SCHEMA', 'NO_RANDOM_ACCESS'],
    }

    const response = await sourcesApi.createSourceV1({ source: source as never, provisionAsCsv: true })
    const sourceId = (response.data as SourcePayload | undefined)?.id
    if (!sourceId) {
        throw new ConnectorError(`Failed to create result source "${sourceName}"`)
    }

    await sourcesApi.createSourceSchemaV1({ sourceId, schema: DEFAULT_ACCOUNT_SCHEMA as never })
    return sourceId
}

/** Resolves an ISC source ID by name, creating a DelimitedFile source when missing. */
export async function resolveSourceByName(
    sourcesApi: SourcesApi,
    sourceName: string,
    token: string
): Promise<string> {
    const existing = await listSourceByName(sourcesApi, sourceName)
    if (existing?.id) {
        return existing.id
    }

    try {
        const ownerId = resolveTokenIdentity(token)
        return await createDelimitedFileSource(sourcesApi, sourceName, ownerId)
    } catch (error) {
        const retried = await listSourceByName(sourcesApi, sourceName)
        if (retried?.id) {
            return retried.id
        }
        throw error
    }
}

async function getAccountSchema(sourcesApi: SourcesApi, sourceId: string): Promise<SchemaPayload | undefined> {
    const response = await sourcesApi.getSourceSchemasV1({ sourceId, includeNames: 'account' })
    const schemas = response.data as SchemaPayload[] | undefined
    return schemas?.find((schema) => schema.name === 'account') ?? schemas?.[0]
}

function collectRequiredAttributes(
    outputFields: OperationField[],
    attributeKeys: string[]
): Map<string, InferredSchemaAttribute> {
    const required = new Map<string, InferredSchemaAttribute>()

    for (const core of CORE_ATTRIBUTES) {
        required.set(core.name, core)
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
        const created = await sourcesApi.createSourceSchemaV1({ sourceId, schema: DEFAULT_ACCOUNT_SCHEMA as never })
        schema = created.data as SchemaPayload
    }

    if (!schema?.id) {
        throw new ConnectorError(`Unable to load account schema for source ${sourceId}`)
    }

    const existingAttrs = schema.attributes ?? []
    const existingByName = new Map(existingAttrs.map((attr: SchemaAttribute) => [attr.name ?? '', attr]))
    const required = collectRequiredAttributes(outputFields, attributeKeys)
    const patches: JsonPatchOperation[] = []

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

    if (patches.length > 0) {
        await sourcesApi.updateSourceSchemaV1({
            sourceId,
            schemaId: schema.id,
            jsonPatchOperation: patches as never,
        })
    }
}
