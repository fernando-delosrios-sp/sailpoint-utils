/** Minimal access request status shape used by preventive SoD check helpers. */
export interface AccessRequestStatusItem {
    id?: string | null
    accessRequestId?: string
    name?: string | null
    type?: string | null
    requestType?: string | null
    state?: string
    requestedFor?: { id?: string | null }
}
