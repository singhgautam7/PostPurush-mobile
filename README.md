# PostPurush for Android

A local-first API client for Android. Compose a request, send it, read the response, and
keep what worked in collections you own.

PostPurush is the native Android version of the PostPurush web client, rebuilt in Flutter
for Material 3 Expressive. It is a member of an app family whose shared rule is that your
data stays on your device.

## What it does

- **Compose and send.** All ten HTTP methods, query parameters, headers, JSON, form and raw
  bodies, bearer, basic and API-key auth, a configurable timeout, and cancellation.
- **Environments.** Sets of `{{variable}}` values for each stage of your work, with secrets
  masked and kept out of exports. The active environment fills variables in at send time.
- **Collections.** Folders and subfolders of saved requests, reorderable, searchable.
- **Response viewer.** Colour-coded status with its reason phrase, syntax-highlighted JSON
  that folds node by node, headers and cookies, and a copy button.
- **Explore.** A bundled, offline catalogue of public APIs. Browse, search and filter, then
  open one as a request. Native requests are not subject to CORS, so everything in it is
  callable.
- **Code export.** cURL, JavaScript, Python, Go, Java and PHP from the request in front of
  you, with variables resolved and secrets masked by default.
- **Analytics.** Totals, success rate, average and P95 response time, status-code
  distribution and per-collection breakdowns, worked out from your own local history.
- **Testing.** Assertions on one response (status, time, headers, body, JSON path) and load
  tests with a concurrency and a stop condition, reporting throughput and latency
  percentiles.
- **API docs.** A readable document generated from a collection, exportable as a PDF.
- **History.** Every send, reopenable exactly as it went out, kept on the device for as long
  as you choose.

## Privacy

No account. No sync. No analytics, crash reporting, ads or telemetry of any kind. The only
traffic that leaves your phone is the API requests you press Send on, plus opening a
documentation link in your browser if you ask for one. See [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

PostPurush declares the `INTERNET` permission, because sending HTTP requests is the whole
point of it. Nothing else is requested.

## Build

Requires Flutter stable (3.47 or newer) and the Android SDK.

```bash
flutter pub get
dart run build_runner build
flutter run
```

Release:

```bash
flutter build apk --release --target-platform android-arm64
```

## Repository layout

```
lib/core/theme/      the token layer: one OKLCh source, one cached ThemeData per theme
lib/core/db/         Drift schema and the repositories over it
lib/core/http/       the dio client, the request builder, the variable resolver,
                     code export, the cURL parser, assertions, the load tester
lib/core/models/     immutable models (freezed), each carrying a schema version
lib/core/widgets/    the shared design system every feature draws from
lib/features/        one folder per feature
```

`CLAUDE.md` holds the engineering contract: the network exception, the data rules, the theme
rules and the shared-component rule.

## Licence

Not yet chosen.
