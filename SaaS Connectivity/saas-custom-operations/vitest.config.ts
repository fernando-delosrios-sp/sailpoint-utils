import { defineConfig } from 'vitest/config'

export default defineConfig({
    test: {
        globals: true,
        environment: 'node',
        clearMocks: true,
        include: ['src/**/*.spec.ts', 'scripts/**/*.spec.ts'],
        coverage: {
            provider: 'v8',
            include: ['src/**/*.ts'],
            exclude: [
                'src/**/*.spec.ts',
                'src/operations/_template.ts',
                // Endpoint-migration stubs — not registered on the connector yet
                'src/services/access.service.ts',
                'src/services/recommendation.service.ts',
                'src/services/email-templates.ts',
            ],
            thresholds: {
                statements: 60,
                branches: 50,
                functions: 40,
                lines: 60,
            },
        },
    },
})


