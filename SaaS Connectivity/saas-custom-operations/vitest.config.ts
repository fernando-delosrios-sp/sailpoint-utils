import { defineConfig } from 'vitest/config'

export default defineConfig({
    test: {
        name: 'saas-custom-operations',
        globals: true,
        environment: 'node',
        clearMocks: true,
        include: ['src/**/*.spec.ts', 'scripts/**/*.spec.ts'],
        coverage: {
            provider: 'v8',
            include: ['src/**/*.ts'],
            exclude: ['src/**/*.spec.ts', 'src/operations/_template/index.ts'],
            thresholds: {
                statements: 60,
                branches: 50,
                functions: 40,
                lines: 60,
            },
        },
    },
})

