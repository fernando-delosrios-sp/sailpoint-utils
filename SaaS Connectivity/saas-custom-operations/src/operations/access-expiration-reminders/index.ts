import { ConnectorError } from '@sailpoint/connector-sdk'
import { customOperation, isOfflineContext, OperationSignature, RequestContext } from '../../framework'
import { findAccountOnSource } from '../../isc/accounts'
import {
    OFFLINE_REFERENCE_NOW,
    searchIdentitiesWithSunsetAccessProfiles,
    searchIdentitiesWithSunsetAccessProfilesOffline,
    type IdentityWithSunsetAccessProfiles,
} from '../../isc/identities'
import { resolveIdentityEmail } from '../../isc/public-identities'
import { resolveIdentityEmailOffline } from '../../isc/public-identities/offline-data'
import { resolveTokenIdentity } from '../../isc/token-identity'
import { childPersistIdentity, DEFAULT_EXPIRATION_DAYS, MAX_FORMS_PER_RUN } from './constants'
import { buildFormEmailBody, buildFormEmailHeader } from './form-email'
import {
    createAccessExpirationRemindersInstance,
    ensureAccessExpirationRemindersFormDefinition,
} from './form-service'
import { accessExpirationRemindersOperationSchema } from './index.schema'
import { matchesExpirationDays } from './utc-day-match'

export interface AccessExpirationRemindersOperation extends OperationSignature {
    command: 'custom:access-expiration-reminders'
    input: {
        formName: string
        expirationDays?: number
    }
    output: {
        'access-expiration-reminders:identities-scanned': number
        'access-expiration-reminders:expirations-matched': number
        'access-expiration-reminders:forms-created': number
        'access-expiration-reminders:forms-skipped-existing'?: number
        'access-expiration-reminders:forms-skipped-missing-manager-email'?: number
        'access-expiration-reminders:forms-launch-failed'?: number
        'access-expiration-reminders:forms-persist-failed'?: number
        'access-expiration-reminders:forms-overflow'?: number
        'access-expiration-reminders:identityId'?: string
        'access-expiration-reminders:managerId'?: string
        'access-expiration-reminders:accessProfileId'?: string
        'access-expiration-reminders:removeDate'?: string
        'access-expiration-reminders:daysRemaining'?: number
        'access-expiration-reminders:form-url'?: string
        'access-expiration-reminders:form-email-header'?: string
        'access-expiration-reminders:form-email-body'?: string
        'access-expiration-reminders:form-email-recipients'?: string[]
    }
}

function escapeHtml(text: string): string {
    return text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
}

function buildSituationSummaryHtml(params: {
    identityDisplayName: string
    accessProfileName: string
    removeDate: string
    daysRemaining: number
}): string {
    const identity = escapeHtml(params.identityDisplayName)
    const profile = escapeHtml(params.accessProfileName)
    const removeDate = escapeHtml(params.removeDate)
    const daysLabel = params.daysRemaining === 1 ? '1 day' : `${params.daysRemaining} days`
    return (
        `<p><strong>${identity}</strong> holds access profile <strong>${profile}</strong>, ` +
        `which expires on <strong>${removeDate}</strong> (${daysLabel} remaining).</p>` +
        `<p>Select a <em>new expiration date after</em> the current expiration. ` +
        `This form does not apply the date automatically.</p>`
    )
}

async function discoverSunsetIdentities(
    offline: boolean,
    ctx: RequestContext<AccessExpirationRemindersOperation['output']>
): Promise<IdentityWithSunsetAccessProfiles[]> {
    if (offline) {
        ctx.log.info('discoverSunsetIdentities using offline fixtures')
        return searchIdentitiesWithSunsetAccessProfilesOffline()
    }

    ctx.log.info('discoverSunsetIdentities searching identities')
    return searchIdentitiesWithSunsetAccessProfiles(ctx.sdk.search)
}

