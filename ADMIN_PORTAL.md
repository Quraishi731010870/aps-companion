# PayAfghan Admin Portal

## Status

The separate React web application is in `admin-portal/`. It provides a
responsive enterprise-style shell, typed HTTP admin API adapter, sign-in/session
architecture, protected routes, client-side permission gates, and customers,
transactions, monitoring, notifications, reports, security, and configuration
surfaces.

The executable NestJS API in `backend/src` provides administrator identity,
cookie sessions, CSRF protection, RBAC, PostgreSQL-backed data, audit logging,
configuration, dynamic content, and monitoring endpoints. The portal never
connects to Google Sheets. `/preview` remains intentionally disconnected.

## Architecture

```text
Browser (React + TypeScript)
        │ HTTPS, HttpOnly cookie, CSRF header
        ▼
AdminApi interface (`src/api/adminApi.ts`)
        │ FetchAdminApi (`backend/src` REST controllers)
        ▼
NestJS backend / BFF
        ├── PostgreSQL / Prisma
        ├── Redis / Socket.IO
        └── Prometheus / Grafana (Docker Compose)
```

`AdminApi` models sessions, permissions, paginated customers/transactions,
dashboard data, and monitoring. `FetchAdminApi` uses credentialed cookies,
CSRF tokens, request timeouts, generic errors, and session expiry handling.
`backend/admin-api/` is an archived pre-implementation contract. The NestJS
controllers and generated Swagger document are authoritative.

The preview is available at `/preview/dashboard`. Real routes are under `/app`
and are protected by an in-memory session returned by the future backend
adapter. Session tokens are not written to local storage. The production
backend must use secure, HttpOnly, SameSite cookies (or an approved OIDC flow),
CSRF protection where needed, session expiry/revocation, and server-side RBAC.
Frontend permission gates are a UX aid, not an authorization boundary.

## Run locally

Requires Node.js 20.19+ (or 22.12+) and npm. This matches the patched Vite 7,
React Router 7, and Vitest 4 toolchain.

```sh
cd admin-portal
npm ci
cp .env.example .env.local
npm run dev
```

Vite serves the web app at `http://localhost:5173`. The current build opens at
the unconnected sign-in screen; choose **Open disconnected interface preview**
to inspect the portal shell and backend-required states.

## Environment configuration

`.env.example` contains public, non-secret placeholders:

| Variable | Purpose | Current state |
|---|---|---|
| `VITE_API_BASE_URL` | Same-origin admin API/BFF origin (loopback HTTP only for local development) | Adapter implemented; server not present |

The client rejects cross-origin API URLs; route `/api/` through the portal's
same-origin reverse proxy. Monitoring providers are configured only
server-side. No Vite variables expose
Grafana or Zabbix URLs/credentials. See [`MONITORING.md`](MONITORING.md).

Vite exposes every `VITE_*` value to the browser bundle. Never put passwords,
API keys, access tokens, private keys, Zabbix credentials, or other secrets in
these variables. The root `.gitignore` excludes `.env` and `.env.*`; only the
placeholder `.env.example` is intended for Git.

## API integration requirements

The client targets the versioned OpenAPI contract under
[`backend/admin-api/openapi.yaml`](backend/admin-api/openapi.yaml). The backend
server still needs implementation and the organization must approve its
authentication/session, CSRF/CORS, error, role/permission and safe-field
policies. It must enforce all permissions and audit sensitive actions.

Required capabilities for the planned modules:

* Authentication: administrator login, current-session lookup, logout/revocation,
  expiry, and permission claims.
* Customers: searchable/paginated list, authorized detail/activity/account
  views, and status mutation only if a supported workflow exists.
* Transactions: searchable/paginated list and detail; authoritative status,
  response, and timeline. Retry/reverse/cancel/approve/reject are absent and are
  not exposed as actions.
* Dashboard/reports: server-computed aggregates, trends, report filters, and
  authorized export. The mobile prototype list is capped and unsuitable for
  reporting.
