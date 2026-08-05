import { connector } from './index'
import { Connector, StandardCommand } from '@sailpoint/connector-sdk'

describe('connector unit tests', () => {
    it('connector SDK major version should be the same as Connector.SDK_VERSION', async () => {
        expect((await connector()).sdkVersion).toStrictEqual(Connector.SDK_VERSION)
    })

    it('does not register std command handlers', async () => {
        const conn = await connector()
        const handlers = conn.handlers

        expect(handlers.has(StandardCommand.StdTestConnection)).toBe(false)
        expect(handlers.has(StandardCommand.StdAccountList)).toBe(false)
        expect(handlers.has(StandardCommand.StdAccountRead)).toBe(false)
    })

    it('registers custom commands', async () => {
        const conn = await connector()

        expect(conn.handlers.has('custom:example')).toBe(true)
    })
})


