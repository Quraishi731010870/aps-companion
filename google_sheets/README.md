# PayAfghan Google Sheets database

The Flutter app reads and writes transactions through a Google Apps Script web
API backed by one spreadsheet. The workbook schema includes Transactions,
Users, Cards, Bills, Limits, Settings, Institutions, Notifications, and AuditLog.

1. Create a Google Sheet named `PayAfghan Database`.
2. Open Extensions → Apps Script and paste `Code.gs`.
3. Run `setupDatabase()` once and approve access.
4. In Apps Script Project Settings → Script Properties, add `API_KEY` with a
   long random test value.
5. Deploy → New deployment → Web app. Execute as yourself and allow access to
   intended test users. Copy the `/exec` URL.
6. Build the app:

```sh
flutter build apk --release \
  --dart-define=GOOGLE_SHEETS_API_URL=https://script.google.com/macros/s/DEPLOYMENT_ID/exec \
  --dart-define=GOOGLE_SHEETS_API_KEY=YOUR_TEST_KEY
```

This architecture is for prototyping only. Do not use Google Sheets as the
production ledger or store PANs, PINs, passwords, CVVs, biometric data, or other
sensitive authentication data. The sheet stores only masked card identifiers.
