import { type IscClientConfig, iscGet } from '../http'

interface PublicIdentity {
    id: string
    email?: string
}

/** Resolves an identity's public email address by ID. Returns empty string when not found. */
export async function resolveIdentityEmail(config: IscClientConfig, identityId: string): Promise<string> {
    const identities = await iscGet<PublicIdentity[]>(
        config,
        `/public-identities/v1?filters=id eq "${identityId}"`
    )
    return identities[0]?.email ?? ''
}
