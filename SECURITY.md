# Security status and deployment gates

## Current gates

The React portal uses the authenticated NestJS administrator service in
`backend/src`. Its fetch adapter uses HTTPS (except loopback development),
credentialed cookies, a CSRF header for mutation requests, request timeouts,
generic network/server errors, and clears cached portal state when a session is
unauthorized or expires. The backend implements environment-aware secure
cookies, CSRF validation, temporary login lockout, server-enforced RBAC,
validation, exact-origin CORS, persisted audits, Argon2id hashes, refresh-token
rotation, and database-backed session revocation. Distributed rate limiting,
MFA/SSO, password recovery, and an external security assessment remain
production gates. UI gates do not replace API authorization.

Mobile requests are device-bound: the app signs each request (method, path,
timestamp, nonce, body hash) with a per-installation Ed25519 key registered at
login, and the backend verifies it, rejects replays and stale timestamps, and
records the signing device on each transaction (see `API.md`). The key is
software-generated and kept in the Keychain / Keystore-wrapped storage, not in
the Secure Enclave or StrongBox, neither of which supports Ed25519. There is
no attestation or new-device cooling period yet.

The Google Apps Script / Sheets pathways are prototype-only and are not used by
the portal. Do not attach them to administrator sign-in or any financial
operation. No supported transaction-mutation endpoint was found.

## Exposed prototype token

The previously source-embedded shared token default was removed from active
source; the prior value remains in Git history and is not restated here. Treat
it as compromised: revoke and rotate it in the deployed Apps Script project.
Do not paste it into issues, chat, source, or replacement config. Repository
history has not been rewritten; this update does not remove the old value from
past commits. The history scan identified the old credential-bearing versions in
`backend/apps_script/Code.gs` and `lib/services/google_sheets_service.dart`;
the scan reported paths only, not credential values.

## Dependencies

The portal uses patched React Router 7, Vite 7, and Vitest 4 versions, which
require a current Node.js 20/22 runtime. Tests, lint, and builds passed under
Node.js 22.13; `npm audit` reports zero vulnerabilities. Re-run the full audit
for the deployment lockfile and runtime before release.

## Deployment checklist

* HTTPS-only portal/API with same-origin reverse proxy where possible.
* Secure, HttpOnly, SameSite cookie; server-revocable opaque sessions; CSRF
  defense; short idle/absolute expiry; no tokens in web storage.
* Exact-origin CORS; restrictive CSP, frame-ancestors, HSTS, and other security
  headers; no public Grafana embedding.
* Server-side role/permission checks, account lockout/rate limiting, MFA/SSO
  decision, password reset verification, and protected admin bootstrap.
* Strict schema validation, allow-listed sorting/filtering, parameterized SQL,
  bounded pagination and upstream timeouts, safe errors, and audit events.
* Never log credentials, cookies, access tokens, PINs, PAN/CVV, or secret
  request/response bodies. Mask customer identifiers according to policy.
* Rotate the exposed Apps Script token; separately coordinate any history
  remediation with repository owners.
* Security review and penetration test before production data access.
