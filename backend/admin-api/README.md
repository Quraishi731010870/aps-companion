# Archived Admin API design contract

> Historical design artifact: the executable implementation now lives in
> `backend/src` and uses NestJS, Prisma, PostgreSQL, and Redis. Do not build a
> second API from this directory. `openapi.yaml` and
> `control_plane_schema.sql` are retained for traceability and must not be
> applied as a competing schema.

## Discovery and status

At the time this document was written, the existing `backend/` was Google Apps Script/Google Sheets only. It is a
prototype integration, not an authenticated application service. The Flutter
application has no production identity provider or authoritative database;
`MockPaymentGateway` defaults to success, while `GoogleSheetsGateway` records
prototype transactions. The separate user sheet script supports basic
list/append. None of these services are used by this API contract.

The repository now contains an admin API server. This directory originally established
the transport contract and database boundary for one. Do not expose customer
or financial operations until an owner identifies the authoritative regulated
customer/ledger services and supplies their supported query/action contracts.

## Proposed architecture

Use a TypeScript Node.js API/BFF (Fastify or Express are both suitable; choose
one when the deployment platform is known), PostgreSQL for admin identities,
server sessions, RBAC assignments, and audit persistence, and service adapters
to the existing authoritative customer/transaction services. Those source
services are not present today. Avoid duplicating their customer/ledger data in
the admin control-plane database.

```text
React portal -- HTTPS, HttpOnly cookie + CSRF --> Admin API/BFF
                                                ├── Admin PostgreSQL schema
                                                ├── Customer service (external / not supplied)
                                                ├── Transaction ledger (external / not supplied)
                                                ├── Notification provider (not supplied)
                                                └── Monitoring proxy -> Zabbix/Grafana (not active)
```

`openapi.yaml` defines the intended versioned API used by the portal's
`FetchAdminApi`. It is a contract, not a claim that these endpoints currently
exist. Until the API is deployed, leave `VITE_API_BASE_URL` empty. A URL alone
does not make the API or login service operational.

`control_plane_schema.sql` is a proposed initial schema for admin identities,
role/permission assignments, hashed sessions, and audit events. It has not been
applied to any database. It intentionally omits customer/transaction copies.
`.env.example` lists server-side configuration names only; it contains no
service credentials.

## Authentication and authorization design

* Use a server-side, opaque session cookie named `__Host-admin_session` with
  `Secure`, `HttpOnly`, `SameSite=Strict`, `Path=/`, and no `Domain` attribute.
* Store only a one-way session identifier hash server-side. Expire and revoke
  sessions server-side; never accept role/permission claims from browser state.
* `GET /auth/csrf` issues a session-bound CSRF token. Send mutations with
  `X-CSRF-Token`. Require exact-origin CORS; prefer same-origin reverse proxy.
* Store passwords with Argon2id or a reviewed password-hashing implementation.
  Support lockout/rate limiting and a separately verified reset workflow.
* Enforce permission checks on every handler, not just in React. Apply least
  privilege; seed no default administrator credentials or public bootstrap.
* Implement role/permission administration and self-protection policies before
  exposing any administrator mutation endpoint.
* Log successful/failed admin login, logout, data mutations, and denials to a
  durable append-oriented audit store. Omit passwords, cookies, tokens, PAN,
  PIN, secret values, and unredacted request/response bodies.

Suggested initial role mappings (must be approved by the institution):

| Role | Intended permission scope |
|---|---|
| Super Admin | Security/admin configuration; no implicit financial mutation |
| Admin | Customer and system administration |
| Operations | Transaction search and approved transaction actions |
| Support | Masked customer and transaction read-only support |
| Monitoring | Monitoring and alert acknowledgement |
| Viewer | Read-only overview and permitted reports |

Keep mutation permissions separate (`transactions.act`, `alerts.manage`,
`customers.edit`, `security.manage`). Require dual control for any future
financial action if the ledger supports it.

## Data boundary

The admin control plane should contain administrator accounts, role/permission
definitions and assignments, hashed/revocable sessions, and audit events. It
should not create replacement `Customers` or `Transactions` tables. Customer
and transaction APIs must query the authoritative service. Existing prototype
Sheets include seeded examples and hard-coded-success behavior; they are not a
production source and must not be attached to this portal.

No supported financial mutation endpoint was discovered. The portal intentionally
has no retry/reverse/cancel/approve/reject API. Notification provider, report
jobs, and persistent application audit source also remain unspecified.

## Local API contract

Read `openapi.yaml`. Core endpoints used by the client:

* `GET /api/admin/v1/auth/csrf`, `POST /auth/login`, `GET /auth/session`,
  `POST /auth/logout`
* `GET /dashboard`, `GET /customers`, `GET /transactions`,
  `GET /transactions/{id}`
* `GET /monitoring/overview`, `/monitoring/transactions`, `/monitoring/alerts`
* `GET /customers/{id}` for masked profile/account/activity data

All list endpoints are server-paginated and accept allow-listed sort/filter
parameters. Every endpoint except CSRF and login requires the server session;
mutations require CSRF plus permission. Standard errors use safe message/code
and `requestId`; never return stack traces or upstream credentials.

## Deployment dependencies

Before implementing/deploying the server, the project owner must select the
hosting environment, supported Node LTS, PostgreSQL service/backup policy,
secret manager, identity/password reset policy, authoritative EMI customer and
ledger APIs, role approval, trusted origins, and provider-specific monitoring
and notification access. Do not use Apps Script as a substitute for these.

No server credentials, seed account, migration execution, or deployment have
been added here. The portal's API adapter is testable independently and fails
closed when configuration is absent.
