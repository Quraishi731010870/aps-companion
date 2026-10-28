# CLAUDE.md

AfghanPay / PayAfghan: an Afghanistan-focused EMI wallet prototype. This repo holds the
Flutter app (`lib/`), a React admin portal (`admin-portal/`), a NestJS + Prisma API
(`backend/`), and Prometheus/Grafana monitoring. These rules cover the **Flutter app**.
See `ARCHITECTURE.md`, `API.md`, `DEPLOYMENT.md` and `SECURITY.md` for the rest.

## Commands

```bash
flutter pub get
flutter run                                                     # mock gateway, no backend
flutter run --dart-define-from-file=dart_defines.local.json     # real API (file is git-ignored)
flutter run -d web-server --web-port 8090                       # quick browser check
dart run build_runner watch                                     # regenerate Riverpod *.g.dart files
flutter analyze                                                 # must be clean
dart format lib test                                            # must produce no changes
flutter test
```

Android emulator reaches the local API at `http://10.0.2.2:8081`; browser/desktop use
`http://localhost:8081`; the iOS simulator also uses `http://localhost:8081`.

### Testing against the local backend (test user)

There is no sign-in screen yet. Debug builds sign in automatically as the seeded test
user (**Demo Customer 001**) when `dart_defines.local.json` (git-ignored) contains:

```json
{
  "API_BASE_URL": "http://localhost:8081",
  "TEST_USER_PHONE": "<SEED_MOBILE_PHONE from .env>",
  "TEST_USER_PASSWORD": "<SEED_MOBILE_PASSWORD from .env>"
}
```

1. `docker compose up -d postgres redis backend` (seed once; see `DEPLOYMENT.md`).
2. `flutter run --dart-define-from-file=dart_defines.local.json`
   (web: add `-d web-server --web-port 8090`; that origin is allowed in `docker-compose.yml`).
   In VS Code, pick **aps-companion (local backend)** or **(local backend, web :8090)** from
   Run and Debug; `.vscode/launch.json` (git-ignored, per developer) passes the same flag.
   **(offline mock)** runs with no defines and the mock gateway.

Release builds ignore `TEST_USER_*` even if passed. Sign-in is never retried
automatically: 5 wrong passwords lock the account for 15 minutes. Payments stay
`PENDING` because no processor runs locally.

## Engineering principles (apply to every change)

- **MVVM:** View = `presentation/views/` and `presentation/widgets/` (render state,
  forward user input, nothing else). ViewModel = Riverpod `Notifier`/`AsyncNotifier` in
  `presentation/view_models/`. Model = `domain/` (entities, rules) plus `data/`.
  Views talk only to ViewModels; ViewModels reach data only through providers.
- **DRY / reuse first:** before writing a widget, helper, formatter, provider or model,
  search for an existing one and reuse or extend it. Code used by two or more features
  goes in `core/` (e.g. `LoadingView`, `ErrorRetryView`, `afn()`); a feature's own
  reusable pieces stay in that feature (e.g. `CardNumber`, `IdempotencyKey` in payments).
- **SOLID:** one responsibility per class and file; depend on abstractions
  (`PaymentGateway`, `BiometricAuthenticator`) injected through providers; add new
  behaviour by adding an implementation, not by editing callers.
- **Separation of concerns:** no HTTP, storage or platform plugins in widgets; no
  `BuildContext` in ViewModels; `domain/` has no Riverpod and no I/O.
- **No memory leaks:** every controller, `FocusNode`, subscription, `Timer`, socket and
  `http.Client` is disposed by its owner (`State.dispose` or `ref.onDispose`). Dialogs and
  sheets that need controllers are their own `StatefulWidget` so the controllers live
  exactly as long as the route.
- **Smoothness:** `const` widgets, `select` for narrow rebuilds, lazy lists
  (`ListView.builder` / `SliverList`), nothing heavy in `build` or on the UI isolate.

