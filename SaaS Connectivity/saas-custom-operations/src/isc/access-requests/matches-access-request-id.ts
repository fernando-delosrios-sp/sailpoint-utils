import type { AccessRequestStatusItem } from './types'
import { resolveAccessRequestTrackingNumber } from './list-executing-grants'

/** True when the status item matches the workflow access request id or tracking number. */
export function matchesAccessRequestId(request: AccessRequestStatusItem, accessRequestId: string): boolean {
    const trackingNumber = resolveAccessRequestTrackingNumber(request)
    return (
        request.accessRequestId === accessRequestId ||
        request.id === accessRequestId ||
        trackingNumber === accessRequestId
    )
}
