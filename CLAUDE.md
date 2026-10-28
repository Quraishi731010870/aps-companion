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

## Engineering principles (apply to every change)

- **MVVM:** View = widgets in `screens/` and `widgets/` (render state, forward user
  input, nothing else). ViewModel = Riverpod `Notifier`/`AsyncNotifier` in `state/`.
  Model = `domain/` (entities, rules) plus `repositories/`, `data/` and `network/`.
  Views talk only to ViewModels; ViewModels reach data only through providers.
- **DRY / reuse first:** before writing a widget, helper, formatter, provider or model,
  search for an existing one and reuse or extend it. Shared UI goes in `widgets/`
  (e.g. `ActivityTile`, `LoadingView`, `ErrorRetryView`); shared rules go in `domain/`
  (e.g. `CardNumber`, `TransactionLimits`, `IdempotencyKey`).
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

## Project structure (`lib/src/`)

| Folder | Holds |
|---|---|
| `config/` | `AppEnvironment` (the only place `--dart-define` values are read) and its provider. |
| `domain/` | Immutable models and enums (`PaymentOperation`, `PaymentRequest`, `WalletActivity`). No Flutter widgets, no I/O, no Riverpod. |
| `data/` | `PaymentGateway` implementations (`BackendPaymentGateway`, `MockPaymentGateway`, `GoogleSheetsGateway`) and the provider that exposes them. |
| `network/` | `ApiClient` (HTTP + token refresh), `ConfigSyncService` (Socket.IO `/realtime`) and their providers. |
| `repositories/` | Data access with caching (`ConfigRepository`) and their providers. |
| `state/` | Riverpod `Notifier` / `AsyncNotifier` classes: app-wide and feature state. One file per concern. |
| `screens/` | One file per full-page screen, named `*_screen.dart`. |
| `widgets/` | Reusable widgets and sheets shared across screens. |
| `l10n/` | `context.tr()` English → Dari translations. |

Data flows one way: **widget → notifier (state/) → repository / gateway → ApiClient**.
Widgets never skip a layer.

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
| Provider | Layer | Purpose |
|---|---|---|
| `appEnvironmentProvider` | config | Build-time `--dart-define` values; override in tests |
| `apiClientProvider`, `configSyncServiceProvider` | network | HTTP client and live config socket |
| `configRepositoryProvider` | repositories | Remote config with offline cache |
| `paymentGatewayProvider` | data | Chooses backend / Sheets / mock gateway |
| `biometricAuthenticatorProvider` | data | Platform biometric check |
| `settingsProvider` | state | Language, biometric flag, transaction limits |
| `mobileConfigProvider`, `currentConfigProvider`, `enabledOperationsProvider` | state | Remote config and the feature-flagged operation list |
| `linkedCardProvider` | state | Masked linked-card label |
| `activitiesProvider` | state | Wallet history (invalidated after each payment) |
| `paymentSubmissionProvider` | state | Submits a payment; double-tap guard; reuses the idempotency key on retry |

`context.tr()` reads the locale from `Localizations`, so it needs no provider.

---

## Flutter best practices

### Widgets and UI
- Prefer `StatelessWidget` / `ConsumerWidget`; reach for a stateful widget only for local UI
  state (controllers, animation, focus, form fields).
- Use `const` constructors and `const` widgets everywhere possible.
- Keep `build` methods small: split into private widget classes (`_BalanceCard`), not helper
  methods that return widgets. Promote them to `widgets/` when a second screen needs them.
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
  typed models at the boundary (`data/`, `repositories/`).
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
- Auth tokens live only in `flutter_secure_storage`; SharedPreferences is for non-sensitive
  cached config only. Never put tokens or card data in provider state that gets logged.
- Never store, log or display a full card PAN or CVV. Show masked values (`•••• 1087`).
- Errors shown to users stay generic (see `ApiException`); don't surface raw server bodies.
- Read `SECURITY.md` before touching auth, Google Sheets or ISO 8583 code.

## Testing
- Tests live in `test/`, mirror `lib/src/` paths, and are named `<feature>_test.dart`.
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