## Project structure (feature-first)

```text
lib/
  main.dart                    ProviderScope + app entry
  src/
    app.dart                   MaterialApp, theme, maintenance gate
    shell/                     MainShell (bottom navigation)
    core/                      shared by every feature; never imports features/
      config/                  AppEnvironment (only place --dart-define is read)
      network/                 ApiClient
      storage/                 SecureStore (flutter_secure_storage wrapper, SecureKey)
      remote_config/
        data/                  ConfigRepository, ConfigSyncService (socket)
        state/                 MobileConfig, currentConfig
      formatting/              afn() and other display formatters
      l10n/                    context.tr() English → Dari
      widgets/                 LoadingView, ErrorRetryView
    features/
      <feature>/
        domain/                entities, value objects, rules (no Flutter UI, no I/O, no Riverpod)
        data/                  gateways, services, repositories + their providers
        presentation/
          view_models/         Riverpod Notifier / AsyncNotifier (ViewModels)
          views/               full screens, sheets, dialogs (*_screen.dart)
          widgets/             widgets reused inside the feature
```

| Feature | Owns |
|---|---|
| `auth` | `SessionStatus`, `UserProfile`, `AuthRepository` (login, secure token + profile storage, sign-out), `Session` and current-user view models, `SessionGate` |
| `payments` | `PaymentOperation`/`PaymentRequest`/`PaymentResult`, `PaymentGateway` + backend/mock/Sheets gateways, idempotency keys, card numbers, payment flow, card linking, QR scanner, receipt |
| `activity` | Wallet history, CSV export, `ActivityTile` |
| `home` | Home dashboard |
| `services` | Services catalogue |
| `profile` | Profile, wallet identity and QR, security (PIN/password) |
| `settings` | `AppSettings`/`TransactionLimits`, biometrics, limits screen |
| `admin` | Prototype-only tools: management/ISO console, Google Sheets |

Rules:
- A new feature gets its own `features/<name>/` folder with only the sub-folders it needs.
- Features may import another feature's `domain/` and providers, but never its
  `data/` implementations directly — go through the provider.
- `core/` must not import from `features/`.
- Folder names are `snake_case`; files keep the `*_screen.dart` suffix for full screens.

Data flows one way: **view → view model → repository / gateway → ApiClient**.
Views never skip a layer.

---

## State management: Riverpod

Riverpod is the only state-management solution for this app. Don't add Provider, Bloc,
GetX, MobX or new `ChangeNotifier`/`InheritedWidget` state.

### Setup
- Packages: `flutter_riverpod`, `riverpod_annotation`; dev: `riverpod_generator`,
  `build_runner`. `riverpod_lint` runs as an analyzer plugin declared under `plugins:`
  in `analysis_options.yaml` (not a pubspec dependency; `custom_lint` is incompatible
  with the current generator).
- `main.dart` wraps the app in `ProviderScope`; nothing else creates a root container.
- Write providers with code generation (`@riverpod` / `@Riverpod(keepAlive: true)`) and add
  `part 'file_name.g.dart';`. Commit the generated `*.g.dart` files.
- Don't use the legacy APIs: `StateProvider`, `StateNotifierProvider`, `ChangeNotifierProvider`.

### Choosing a provider
| Need | Use |
|---|---|
| A dependency/service (`ApiClient`, `PaymentGateway`, `ConfigRepository`) | `@Riverpod(keepAlive: true)` function provider |
| A computed value derived from other providers | `@riverpod` function provider |
| A one-off async read (e.g. activity list) | `@riverpod Future<T>` function provider |
| State that changes through user actions | `@riverpod class X extends _$X` (`Notifier`) |
| Async state that changes through user actions | `@riverpod class X extends _$X` with `Future<T> build()` (`AsyncNotifier`) |
| Live stream (config sync, socket events) | `@riverpod Stream<T>` |
| Per-item state (a transaction by id) | Provider with parameters (family), e.g. `transactionProvider(id)` |

