import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { E2E_MARKER, env } from './env';

/**
 * Removes what the tests created on a local stack: E2E-tagged transactions,
 * the e2e test devices with their sessions, and customers named "E2E …". Audit logs are left in place on purpose.
 * Set E2E_SKIP_CLEANUP=1 to keep the data for inspection.
 */
export default function globalTeardown(): void {
  if (process.env.E2E_SKIP_CLEANUP === '1') return;
  if (!/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(env.apiUrl)) return;
  const sql = `
    BEGIN;
    DELETE FROM transaction_events WHERE transaction_id IN (SELECT id FROM transactions WHERE destination_reference LIKE '${E2E_MARKER}-%');
    DELETE FROM transactions WHERE destination_reference LIKE '${E2E_MARKER}-%';
    DELETE FROM security_events WHERE safe_metadata->>'deviceId' IN (SELECT id::text FROM devices WHERE installation_id LIKE 'e2e-%');
    DELETE FROM sessions WHERE device_id IN (SELECT id FROM devices WHERE installation_id LIKE 'e2e-%');
    DELETE FROM devices WHERE installation_id LIKE 'e2e-%';
    DELETE FROM security_events WHERE user_id IN (SELECT id FROM users WHERE display_name LIKE '${E2E_MARKER} %');
    DELETE FROM accounts WHERE customer_id IN (SELECT c.id FROM customers c JOIN users u ON u.id = c.user_id WHERE u.display_name LIKE '${E2E_MARKER} %');
    DELETE FROM customers WHERE user_id IN (SELECT id FROM users WHERE display_name LIKE '${E2E_MARKER} %');
    DELETE FROM users WHERE principal_type = 'MOBILE_USER' AND display_name LIKE '${E2E_MARKER} %';
    COMMIT;`;
  try {
    execFileSync('docker', ['compose', 'exec', '-T', 'postgres', 'sh', '-c', 'psql -q -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"'], {
      cwd: fileURLToPath(new URL('../..', import.meta.url)),
      input: sql,
      stdio: ['pipe', 'ignore', 'pipe'],
    });
  } catch (error) {
    console.warn(`E2E cleanup skipped: ${(error as Error).message}`);
  }
}
