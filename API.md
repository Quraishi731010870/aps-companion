# API

Swagger is generated from the NestJS controllers at `/api/docs` outside production. APIs are versioned under `/api/v1`; browser-compatible admin authentication remains under `/api/admin/v1/auth`.

Implemented resources include authentication, dashboard summary/statistics/activity, users, customers, transactions, notifications, configuration, feature flags, audit logs, monitoring, alerts, reports, health, metrics, and public mobile configuration.

Errors follow this shape:

```json
{"success":false,"code":"ERROR_CODE","message":"Safe message","requestId":"uuid","timestamp":"ISO-8601"}
```

List endpoints use server-side pagination with a bounded page size. Transaction and customer searching/filtering is executed in PostgreSQL rather than loading entire tables into the browser.

## Cards (mobile customers)

Card numbers are never sent or stored in clear. See `backend/src/cards/card-envelope.ts`.

| Method | Path | Purpose |
|---|---|---|
| GET | `/api/v1/cards/encryption-key` | RSA-OAEP-256 public key as a JWK; `kid` is its RFC 7638 thumbprint (pinned by the app) |
| POST | `/api/v1/cards` | `{ encryptedCard }` → vaults the card, returns `{ token, maskedPan, expiryMonth, expiryYear, holderName }` |
| GET | `/api/v1/cards` | The caller's saved cards (masked) |
| DELETE | `/api/v1/cards/:token` | Revoke a saved card |

`POST /api/v1/transactions` accepts `cardToken` (saved card) or `encryptedCard` (one-off card) and records only the masked number. A raw card number in `source` returns `400 CARD_NUMBER_NOT_ENCRYPTED`. Card endpoints return `503 CARD_ENCRYPTION_NOT_CONFIGURED` until `CARD_ENCRYPTION_PRIVATE_KEY` and `CARD_VAULT_KEY` are set.
