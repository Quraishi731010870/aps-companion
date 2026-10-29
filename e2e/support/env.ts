import { existsSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

/** Values from the repo's local `.env` (never committed), overridable by real env vars. */
function loadDotEnv(): Record<string, string> {
  const path = fileURLToPath(new URL('../../.env', import.meta.url));
  if (!existsSync(path)) return {};
  const values: Record<string, string> = {};
  for (const line of readFileSync(path, 'utf8').split('\n')) {
    const match = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (match) values[match[1]] = match[2].replace(/^(['"])(.*)\1$/, '$2');
  }
  return values;
}

const dotEnv = loadDotEnv();

function value(name: string, fallback?: string): string {
  const found = process.env[name] ?? dotEnv[name] ?? fallback;
  if (!found) throw new Error(`${name} is not set. Add it to the repo .env or export it before running the e2e tests.`);
  return found;
}

export const env = {
  /** Backend as the mobile app sees it. */
  apiUrl: value('E2E_API_URL', 'http://localhost:8081'),
  /** Admin portal (its nginx proxies /api to the backend). */
  portalUrl: value('E2E_PORTAL_URL', 'http://localhost:8082'),
  adminEmail: value('E2E_ADMIN_EMAIL', 'admin@afghanpay.test'),
  get adminPassword() { return value('SEED_ADMIN_PASSWORD'); },
  get customerPhone() { return value('SEED_MOBILE_PHONE'); },
  get customerPassword() { return value('SEED_MOBILE_PASSWORD'); },
};

/** Marks every row the tests create so teardown can remove exactly those. */
export const E2E_MARKER = 'E2E';