- Generated providers are `autoDispose` by default. Use `keepAlive: true` only for app-lifetime
  state: settings, session, configuration, services.
- Build-time config (`String.fromEnvironment`) is read once and exposed through a provider;
  e.g. `paymentGatewayProvider` returns backend, Sheets, or mock based on `API_BASE_URL`.

### Using providers in widgets
- Use `ConsumerWidget` / `ConsumerStatefulWidget` (or a `Consumer` around a small subtree).
- `ref.watch` inside `build` only. `ref.read` inside callbacks (`onPressed`) only.
- `ref.listen` for side effects: snackbars, dialogs, navigation. Never trigger them in `build`.
- Watch the narrowest thing you need: `ref.watch(appSettingsProvider.select((s) => s.locale))`.
- Render every `AsyncValue` fully: loading, error **and** data, using a `switch` or `.when`.
  Never call `.value!` or `.requireValue` in UI code.
- Refresh with `ref.invalidate(provider)` or `ref.refresh(provider.future)` (pull-to-refresh).

### Writing notifiers
- State is immutable: `final` fields, `const` constructors, `copyWith`, and value equality.
  Replace `state`; never mutate lists or objects in place.
- Business rules live in notifiers or the domain layer, never in widgets.
- Notifiers don't take or hold a `BuildContext`, and don't show UI.
- Mutations that can fail set `state = AsyncError(...)` or use `AsyncValue.guard(...)`;
  keep the previous data visible while reloading.
- After every `await`, check `if (!ref.mounted) return;` before touching `state`.
- Clean up timers, sockets and subscriptions with `ref.onDispose`.
- Providers depend on each other through `ref.watch` in `build`; never pass a `ref` around
  or store it in a long-lived object.

### Existing providers (reuse these)
| Provider | Location | Purpose |
|---|---|---|
| `appEnvironmentProvider` | `core/config` | Build-time `--dart-define` values; override in tests |
| `apiClientProvider` | `core/network` | HTTP client with token refresh |
| `secureStoreProvider` | `core/storage` | Encrypted storage for tokens and the user profile |
| `configRepositoryProvider`, `configSyncServiceProvider` | `core/remote_config/data` | Remote config with offline cache; live config socket |
| `mobileConfigProvider`, `currentConfigProvider` | `core/remote_config/state` | Remote config (flags, maintenance mode), previous value kept while reloading |
| `cardVaultProvider` | `features/payments/data` | Backend card vault (encrypt, vault, pinned key) or offline mock |
| `enabledOperationsProvider` | `features/payments/presentation/view_models` | Payment operations allowed by remote feature flags |
| `paymentGatewayProvider` | `features/payments/data` | Chooses backend / Sheets / mock gateway |
| `paymentSubmissionProvider` | `features/payments/presentation/view_models` | Submits a payment; double-tap guard; reuses the idempotency key on retry |
| `linkedCardProvider` | `features/payments/presentation/view_models` | Linked `SavedCard` (vault token + masked number), persisted in secure storage |
| `activitiesProvider` | `features/activity/presentation/view_models` | Wallet history (invalidated after each payment) |
| `biometricAuthenticatorProvider` | `features/settings/data` | Platform biometric check |
| `settingsProvider` | `features/settings/presentation/view_models` | Language, biometric flag, transaction limits |
| `authRepositoryProvider` | `features/auth/data` | Mobile login; stores tokens via `ApiClient` |
| `currentUserProvider`, `displayedUserProvider` | `features/auth/presentation/view_models` | Signed-in `UserProfile` from secure storage; UI falls back to the demo user offline |
| `sessionProvider` | `features/auth/presentation/view_models` | Signed in / out; auto-signs in the test user in debug builds; no auto-retry |

`context.tr()` reads the locale from `Localizations`, so it needs no provider.

---

## Flutter best practices

