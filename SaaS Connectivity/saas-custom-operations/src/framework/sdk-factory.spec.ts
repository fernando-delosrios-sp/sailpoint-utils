import { describe, expect, it } from 'vitest'
import { createSailPointClients } from '../framework/sdk-factory'

describe('sdk-factory', () => {
    it('createSailPointClients returns ISC loopback clients for sod remediation', () => {
        const clients = createSailPointClients('https://tenant.api.identitynow.com', 'token')

        expect(clients.accounts).toBeDefined()
        expect(clients.sources).toBeDefined()
        expect(typeof clients.forms.searchFormDefinitionsByTenantV1).toBe('function')
        expect(typeof clients.identityHistory.listIdentityAccessItemsV1).toBe('function')
        expect(typeof clients.accessProfiles.getAccessProfileEntitlementsV1).toBe('function')
        expect(typeof clients.roles.getRoleEntitlementsV1).toBe('function')
        expect(typeof clients.tasks.getTaskStatusV1).toBe('function')
        expect(typeof clients.governanceGroups.listWorkgroupsV1).toBe('function')
        expect(typeof clients.governanceGroups.listWorkgroupMembersV1).toBe('function')
        expect(typeof clients.accessRequests.listAccessRequestStatusV1).toBe('function')
        expect(typeof clients.search.searchPostV1).toBe('function')
        expect(typeof clients.sodPolicies.listSodPoliciesV1).toBe('function')
        expect(typeof clients.sodPolicies.getSodPolicyV1).toBe('function')
        expect(typeof clients.sodViolations.startPredictSodViolationsV1).toBe('function')
    })
})
