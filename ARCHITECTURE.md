# AfghanPay architecture

AfghanPay preserves the existing Flutter client and React operations portal and places an authoritative NestJS API between clients and data stores.

```text
Flutter app ─┐
             ├─ HTTPS REST / Socket.IO ─ NestJS API ─ PostgreSQL
React admin ─┘                              │          Redis / job infrastructure
                                           └─ /metrics ─ Prometheus ─ Grafana
```

The API uses validated DTOs at the transport boundary, application services for orchestration, domain rules for transaction transitions, and Prisma for persistence. PostgreSQL is authoritative. Redis supports cache, events, and background-job infrastructure; it is never the financial system of record.

Mobile authentication uses short-lived JWT access tokens and persisted refresh-token hashes. The admin portal uses an HttpOnly cookie plus double-submit CSRF protection. Backend guards enforce permissions; frontend gates only control presentation.

Configuration updates and audit records are written in one PostgreSQL transaction. After commit, only public configuration metadata is emitted through the `/realtime` Socket.IO namespace. Flutter retains a last-known-good public configuration in platform preferences and keeps authentication tokens in secure storage.

Google Sheets and Apps Script remain isolated prototype integrations. They are not used by the new backend, PostgreSQL database, authentication, admin portal, or metrics stack and should be removed only after migration verification.
