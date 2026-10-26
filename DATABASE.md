# Database

The single PostgreSQL database is intentionally named `afghanpay`; a separate `afghan_emi_admin` database is not used. Its Prisma schema is `backend/prisma/schema.prisma`, with reproducible SQL migrations under `backend/prisma/migrations/`.

Core tables cover identities, customers, RBAC, sessions, devices, accounts, transaction types, transactions, immutable transaction events, configuration, feature flags, dynamic content, notifications and deliveries, append-oriented audit events, login/security events, monitoring checks, and alerts. Reports are computed from authoritative records instead of duplicated into a stale report table. Monetary values use `Decimal(20,2)` and store currency explicitly.

Apply reviewed migrations with `npm run migration` (or `npm run prisma:migrate`). Seed with `npm run seed`. `npm run db:reset:dev` is development-only and must never run in production.

The seed is synthetic. It creates 30 customers, accounts, seven administrator roles, granular permissions, all ten configured transaction types, at least 500 time-distributed transactions, settings, feature flags, a notification, an alert, and an audit record.

```bash
cd backend
NODE_ENV=development SEED_ADMIN_PASSWORD='your-local-password' npm run prisma:seed
```

The development administrator is `admin@afghanpay.test`. Its password is supplied at runtime and is not stored in Git.

Production requires encrypted backups, tested restores, retention policy, connection pooling, access separation, and an approved disaster-recovery plan.
