#!/usr/bin/env node

import * as readline from 'node:readline/promises'
import { stdin as input, stdout as output } from 'node:process'

import {
    DEFAULT_CONFIG_PATH,
    ENGINES,
    buildDriver,
    listDriverVersions,
    loadConfig,
    resolveVersion,
} from './lib/drivers.mjs'
import { fetchText } from './lib/maven.mjs'
import { downloadAndZip, writeManifest } from './lib/pack.mjs'

const rl = readline.createInterface({ input, output })

const ask = async (prompt) => rl.question(prompt)

const pickDriver = async (config) => {
    console.log('\nSelect a driver:\n')
    ENGINES.forEach((engine, index) => {
        const { name, version } = config[engine]
        console.log(`  ${index + 1}. ${engine.padEnd(10)} ${name} (default: ${version})`)
    })

    while (true) {
        const answer = (await ask('\nDriver number: ')).trim()
        const index = Number.parseInt(answer, 10) - 1
        if (index >= 0 && index < ENGINES.length) return ENGINES[index]
        console.log('Enter a number from the list.')
    }
}

const pickVersion = async (engine, configEntry) => {
    console.log(`\nFetching versions for ${engine}...`)
    const versions = await listDriverVersions(engine, fetchText)
    const latest = versions[versions.length - 1]

    console.log('\nRecent stable versions:\n')
    versions.forEach((version, index) => {
        const marker = version === configEntry.version ? ' (config default)' : ''
        console.log(`  ${index + 1}. ${version}${marker}`)
    })
    console.log(`  L. latest (${latest})`)
    console.log(`  D. use config default (${configEntry.version})`)
    console.log('  C. enter a custom version')

    while (true) {
        const answer = (await ask('\nVersion choice: ')).trim()
        const lower = answer.toLowerCase()

        if (lower === 'l') return latest
        if (lower === 'd') return resolveVersion(engine, configEntry.version, fetchText)
        if (lower === 'c') {
            const custom = (await ask('Custom version: ')).trim()
            if (custom) return custom
            console.log('Enter a version string.')
            continue
        }

        const index = Number.parseInt(answer, 10) - 1
        if (index >= 0 && index < versions.length) return versions[index]
        console.log('Enter a list number, L, D, or C.')
    }
}

const run = async () => {
    const configPath = process.argv[2] || DEFAULT_CONFIG_PATH
    const config = await loadConfig(configPath)

    console.log('JDBC SaaS Driver Downloader')
    console.log(`Config: ${configPath}`)

    const engine = await pickDriver(config)
    const version = await pickVersion(engine, config[engine])
    const resolvedVersion = typeof version === 'string' ? version : await version
    const driver = buildDriver(engine, config[engine], resolvedVersion)

    console.log(`\nDownloading ${driver.name} @ ${driver.version}...`)
    const { jarPath, zipPath, bytes } = await downloadAndZip(driver)
    const manifestPath = await writeManifest([driver], configPath, 'interactive')

    console.log(`\nDone.`)
    console.log(`  JAR: ${jarPath} (${bytes.toLocaleString()} bytes)`)
    console.log(`  ZIP: ${zipPath}`)
    console.log(`  Manifest: ${manifestPath}`)
}

run()
    .catch((err) => {
        console.error(`\nFailed: ${err instanceof Error ? err.message : err}`)
        process.exit(1)
    })
    .finally(() => rl.close())
