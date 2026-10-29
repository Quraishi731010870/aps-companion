import { defineConfig, devices } from '@playwright/test';
import { env } from './support/env';

/**
 * Runs against the local Docker stack (see e2e/README.md). Serial on purpose:
 * the feature-flag tests change shared configuration and restore it.
 */
export default defineConfig({
  testDir: './tests',
  fullyParallel: false,
  workers: 1,
  retries: 0,
  timeout: 30_000,
  expect: { timeout: 10_000 },
  reporter: [['list'], ['html', { open: 'never' }]],
  globalSetup: './support/global-setup.ts',
  globalTeardown: './support/global-teardown.ts',
  use: { trace: 'retain-on-failure', screenshot: 'only-on-failure' },
  projects: [
    { name: 'api', testDir: './tests/api' },
    { name: 'portal', testDir: './tests/portal', use: { ...devices['Desktop Chrome'], baseURL: env.portalUrl } },
  ],
});
