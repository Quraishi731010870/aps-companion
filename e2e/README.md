# End-to-end tests

Playwright tests across the three parts of the system, run against the **local Docker stack**:

| Project | What it proves |
|---|---|
| `api` | A customer signs in with a bound Ed25519 device and pays; the admin API sees the payment. Unsigned, tampered, replayed, stale and foreign-device requests are rejected. Admin feature-flag changes reach the mobile configuration. Customers can't use admin endpoints. |
| `portal` | Admin sign-in through the real login form (wrong password refused). A payment made through the mobile API appears in **Transactions** with its timeline. Flipping a feature flag switch in **Configuration** changes the mobile configuration. |

## Run

```bash
docker compose up -d postgres redis backend admin-portal   # from the repo root
cd e2e
npm ci
npx playwright install chromium   # first time only
npm test                          # or: npm run test:api / npm run test:portal
npm run report                    # HTML report of the last run
```

Credentials come from the repo-root `.env` (`SEED_ADMIN_PASSWORD`, `SEED_MOBILE_PHONE`,
`SEED_MOBILE_PASSWORD`); real environment variables override them. `E2E_API_URL`
(default `http://localhost:8081`) and `E2E_PORTAL_URL` (default `http://localhost:8082`)
point the tests elsewhere.

## Data

Tests run serially because they change shared configuration; every flag they flip is
restored, even on failure. Payments go to `E2E-MERCHANT-…` destinations and use the
`e2e-playwright-device` installation. Teardown deletes those rows from the local database
(audit logs are kept). Set `E2E_SKIP_CLEANUP=1` to keep them for inspection. Cleanup only
runs against `localhost`.