### Widgets and UI
- Prefer `StatelessWidget` / `ConsumerWidget`; reach for a stateful widget only for local UI
  state (controllers, animation, focus, form fields).
- Use `const` constructors and `const` widgets everywhere possible.
- Keep `build` methods small: split into private widget classes (`_BalanceCard`), not helper
  methods that return widgets. Promote them to the feature's `presentation/widgets/` when a
  second screen needs them, or to `core/widgets/` when a second feature does.
- `build` must be side-effect free: no network calls, no state writes, no navigation.
- Dispose every `TextEditingController`, `AnimationController`, `FocusNode`, `ScrollController`
  and subscription in `dispose()`.
- After an `await` in a widget, check `if (!context.mounted) return;` before using `context`.
- Use Material 3 and the theme in `app.dart` (seed colour `0xff087f67`). Read colours and
  text styles from `Theme.of(context)`; never hard-code new colours or font sizes.
- Wrap screen bodies in `SafeArea`; use `LayoutBuilder` / `MediaQuery.sizeOf` for responsive
  layouts and constrain wide screens (e.g. `maxWidth: 440`).
- Long or dynamic lists use `ListView.builder` / `SliverList`, never a `Column` of all items.

### Localization and accessibility
- Every user-visible string goes through `context.tr('English text')`, with its Dari entry
  added to `_dari` in `l10n/app_localizations.dart`.
- Layouts must work right-to-left (Dari): use `EdgeInsetsDirectional`, `AlignmentDirectional`
  and `start`/`end`, not `left`/`right`.
- Tap targets are at least 48×48. Icon-only buttons have a `tooltip` or `Semantics` label.
- Layouts must not overflow at 1.3× text scale.

