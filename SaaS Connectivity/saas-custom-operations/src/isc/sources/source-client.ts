import { ConnectorError } from '@sailpoint/connector-sdk'
import { SourcesApi } from 'sailpoint-api-client'

export interface SourceOwner {
    type: string
    id: string
}

export interface SourcePayload {
    id?: string
    name: string
    description?: string
    type: string
    connector?: string
    connectorClass?: string
    connectorScriptName?: string
    provisionAsCsv?: boolean
    owner: SourceOwner
    features?: string[]
}

export interface SchemaAttribute {
    name?: string
    nativeName?: string | null
    type?: string
    schema?: null
    description?: string
    isMulti?: boolean
    isEntitlement?: boolean
    isGroup?: boolean
}

export interface SchemaPayload {
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

export interface JsonPatchOperation {
    op: string
    path: string
    value?: unknown
}

/** True when an HTTP client error indicates the resource was not found. */
export function isHttpNotFound(error: unknown): boolean {
    if (typeof error !== 'object' || error === null) {
        return false
    }

    const candidate = error as { status?: number; response?: { status?: number } }
    return candidate.status === 404 || candidate.response?.status === 404
}

/** Lists sources matching a name filter. */
export async function findSourceByName(sourcesApi: SourcesApi, sourceName: string): Promise<SourcePayload | undefined> {
    const response = await sourcesApi.listSourcesV1({ filters: `name eq "${sourceName}"` })
    return response.data?.[0] as SourcePayload | undefined
}

/** Creates a source from a caller-supplied payload. */
export async function createSource(
    sourcesApi: SourcesApi,
    source: SourcePayload,
    options?: { provisionAsCsv?: boolean }
): Promise<string> {
    const response = await sourcesApi.createSourceV1({
        source: source as never,
        provisionAsCsv: options?.provisionAsCsv,
    })
    const sourceId = (response.data as SourcePayload | undefined)?.id
    if (!sourceId) {
        throw new ConnectorError(`Failed to create source "${source.name}"`)
    }
    return sourceId
}

/** Read-only ISC connectivity check (list sources with minimal page size). */
export async function verifyIscStatus(sourcesApi: SourcesApi): Promise<void> {
    await sourcesApi.listSourcesV1({ limit: 1 })
}

/** Returns account schemas for a source. */
export async function getAccountSchemas(
    sourcesApi: SourcesApi,
    sourceId: string,
    includeNames = 'account'
): Promise<SchemaPayload[]> {
    try {
        const response = await sourcesApi.getSourceSchemasV1({ sourceId, includeNames })
        return (response.data as SchemaPayload[] | undefined) ?? []
    } catch (error) {
        if (isHttpNotFound(error)) {
            return []
        }
        throw error
    }
}

/** Returns the account schema for a source when present. */
export async function getAccountSchema(sourcesApi: SourcesApi, sourceId: string): Promise<SchemaPayload | undefined> {
    const schemas = await getAccountSchemas(sourcesApi, sourceId)
    return schemas.find((entry) => entry.name === 'account') ?? schemas[0]
}

/** Creates an account schema on a source from a caller-supplied payload. */
export async function createAccountSchema(
    sourcesApi: SourcesApi,
    sourceId: string,
    schema: SchemaPayload
): Promise<SchemaPayload> {
    const response = await sourcesApi.createSourceSchemaV1({ sourceId, schema: schema as never })
    const created = response.data as SchemaPayload | undefined
    if (!created?.id) {
        throw new ConnectorError(`Failed to create account schema for source ${sourceId}`)
    }
    return created
}

/** Applies JSON Patch operations to a source account schema. */
export async function patchAccountSchema(
    sourcesApi: SourcesApi,
    sourceId: string,
    schemaId: string,
    patches: JsonPatchOperation[]
): Promise<void> {
    if (patches.length === 0) {
        return
    }

    await sourcesApi.updateSourceSchemaV1({
        sourceId,
        schemaId,
        jsonPatchOperation: patches as never,
    })
}
