# API

Swagger is generated from the NestJS controllers at `/api/docs` outside production. APIs are versioned under `/api/v1`; browser-compatible admin authentication remains under `/api/admin/v1/auth`.

Implemented resources include authentication, dashboard summary/statistics/activity, users, customers, transactions, notifications, configuration, feature flags, audit logs, monitoring, alerts, reports, health, metrics, and public mobile configuration.

Errors follow this shape:

```json
{"success":false,"code":"ERROR_CODE","message":"Safe message","requestId":"uuid","timestamp":"ISO-8601"}
```

List endpoints use server-side pagination with a bounded page size. Transaction and customer searching/filtering is executed in PostgreSQL rather than loading entire tables into the browser.
