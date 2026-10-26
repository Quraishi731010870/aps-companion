# AfghanPay backend

The executable NestJS/TypeScript backend uses Prisma/PostgreSQL, Redis, JWT mobile sessions, secure cookie/CSRF admin sessions, backend-enforced RBAC, versioned REST APIs, Socket.IO events, Swagger, health probes, and Prometheus metrics.

```bash
npm ci
npx prisma generate
npm run build
npm test
```

Use Node.js 18.19 or newer. Copy `.env.example` to `.env` only for local development and provide secrets locally. Apply schema changes through reviewed Prisma migrations. Run the synthetic seed only outside production and provide `SEED_ADMIN_PASSWORD` at runtime.

## Crash ISO 8583 gateway

The `ISO 8583`, `ISO CP`, and `ISO Reversal` Swagger groups mirror the Crash
ISO UAT contract through authenticated `/api/v1/iso/**` endpoints. Set
`ISO_API_BASE_URL=http://10.60.76.71:9005` for the supplied UAT server and
restart the backend. The Afghan EMI API applies authorization, validation,
timeouts, and safe upstream error handling before forwarding each request.

PAN, CVV, OTP, PIN/PIN block, expiry, and track-2 properties are write-only in
OpenAPI. They are not logged, audited, or stored by this gateway. Never use real
cardholder data outside an approved PCI-controlled environment. Production
refuses a plaintext HTTP processor URL and requires HTTPS.

`/api/v1/iso8583/validate` and `/api/v1/iso8583/simulate` are safe development
tools. Simulation is disabled in production and persists only non-sensitive
transaction metadata and status events.

The Apps Script code in `apps_script/` remains an isolated legacy prototype and is not authoritative.

## Legacy Apps Script setup

This app uses the Apps Script web app in `apps_script/` to access the private
`Afghan EMI Database` spreadsheet as the deploying Google account. Phone users
do not sign in to Google.

## Deploy

1. Open the `Afghan EMI Database` spreadsheet with the account that owns it.
2. Select **Extensions → Apps Script**.
3. Replace the editor's `Code.gs` with `apps_script/Code.gs`.
4. In **Project Settings**, enable **Show "appsscript.json" manifest file**,
   then replace the manifest contents with `apps_script/appsscript.json`.
5. Save. Select `authorizeSpreadsheetAccess` and click **Run** once; approve
   the requested Sheets access as the spreadsheet owner.
   In **Project Settings → Script Properties**, set `SPREADSHEET_ID` and a new
   random `SERVICE_TOKEN`. Do not reuse any token previously present in source.
6. Choose **Deploy → New deployment → Web app**.
   - Execute as: **Me**
   - Who has access: **Anyone** (anonymous access)
7. Deploy, then copy the Web app URL ending in `/exec`.

The deployment runs with the owner's Sheet access. Keep the spreadsheet private.
The endpoint only exposes list and append operations for the `Users` worksheet.
The Apps Script reads `SERVICE_TOKEN` and `SPREADSHEET_ID` from Script
Properties. The mobile client sends its build-time token to this prototype
service; any token compiled into an APK can be extracted. Use this only for
trusted testing, rotate any previously exposed token, and do not use this design
for production or admin access. Production requires an identity-aware backend
that authorizes each user server-side.

## Configure/build Flutter

From the project root, create a local-only Dart-defines file from the example:

```sh
cp dart_defines.example.json dart_defines.local.json
# Edit dart_defines.local.json with the real /exec URL and a NEW test token.
flutter build apk --debug --dart-define-from-file=dart_defines.local.json
```

`dart_defines.local.json` is ignored by Git. Both
`GOOGLE_SHEETS_SERVICE_URL` and `GOOGLE_SHEETS_SERVICE_TOKEN` are required.
The URL must be the deployed HTTPS `/exec` URL and the token must match the
Apps Script `SERVICE_TOKEN` property. These values are compiled into the APK;
the token is therefore extractable and this is not production authentication.
Never reuse or commit credentials. The Profile → Google Sheets view accesses
only this `Users` service. The separate `google_sheets/` transaction prototype
uses a different API contract and has sample/test-only behavior.
