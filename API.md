# API

Swagger is generated from the NestJS controllers at `/api/docs` outside production. APIs are versioned under `/api/v1`; browser-compatible admin authentication remains under `/api/admin/v1/auth`.

Implemented resources include authentication, dashboard summary/statistics/activity, users, customers, transactions, notifications, configuration, feature flags, audit logs, monitoring, alerts, reports, health, metrics, and public mobile configuration.

Errors follow this shape:

```json
{"success":false,"code":"ERROR_CODE","message":"Safe message","requestId":"uuid","timestamp":"ISO-8601"}
```

List endpoints use server-side pagination with a bounded page size. Transaction and customer searching/filtering is executed in PostgreSQL rather than loading entire tables into the browser.

## Cards (mobile customers)

Card numbers are never sent or stored in clear. See `backend/src/cards/card-envelope.ts`. Only the card number is vaulted: the expiry is checked when linking and then discarded, and an envelope carrying a CVV, PIN or track data is rejected (`INVALID_CARD`).

| Method | Path | Purpose |
|---|---|---|
| GET | `/api/v1/cards/encryption-key` | RSA-OAEP-256 public key as a JWK; `kid` is its RFC 7638 thumbprint (pinned by the app) |
| POST | `/api/v1/cards` | `{ encryptedCard }` → vaults the card number, returns `{ token, maskedPan, holderName }`. An expired card returns `400 CARD_EXPIRED` |
| GET | `/api/v1/cards` | The caller's saved cards (masked) |
| DELETE | `/api/v1/cards/:token` | Revoke a saved card |

`POST /api/v1/transactions` accepts `cardToken` (saved card) or `encryptedCard` (one-off card) and records only the masked number. A raw card number in `source` returns `400 CARD_NUMBER_NOT_ENCRYPTED`. Card endpoints return `503 CARD_ENCRYPTION_NOT_CONFIGURED` until `CARD_ENCRYPTION_PRIVATE_KEY` and `CARD_VAULT_KEY` are set.

## Wallet (mobile customers)

`GET /api/v1/wallet` returns the signed-in customer's active wallet: `{ walletId, currency, availableBalance }`. Returns `404 WALLET_NOT_FOUND` if there is none and `403` for admin sessions.

## Device signatures (mobile customers)

Every mobile customer request is signed with the Ed25519 key the app created for its installation. Format shared by `backend/src/devices/request-signature.ts` and `lib/src/core/security/request_signature.dart`.

| Header | Value |
|---|---|
| `X-Request-Timestamp` | Unix time in milliseconds; must be within 5 minutes of server time |
| `X-Request-Nonce` | 16–64 base64url characters; accepted once per device key (Redis) |
| `X-Device-Signature` | Ed25519 signature (base64url) over the canonical request below |

```text
AFGHANPAY-ED25519-V1\n<METHOD>\n<path?query as sent>\n<timestamp>\n<nonce>\n<sha256 hex of the raw body>
```

- `POST /api/v1/auth/login` takes `{ identifier, password, device: { installationId, platform, publicKey } }`, where `platform` is `ANDROID`, `IOS` or `WEB` and `publicKey` is the raw 32-byte Ed25519 key in base64url. The request must be signed with that key. Only `MOBILE_USER` accounts may sign in. The device is bound to the customer, and a known installation can't switch keys (`DEVICE_KEY_MISMATCH`).
- `POST /api/v1/auth/refresh` and every authenticated request must be signed by the device bound to the session. Admin cookie sessions aren't device-bound.
- Failures return `401` with `DEVICE_SIGNATURE_REQUIRED`, `DEVICE_SIGNATURE_INVALID`, `DEVICE_SIGNATURE_EXPIRED`, `DEVICE_SIGNATURE_REPLAYED`, `DEVICE_NOT_BOUND` or `DEVICE_KEY_MISMATCH`. Invalid signatures and key mismatches are recorded in `security_events`.
- Transactions store the signing `device_id` and `device_signature`.
