# JDBC SaaS Driver Downloader

Download and zip JDBC driver JARs from Maven Central for use with the SailPoint JDBC SaaS connector.

## Requirements

- [Node.js](https://nodejs.org/) 18+ (uses native `fetch`)
- `zip` CLI

## Supported engines

| Key          | Artifact                                      |
|--------------|-----------------------------------------------|
| `db2`        | `com.ibm.db2:jcc`                             |
| `oracle`     | `com.oracle.database.jdbc:ojdbc11`            |
| `sybase`     | `net.sourceforge.jtds:jtds`                   |
| `sqlserver`  | `com.microsoft.sqlserver:mssql-jdbc`          |
| `mysql`      | `com.mysql:mysql-connector-j`                 |
| `postgres`   | `org.postgresql:postgresql`                   |

## Configure defaults

Edit `config/drivers.json` to set the default version, driver name, and JDBC class for each engine:

```json
{
    "postgres": {
        "name": "PostgreSQL JDBC Driver",
        "class": "org.postgresql.Driver",
        "version": "42.7.10"
    },
    "mysql": {
        "name": "MySQL Connector/J",
        "class": "com.mysql.cj.jdbc.Driver",
        "version": "latest"
    }
}
```

| Field     | Description |
|-----------|-------------|
| `name`    | Human-readable driver label |
| `class`   | Fully-qualified JDBC driver class |
| `version` | Default version for batch download, or `"latest"` to resolve the latest stable release from Maven Central |

## Commands

### Interactive — pick one driver and version

```bash
npm run download
```

Prompts you to:

1. Select a driver from the list
2. Choose a version (recent releases, latest, config default, or custom)
3. Download the JAR to `drivers/` and create a ZIP in `dist/`

### Batch — download and zip all configured drivers

```bash
npm run download:all
```

Downloads every engine in `config/drivers.json` using each engine's default `version`, then creates one ZIP per JAR.

Optional custom config path:

```bash
node download-all.mjs path/to/drivers.json
node download-interactive.mjs path/to/drivers.json
```

## Output

- `drivers/*.jar` — downloaded JARs
- `drivers/manifest.json` — versions, class names, and Maven URLs
- `dist/*.zip` — single-JAR ZIPs ready for upload

## Using with SailPoint JDBC SaaS

Upload the ZIP from `dist/` as a driver asset for your JDBC SaaS source, then set the driver class from `manifest.json` or `config/drivers.json`.

## Notes

- Oracle JARs may have licensing constraints; use the interactive command to pick an approved version, or place a manual JAR under `drivers/` if needed.
- AWS RDS uses the same engine drivers based on the database type (MySQL, PostgreSQL, SQL Server, Oracle, etc.).
