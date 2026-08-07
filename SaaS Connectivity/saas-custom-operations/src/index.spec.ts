import { readFileSync } from 'fs'
import { join } from 'path'
import { connector } from './index'
import { Connector, StandardCommand } from '@sailpoint/connector-sdk'

function connectionConfigKeys(): string[] {
    const manifest = JSON.parse(readFileSync(join(__dirname, '../connector-spec.json'), 'utf8'))
    const items = manifest.sourceConfig?.[0]?.items?.[0]?.items ?? []
    return items.map((item: { key: string }) => item.key)
}

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

    it('connector manifest uses sourceName for result source config', () => {
        const keys = connectionConfigKeys()

        expect(keys).toContain('sourceName')
        expect(keys).not.toContain('sourceId')
    })
})

