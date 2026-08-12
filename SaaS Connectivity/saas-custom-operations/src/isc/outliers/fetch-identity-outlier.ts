import { IAIOutliersApi } from 'sailpoint-api-client'
import { SAILPOINT_EXPERIMENTAL } from '../../framework/sdk-factory'

export interface IdentityOutlierData {
    score?: number
    [key: string]: unknown
}

/** Fetches outlier score data for an identity. Returns null when unavailable. */
export async function fetchIdentityOutlier(
    iaiOutliers: IAIOutliersApi,
    identityId: string
): Promise<IdentityOutlierData | null> {
    try {
        const response = await iaiOutliers.getIdentityOutliersV1({
            filters: `identityId eq "${identityId}"`,
            xSailPointExperimental: SAILPOINT_EXPERIMENTAL,
        })
        const items = response.data ?? []
        return (items[0] as IdentityOutlierData | undefined) ?? null
    } catch (error) {
        console.error(`[fetchIdentityOutlier] Error fetching outlier for identity ${identityId}:`, error)
        return null
    }
}

/** Formats outlier score as a percentage string for workflow display. */
export function formatOutlierScore(outlier: IdentityOutlierData | null): string {
    if (outlier?.score === undefined || outlier.score === null) {
        return 'N/A'
    }
    return `${(outlier.score * 100).toFixed(2)}%`
}
