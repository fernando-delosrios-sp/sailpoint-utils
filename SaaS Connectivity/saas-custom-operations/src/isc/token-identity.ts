import { ConnectorError } from '@sailpoint/connector-sdk'

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
