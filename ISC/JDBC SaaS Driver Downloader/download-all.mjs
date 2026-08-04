#!/usr/bin/env node

import { DEFAULT_CONFIG_PATH, loadConfig, resolveConfiguredDrivers } from './lib/drivers.mjs'
import { fetchText } from './lib/maven.mjs'
import { downloadAndZipAll, writeManifest } from './lib/pack.mjs'

const run = async () => {
    const configPath = process.argv[2] || DEFAULT_CONFIG_PATH
    console.log(`Config: ${configPath}`)

    const config = await loadConfig(configPath)
    const drivers = await resolveConfiguredDrivers(config, fetchText)

    console.log('Downloading and zipping all configured drivers:')
    await downloadAndZipAll(drivers)

    const manifestPath = await writeManifest(drivers, configPath, 'all')
    console.log(`Manifest: ${manifestPath}`)
}

run().catch((err) => {
    console.error(`Failed: ${err instanceof Error ? err.message : err}`)
    process.exit(1)
})
