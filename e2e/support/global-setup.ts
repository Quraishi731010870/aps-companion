import { env } from './env';

/** Fails fast with a useful message when the local stack is not running. */
export default async function globalSetup(): Promise<void> {
  for (const [name, url] of [['backend', `${env.apiUrl}/health/ready`], ['admin portal', `${env.portalUrl}/healthz`]] as const) {
    const ok = await fetch(url).then((response) => response.ok, () => false);
    if (!ok) throw new Error(`The ${name} is not reachable at ${url}. Start it with: docker compose up -d postgres redis backend admin-portal`);
  }
  // Touch the credentials now so a missing value fails before any test runs.
  void [env.adminPassword, env.customerPhone, env.customerPassword];
}
