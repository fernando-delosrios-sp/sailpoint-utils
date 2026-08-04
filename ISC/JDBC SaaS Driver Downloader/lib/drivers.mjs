import { readFile } from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

import { jarUrl, latestStable, listStableVersions, metadataUrl } from './maven.mjs'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
export const ROOT_DIR = path.resolve(__dirname, '..')
export const DEFAULT_CONFIG_PATH = path.join(ROOT_DIR, 'config', 'drivers.json')
export const DRIVERS_DIR = path.join(ROOT_DIR, 'drivers')
export const DIST_DIR = path.join(ROOT_DIR, 'dist')

export const ARTIFACTS = {
    db2: { groupId: 'com.ibm.db2', artifactId: 'jcc', notes: 'IBM DB2 JDBC driver.' },
    oracle: {
        groupId: 'com.oracle.database.jdbc',
        artifactId: 'ojdbc11',
        notes: 'Oracle artifacts may have licensing restrictions.',
    },
    sybase: { groupId: 'net.sourceforge.jtds', artifactId: 'jtds', notes: 'jTDS for Sybase ASE.' },
    sqlserver: { groupId: 'com.microsoft.sqlserver', artifactId: 'mssql-jdbc' },
    mysql: { groupId: 'com.mysql', artifactId: 'mysql-connector-j' },
    postgres: { groupId: 'org.postgresql', artifactId: 'postgresql' },
}

export const ENGINES = Object.keys(ARTIFACTS)

export const loadConfig = async (configPath = DEFAULT_CONFIG_PATH) => {
    const raw = JSON.parse(await readFile(configPath, 'utf8'))
    const config = {}

    for (const engine of ENGINES) {
        const entry = raw[engine]
        if (!entry || typeof entry !== 'object') {
            throw new Error(`Missing configuration for engine "${engine}" in ${configPath}`)
        }

        if (typeof entry.name !== 'string' || !entry.name.trim()) {
            throw new Error(`Invalid config for "${engine}": "name" must be a non-empty string.`)
        }
        if (typeof entry.class !== 'string' || !entry.class.trim()) {
            throw new Error(`Invalid config for "${engine}": "class" must be a non-empty string.`)
        }
        if (entry.version !== undefined && typeof entry.version !== 'string') {
            throw new Error(`Invalid config for "${engine}": "version" must be a string when provided.`)
        }

        config[engine] = {
            name: entry.name.trim(),
            class: entry.class.trim(),
            version: typeof entry.version === 'string' ? entry.version.trim() : 'latest',
        }
    }

    return config
}

export const resolveVersion = async (engine, versionHint, fetchText) => {
    const configured = versionHint?.trim()
    if (configured && configured.toLowerCase() !== 'latest') return configured

    const { groupId, artifactId } = ARTIFACTS[engine]
    const metadata = await fetchText(metadataUrl(groupId, artifactId))
    return latestStable(metadata)
}

export const buildDriver = (engine, configEntry, version) => {
    const artifact = ARTIFACTS[engine]
    return {
        engine,
        ...artifact,
        name: configEntry.name,
        class: configEntry.class,
        version,
        jarFileName: `${engine}-${artifact.artifactId}-${version}.jar`,
        jarUrl: jarUrl(artifact.groupId, artifact.artifactId, version),
    }
}

export const resolveConfiguredDrivers = async (config, fetchText) => {
    const resolved = []

    for (const engine of ENGINES) {
        const version = await resolveVersion(engine, config[engine].version, fetchText)
        resolved.push(buildDriver(engine, config[engine], version))
    }

    return resolved
}

export const listDriverVersions = async (engine, fetchText, limit = 12) => {
    const { groupId, artifactId } = ARTIFACTS[engine]
    const metadata = await fetchText(metadataUrl(groupId, artifactId))
    const versions = listStableVersions(metadata)
    return versions.slice(-limit)
}
