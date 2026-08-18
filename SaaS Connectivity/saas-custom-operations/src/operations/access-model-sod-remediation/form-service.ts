import {
    buildCreateFormDefinitionPayload,
    createStandaloneFormInstance,
    ensureFormDefinitionByName,
    FormsApiLike,
    loadFormSeed,
    pickDeclaredFormInputValues,
} from '../../isc/forms'
import { logIscDebug, logIscRequestFailure } from '../../isc/debug/log-isc-request'
import accessModelSodRemediationSeedJson from './seed/access-model-sod-remediation.seed.json'

export interface AccessModelSodFormInputValues {
    parentRequestId: string
    accessItemId: string
    accessItemType: string
    accessItemTypeTagHtml: string
    accessItemName: string
    policyId: string
    policyName: string
    groupAIds: string[]
    groupBIds: string[]
    groupColumnsHtmlPlain: string
    groupColumnsHtmlWhenGroupARemoved: string
    groupColumnsHtmlWhenGroupBRemoved: string
}

export interface CreateAccessModelSodInstanceParams {
    forms: FormsApiLike
    formDefinitionId: string
    recipientId: string
    createdBySourceId: string
    formInput: AccessModelSodFormInputValues
}

const accessModelSodRemediationSeed = loadFormSeed(accessModelSodRemediationSeedJson)

/** Ensures the access model SoD remediation form definition exists for the tenant. */
export async function ensureAccessModelSodFormDefinition(
    forms: FormsApiLike,
    formName: string,
    ownerId: string
): Promise<string> {
    const template = buildCreateFormDefinitionPayload(
        formName,
        ownerId,
        accessModelSodRemediationSeed,
        accessModelSodRemediationSeed.description
    )
    return ensureFormDefinitionByName(forms, { name: formName, ownerId, template })
}

export interface AssignedRemediationInstanceCache {
    formDefinitionId: string
    assignedPairs: Set<string>
    loadPromise?: Promise<void>
}

function assignedRemediationPairKey(parentRequestId: string, accessItemId: string, policyId: string): string {
    return `${parentRequestId}:${accessItemId}:${policyId}`
}

function matchesAssignedRemediationInstance(
    input: Record<string, unknown> | undefined,
    parentRequestId: string,
    accessItemId: string,
    policyId: string
): boolean {
    return (
        input?.parentRequestId === parentRequestId &&
        input?.accessItemId === accessItemId &&
        input?.policyId === policyId
    )
}

/** Creates an empty scan-scoped cache for assigned remediation form instances. */
export function createAssignedRemediationInstanceCache(formDefinitionId: string): AssignedRemediationInstanceCache {
    return {
        formDefinitionId,
        assignedPairs: new Set(),
    }
}

async function populateAssignedRemediationInstanceCache(
    forms: FormsApiLike,
    cache: AssignedRemediationInstanceCache
): Promise<void> {
    const filters = `formDefinitionId eq "${cache.formDefinitionId}"`
    logIscDebug('loadAssignedRemediationInstances searchFormInstancesByTenantV1 request', {
        filters,
    })

    try {
        const response = await forms.searchFormInstancesByTenantV1({
            filters,
            limit: 250,
        })

        const instances = response.data ?? []
        const assigned = instances.filter((instance) => instance.state === 'ASSIGNED')
        logIscDebug('loadAssignedRemediationInstances response', {
            totalInstances: instances.length,
            assignedInstances: assigned.length,
        })

        for (const instance of assigned) {
            const input = instance.formInput as Record<string, unknown> | undefined
            const parentRequestId = input?.parentRequestId
            const accessItemId = input?.accessItemId
            const policyId = input?.policyId
            if (
                typeof parentRequestId === 'string' &&
                typeof accessItemId === 'string' &&
                typeof policyId === 'string'
            ) {
                cache.assignedPairs.add(assignedRemediationPairKey(parentRequestId, accessItemId, policyId))
            }
        }
    } catch (error) {
        logIscRequestFailure('loadAssignedRemediationInstances searchFormInstancesByTenantV1', error)
        throw error
    }
}

async function ensureAssignedRemediationInstanceCacheLoaded(
    forms: FormsApiLike,
    cache: AssignedRemediationInstanceCache
): Promise<void> {
    if (!cache.loadPromise) {
        cache.loadPromise = populateAssignedRemediationInstanceCache(forms, cache)
    }
    await cache.loadPromise
}

/** Loads assigned remediation instances once for reuse during a scan. */
export async function loadAssignedRemediationInstances(
    forms: FormsApiLike,
    formDefinitionId: string
): Promise<AssignedRemediationInstanceCache> {
    const cache = createAssignedRemediationInstanceCache(formDefinitionId)
    await ensureAssignedRemediationInstanceCacheLoaded(forms, cache)
    return cache
}

/** Returns true when an ASSIGNED instance already exists for the same parent request, access item, and policy. */
export async function hasAssignedRemediationInstance(
    forms: FormsApiLike,
    formDefinitionId: string,
    parentRequestId: string,
    accessItemId: string,
    policyId: string,
    cache?: AssignedRemediationInstanceCache
): Promise<boolean> {
    if (cache) {
        await ensureAssignedRemediationInstanceCacheLoaded(forms, cache)
        return cache.assignedPairs.has(assignedRemediationPairKey(parentRequestId, accessItemId, policyId))
    }

    const filters = `formDefinitionId eq "${formDefinitionId}"`
    logIscDebug('hasAssignedRemediationInstance searchFormInstancesByTenantV1 request', {
        filters,
        parentRequestId,
        accessItemId,
        policyId,
    })

    try {
        const response = await forms.searchFormInstancesByTenantV1({
            filters,
            limit: 250,
        })

        const instances = response.data ?? []
        const assigned = instances.filter((instance) => instance.state === 'ASSIGNED')
        logIscDebug('hasAssignedRemediationInstance response', {
            totalInstances: instances.length,
            assignedInstances: assigned.length,
        })

        return assigned.some((instance) =>
            matchesAssignedRemediationInstance(
                instance.formInput as Record<string, unknown> | undefined,
                parentRequestId,
                accessItemId,
                policyId
            )
        )
    } catch (error) {
        logIscRequestFailure('hasAssignedRemediationInstance searchFormInstancesByTenantV1', error)
        throw error
    }
}

/** Serializes entitlement id lists to JSON strings for ISC STRING formInput fields. */
export function serializeAccessModelSodFormInputForCreate(formInput: AccessModelSodFormInputValues): Record<string, unknown> {
    return {
        ...formInput,
        groupAIds: JSON.stringify(formInput.groupAIds),
        groupBIds: JSON.stringify(formInput.groupBIds),
    }
}

/** Creates a standalone access model SoD remediation form instance for the policy owner. */
export async function createAccessModelSodRemediationInstance(params: CreateAccessModelSodInstanceParams): Promise<string> {
    const { forms, formDefinitionId, recipientId, createdBySourceId, formInput } = params
    const instanceFormInput = pickDeclaredFormInputValues(
        accessModelSodRemediationSeed,
        serializeAccessModelSodFormInputForCreate(formInput)
    )
    logIscDebug('createAccessModelSodRemediationInstance formInput', {
        keys: Object.keys(instanceFormInput),
        groupAIds: instanceFormInput.groupAIds,
        groupBIds: instanceFormInput.groupBIds,
    })

    return createStandaloneFormInstance({
        forms,
        formDefinitionId,
        recipientId,
        createdBySourceId,
        formInput: instanceFormInput,
    })
}

export function buildAccessModelSodFormInput(values: AccessModelSodFormInputValues): AccessModelSodFormInputValues {
    return values
}