### Dart code quality
- Sound null safety: avoid `!`; handle null explicitly. Avoid `dynamic`. Parse JSON into
  typed models at the boundary (each feature's `data/`, or `core/`).
- Use `sealed` classes, `switch` expressions, records and pattern matching where they make
  intent clearer, so the compiler checks every case.
- `final` by default; `const` where possible; private members start with `_`.
- Files `snake_case.dart`, types `UpperCamelCase`, members `lowerCamelCase`, providers
  `somethingProvider`.
- Relative imports inside `lib/`; tests import with `package:afghan_emi/...`.
- No `print`. Use `debugPrint` or `dart:developer` `log`, and never log tokens, PINs or card data.
- Comment only when the *why* isn't obvious; don't restate the code.
- `flutter analyze` (flutter_lints + riverpod_lint) passes with no warnings, and
  `dart format` produces no changes.

### Errors and networking
- All HTTP goes through `ApiClient`, with timeouts on every request.
- Catch errors at the repository/notifier layer and convert them to typed failures; widgets
  show a generic, translated message plus a retry action.
- The app must stay usable offline with cached configuration (`ConfigRepository`).

### Performance
- Avoid rebuilding large subtrees: watch narrow providers, use `select`, extract `const` widgets.
- Don't do heavy work (JSON parsing of big payloads, crypto) on the UI isolate; use `compute`/`Isolate.run`.
- Size and cache images; prefer `Image.asset` with `cacheWidth` for large assets.
- Profile with DevTools in `--profile` mode before optimizing.

---

## Payments and money
- Every transaction is a `PaymentOperation` enum value carrying its ISO code, label, icon,
  `requiresAmount` and `configurationKey`. Add new operations there, never as loose strings.
- Every `PaymentRequest` carries a unique `idempotencyKey` and an explicit currency (`AFN`).
  Guard submit buttons so a double tap can't send two requests.
- Map backend statuses to `TransactionState` in one place (the gateway); an unknown status
  defaults to `processing`, never `successful`.
- Any new gateway capability goes on the `PaymentGateway` interface **and** `MockPaymentGateway`,
  so the app always runs with no backend. The mock never moves money or calls the network.
- Gate operations behind remote feature flags (`configurationKey`, safe default `true`).

## Security
- Never commit secrets, tokens, credential-bearing URLs, `dart_defines.local.json` or `.env`.
- Tokens and the signed-in user live only in `SecureStore` (`core/storage/secure_store.dart`),
  the single wrapper around `flutter_secure_storage`. Add new secure values as a `SecureKey`
  entry; never call the plugin directly or write key strings elsewhere.
  SharedPreferences is for non-sensitive cached config only. Never put tokens or card data in
  provider state that gets logged.
  - iOS: Keychain `unlocked_this_device`, not synchronizable (no iCloud, no device migration).
    Keychain survives uninstall, so `SecureStore` wipes it on the first launch after install.
  - Android: Keystore-wrapped AES-GCM (`resetOnError`). `allowBackup="false"` plus
    `res/xml/data_extraction_rules.xml` keep app data out of backups and device transfers.
  - Store the minimum: `UserProfile` holds only id and display name; no phone, roles,
    permissions or passwords. Only `MOBILE_USER` accounts may sign in to the app.
  - Ending a session (`ApiClient.clearSession` / `AuthRepository.signOut`) clears every
    `SecureKey`, not just tokens.
- Never store, log or display a full card PAN or CVV. Show masked values
  (`CardNumber.masked` → `603799******1234`, displayed as `6037 99** **** 1234`).
- **Card data in transit** (`features/payments/data/card_encryptor.dart` ↔
  `backend/src/cards/card-envelope.ts`): a card number leaves the device only inside a
  `CardEnvelope` — AES-256-GCM over the card JSON with a fresh key and nonce per request, the
  key wrapped with the backend's RSA-OAEP-256 (3072-bit) public key, AAD bound to the key id,
  and a timestamp the backend checks (5-minute replay window). This is on top of TLS.
  - The app pins the backend key by its RFC 7638 thumbprint (`CARD_KEY_SHA256` define; the
    `kid` from `GET /api/v1/cards/encryption-key`). Release builds refuse cards without a pin.
  - Saved cards: `POST /api/v1/cards` vaults the card (AES-256-GCM at rest with
    `CARD_VAULT_KEY`, bound to the customer); the device keeps only the token and masked
    number (`SecureKey.linkedCard`). Pay with `cardToken`; one-off cards with `encryptedCard`.
  - The backend rejects a raw card number in `source` (`CARD_NUMBER_NOT_ENCRYPTED`) and stores
    only masked numbers in transactions.
  - Any change to the envelope must change both files and keep the shared RFC 7638 test
    vector passing on both sides.
- Errors shown to users stay generic (see `ApiException`); don't surface raw server bodies.
- Read `SECURITY.md` before touching auth, Google Sheets or ISO 8583 code.

## Testing
- Tests live in `test/`, mirror `lib/src/` paths (e.g. `test/features/payments/data/…`),
  and are named `<file>_test.dart`. Shared fakes and pump helpers are in
  `test/helpers/test_app.dart` (`pumpApp`, `pumpScreen`, `FakePaymentGateway`, `testConfig`).
- **Notifier/provider tests:** use `ProviderContainer.test(overrides: [...])`, override
  `paymentGatewayProvider` / `apiClientProvider` with fakes, and assert on state transitions
  (loading → data / error).
- **Widget tests:** pump the widget inside `ProviderScope(overrides: [...])` with fake
  dependencies; never hit the network. Find widgets by visible English text or `Key`.
- **Unit tests:** domain rules and `ApiClient` (inject a fake `http.Client` and storage).
- Every new notifier gets a unit test and every new screen/flow gets at least one widget test.
- Run `flutter analyze` and `flutter test` before saying a change is done.

## Git
- Branch off `main` for changes; don't commit directly to `main`.
- Don't commit `build/`, `.dart_tool/` or local config. Do commit generated `*.g.dart` files.
