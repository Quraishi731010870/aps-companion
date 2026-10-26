# AfghanPay dynamic payment platform

An Afghanistan-focused platform containing the preserved Flutter application, React operations portal, NestJS API, PostgreSQL/Prisma persistence, Redis-ready realtime/job infrastructure, and provisioned Prometheus/Grafana monitoring. It is not affiliated with any existing payment provider.

See [`ARCHITECTURE.md`](ARCHITECTURE.md), [`DATABASE.md`](DATABASE.md), [`DEPLOYMENT.md`](DEPLOYMENT.md), and [`API.md`](API.md). Copy `.env.example` to an ignored `.env`, replace all placeholders, then follow `DEPLOYMENT.md`.

## Implemented transaction operations

| Operation | Type |
|---|---:|
| Balance Inquiry | 702 |
| Name Inquiry | 651 |
| W2C (Bank Push) | 785 |
| C2W (Bank Pull) | 781 |
| P2P (Card to Card) | 689 |
| Purchase | 774 |
| Bill Info | 511 |
| Save Payment | 508 |
| Cash-In | 618 |
| Cash-Out | 700 |

Every flow includes validation, a unique idempotency key, typed request payload, mock asynchronous processing, and a receipt. `MockPaymentGateway` intentionally moves no money.

## Run

```bash
flutter pub get
flutter run
```

## Production work still required

- Regulated EMI/core-banking gateway and signed API contracts
- OAuth/device binding, certificate pinning and hardware-backed secret storage
- PCI DSS card-tokenization provider; never store PAN/CVV in this app
- KYC, liveness, AML, sanctions/PEP checks and transaction monitoring
- Double-entry ledger, reconciliation, settlement and reversal handling
- Provider adapters for banks, telecoms, billers, agents and merchants
- Fees, limits, dispute workflow, audit logs, notifications and observability
- Dari/Pashto translation files, accessibility review and legal approval
- Security assessment, penetration test and app-store release hardening

## Web administration portal

A separate React + TypeScript operations portal is in [`admin-portal/`](admin-portal/).
See [`ADMIN_PORTAL.md`](ADMIN_PORTAL.md) for setup, architecture, API/backend
requirements, security notes, and current integration limitations. The portal
includes a documented API contract and monitoring views, but no Admin API
server exists yet, so live customer/financial data and authentication remain
disabled. See [`MONITORING.md`](MONITORING.md) for environment discovery and
[`SECURITY.md`](SECURITY.md) for deployment gates.