* Notifications: provider, templates, recipient targeting, delivery history,
  and asynchronous delivery status.
* Monitoring: an authenticated server-side integration or SSO-protected
  Grafana. Zabbix credentials must remain on the backend; do not call Zabbix
  directly from the browser.
* Security/system: administrators, roles, permissions, persistent audit logs,
  login history, alerts, logs, and configuration APIs.

## Backend and monitoring status

The app currently defaults to `MockPaymentGateway`. Optional Google Apps Script
files are explicitly prototypes: one records limited user rows; a separate
script records transactions and has a capped recent-transaction read. There is
no authoritative payment ledger, admin API server, mutation API,
FCM/notification provider, configured Zabbix/Grafana integration, Prometheus,
infrastructure metrics, or admin audit service. A proposed TypeScript API/BFF,
PostgreSQL admin control-plane schema, endpoint contract, and environment
placeholders are documented under `backend/admin-api/`; they are not a running
backend and have not been applied to a database. The portal reports missing
integrations as unavailable and does not synthesize metrics, actions, events,
or lifecycle stages.

No transaction action is supported. Existing `processing/successful/failed/
reversed` types do not provide a backend transaction lifecycle; current app
flows generally return success in mock/prototype behavior. Therefore status
changes and financial actions must wait for a real transaction service.

Zabbix binaries and configuration files exist on this development machine, but
no server/agent process appeared in the process scan; service-manager checks
were blocked by sandbox permissions. No Grafana executable or project
monitoring deployment config was found. See [`MONITORING.md`](MONITORING.md).

The API adapter uses secure credentialed-cookie requests, CSRF tokens,
timeouts, sanitized errors, and client cache clearing on session expiry. The
backend contract and control-plane schema are proposals; they do not provide
server-enforced authentication or RBAC until implemented and deployed.

## Security notes

* The source-embedded Apps Script shared token default was removed from active
  source. Apps Script now expects `SERVICE_TOKEN` and `SPREADSHEET_ID` in Script
  Properties. The mobile prototype still requires a build-time shared token;
  such a token is extractable from an app bundle and is never used by this
  portal.
* Rotate/revoke the previously exposed token in the deployed Apps Script
  project. Do not reuse it. A new token in Script Properties does not make a
  mobile-embedded shared token production-safe.
* The Git initial commit predates this cleanup and contains the former source
  token in its history. If that commit was pushed to GitHub, treat the token as
  compromised and rotate it immediately. History cleanup requires a separately
  coordinated repository operation; do not force-push without explicit review.
* Google Sheets must not be treated as an EMI ledger or as an admin database.
  Use a regulated/authenticated backend, least-privilege identities, TLS,
  server-side validation, rate limits, audit persistence, and security review.

Dependency review: the portal was upgraded to React Router 7, Vite 7, and
Vitest 4 to use patched releases. Tests, lint, development/UAT/production
builds passed under Node.js 22.13; `npm audit` reports zero
vulnerabilities. Keep route targets fixed internal paths; do not pass untrusted
redirect destinations to router navigation.

## Testing and build

```sh
npm test
npm run lint
npm run build
npm run preview
```

The current automated tests cover the disconnected login/preview behavior,
protected-route redirect, and fail-closed API contract. API authorization,
customer/transaction data loading, filtering against a server, transaction
actions, monitoring, notifications, report export, and logout revocation cannot
be integration-tested until their backend services exist.

## Deployment

Build with `npm run build` and deploy `admin-portal/dist/` to a static web host
behind HTTPS. Configure SPA fallback to `index.html`, restrictive CSP and
security headers, trusted origins, and an authenticated same-origin API/BFF.
Configure production CORS on the backend only for the exact portal origin.
Do not deploy as an operational console until authentication, server-enforced
RBAC, audit persistence, API contract tests, and the token rotation/history
review are complete.