/** Discovers near-expiry ACCESS_PROFILE assignments and launches manager reminder forms. */
export const accessExpirationRemindersOperation = customOperation<AccessExpirationRemindersOperation>(
    async (ctx, input) => {
        const formName = input.formName?.trim()
        if (!formName) {
            throw new ConnectorError('Missing required input field: formName')
        }

        const offline = isOfflineContext(ctx)
        const expirationDays = input.expirationDays ?? DEFAULT_EXPIRATION_DAYS
        const now = offline ? OFFLINE_REFERENCE_NOW : new Date()

        ctx.log.info('access-expiration-reminders start', {
            offline,
            apiUrl: ctx.apiUrl || '<empty>',
            expirationDays,
            formName,
        })

        const identities = await discoverSunsetIdentities(offline, ctx)
        const tokenOwnerId = offline ? 'offline-token-owner' : await resolveTokenIdentity(ctx.token)
        const formDefinitionId = await ensureAccessExpirationRemindersFormDefinition(
            ctx.sdk.forms,
            formName,
            tokenOwnerId
        )

        let expirationsMatched = 0
        let formsCreated = 0
        let formsSkippedExisting = 0
        let formsSkippedMissingManagerEmail = 0
        let formsLaunchFailed = 0
        let formsPersistFailed = 0
        let formsOverflow = 0
        let capWarningLogged = false
        const managerEmailById = new Map<string, string>()

        for (const identity of identities) {
            for (const accessProfile of identity.accessProfiles) {
                if (!matchesExpirationDays(accessProfile.removeDate, expirationDays, now)) {
                    continue
                }

                expirationsMatched += 1

                if (formsCreated >= MAX_FORMS_PER_RUN) {
                    formsOverflow += 1
                    if (!capWarningLogged) {
                        capWarningLogged = true
                        ctx.log.warn('access-expiration-reminders form cap reached; skipping remaining forms', {
                            cap: MAX_FORMS_PER_RUN,
                        })
                    }
                    continue
                }

                const childId = childPersistIdentity(ctx.requestId, identity.id, accessProfile.id)
                const existingChildAccount = offline
                    ? undefined
                    : await findAccountOnSource(ctx.sdk.accounts, ctx.sourceId, childId)

                if (existingChildAccount) {
                    ctx.log.info(
                        'access-expiration-reminders skipping assignment: notice account already exists',
                        {
                            identityId: identity.id,
                            accessProfileId: accessProfile.id,
                            childId,
                        }
                    )
                    formsSkippedExisting += 1
                    continue
                }

                const managerId = identity.managerId?.trim()
                if (!managerId) {
                    formsSkippedMissingManagerEmail += 1
                    ctx.log.info('access-expiration-reminders skipping assignment: missing manager', {
                        identityId: identity.id,
                        accessProfileId: accessProfile.id,
                    })
                    continue
                }

                let managerEmail = managerEmailById.get(managerId)
                if (managerEmail === undefined) {
                    managerEmail = offline
                        ? resolveIdentityEmailOffline(managerId)
                        : await resolveIdentityEmail({ apiUrl: ctx.apiUrl, token: ctx.token }, managerId)
                    managerEmailById.set(managerId, managerEmail)
                }

                if (!managerEmail.trim()) {
                    formsSkippedMissingManagerEmail += 1
                    ctx.log.info('access-expiration-reminders skipping assignment: missing manager email', {
                        identityId: identity.id,
                        accessProfileId: accessProfile.id,
                        managerId,
                    })
                    continue
                }

                const daysRemaining = expirationDays
                const situationSummaryHtml = buildSituationSummaryHtml({
                    identityDisplayName: identity.displayName,
                    accessProfileName: accessProfile.name,
                    removeDate: accessProfile.removeDate,
                    daysRemaining,
                })
                const emailInput = {
                    identityDisplayName: identity.displayName,
                    accessProfileName: accessProfile.name,
                    removeDate: accessProfile.removeDate,
                    daysRemaining,
                }

                let formUrl: string
                try {
                    formUrl = await createAccessExpirationRemindersInstance({
                        forms: ctx.sdk.forms,
                        formDefinitionId,
                        recipientId: managerId,
                        createdBySourceId: ctx.sourceId,
                        expire: accessProfile.removeDate,
                        formInput: {
                            responseAccountId: childId,
                            identityId: identity.id,
                            accessProfileId: accessProfile.id,
                            identityDisplayName: identity.displayName,
                            accessProfileName: accessProfile.name,
                            removeDate: accessProfile.removeDate,
                            daysRemaining: String(daysRemaining),
                            situationSummaryHtml,
                        },
                    })
                } catch (error) {
                    formsLaunchFailed += 1
                    const detail = error instanceof Error ? error.message : String(error)
                    ctx.log.warn('access-expiration-reminders form launch failed', {
                        identityId: identity.id,
                        accessProfileId: accessProfile.id,
                        detail,
                    })
                    continue
                }

                try {
                    await ctx.persist(
                        childId,
                        {
                            'access-expiration-reminders:identityId': identity.id,
                            'access-expiration-reminders:managerId': managerId,
                            'access-expiration-reminders:accessProfileId': accessProfile.id,
                            'access-expiration-reminders:removeDate': accessProfile.removeDate,
                            'access-expiration-reminders:daysRemaining': daysRemaining,
                            'access-expiration-reminders:form-url': formUrl,
                            'access-expiration-reminders:form-email-header': buildFormEmailHeader(emailInput),
                            'access-expiration-reminders:form-email-body': buildFormEmailBody(emailInput, formUrl),
                            'access-expiration-reminders:form-email-recipients': [managerEmail],
                        },
                        undefined,
                        { verify: false }
                    )
                } catch (error) {
                    formsPersistFailed += 1
                    const detail = error instanceof Error ? error.message : String(error)
                    ctx.log.warn('access-expiration-reminders child persist failed', {
                        identityId: childId,
                        detail,
                    })
                }

                formsCreated += 1
            }
        }

        ctx.res.send({
            status: 'success',
            'access-expiration-reminders:identities-scanned': identities.length,
            'access-expiration-reminders:expirations-matched': expirationsMatched,
            'access-expiration-reminders:forms-created': formsCreated,
            ...(formsSkippedExisting > 0
                ? { 'access-expiration-reminders:forms-skipped-existing': formsSkippedExisting }
                : {}),
            ...(formsSkippedMissingManagerEmail > 0
                ? {
                      'access-expiration-reminders:forms-skipped-missing-manager-email':
                          formsSkippedMissingManagerEmail,
                  }
                : {}),
            ...(formsLaunchFailed > 0
                ? { 'access-expiration-reminders:forms-launch-failed': formsLaunchFailed }
                : {}),
            ...(formsPersistFailed > 0
                ? { 'access-expiration-reminders:forms-persist-failed': formsPersistFailed }
                : {}),
            ...(formsOverflow > 0 ? { 'access-expiration-reminders:forms-overflow': formsOverflow } : {}),
        })
    },
    { operationSchema: accessExpirationRemindersOperationSchema }
)
