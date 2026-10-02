# PostPurush

PostPurush is a local-first API client for Android, built in Flutter. Compose a request,
send it, read the response, and keep what worked in folders you own. Everything lives
on the device: no account, no sync, no telemetry, and the only traffic that leaves the
phone is the requests you press Send on.

**Stack:** Flutter (stable, 3.47) · Riverpod · GoRouter · dio (the send engine) · Drift +
`sqlite3` (collections, folders, environments, history) · shared_preferences (device
settings, read synchronously at launch) · dynamic_color (Material You) · freezed +
json_serializable (immutable models, safe payloads) · pdf + printing (API docs export) ·
share_plus · url_launcher (docs links) · file_picker (import).
Package `com.grs.postpurush`, Android only.

**UI source of truth:** `specs/desgin/postpurush-android-design/project/PostPurush Android.dc.html`
(gitignored, on disk). Read it before building or changing any screen. Mull at
`/Users/gautam/Desktop/Projects/Personal/Mull` is the read-only reference for how Material
3 Expressive is executed here: where the board and Mull disagree on layout or intent, the
board wins; on execution (colour roles, motion curves, component styling, folder
conventions), Mull wins. Never modify Mull.

## THE NETWORK EXCEPTION

Unlike the rest of this app family, PostPurush has an HTTP client, and it is the product.
**dio is required and expected.** Read the rest of this section before assuming the family
rule applies.

PostPurush is still local-first:

- No accounts. No sign-in. No sync. No cloud backup of its own.
- No analytics, no crash reporting, no ads, no telemetry, no attribution SDK. Ever.
- The only outbound traffic is the API requests the user explicitly sends, plus OS
  handoffs: opening a documentation link in a browser, or handing text to the share sheet.
- Nothing about a request, a response, or a user is reported anywhere.

Do not inherit the family's "no HTTP client" rule. Do not relax anything else in this list.

## Commands

```bash
flutter run                                              # run on a device
flutter analyze                                          # lints must stay clean
flutter test                                             # unit + widget + golden tests
dart run build_runner build                              # freezed, json_serializable, drift
flutter build apk --release --target-platform android-arm64
dart run flutter_launcher_icons                          # launcher icon
dart run flutter_native_splash:create                    # splash
```

## Persistence decision

**Drift**, not Isar. Isar's v3 line has been effectively unmaintained since 2024 and v4
never shipped a stable release; Drift is actively maintained, is what Mull uses, and gives
migrations and a real query planner. `sqlite3` 3.x bundles SQLite through Dart hooks, so
`sqlite3_flutter_libs` is obsolete and must not be added.

Every table keeps its model as one JSON payload in a `data` column, alongside the few
columns a query actually filters or sorts on (`lib/core/db/app_db.dart`). That split is
deliberate:

- The payload carries its own `schemaVersion`, so a model gaining a field is a code change,
  not a database migration.
- The indexed columns are what Collections, Search, History and Analytics read, so none of
  them decodes a payload to draw a row or to group a statistic.
- A row written by a newer build is skipped on read rather than crashing a list. That is
  `decodeOrNull` / `decodeAll` in `lib/core/error/guard.dart`, and it is the only place
  that decision is made.

## Data rules

**D1. Variables are resolved at send time and nowhere else.** `{{name}}` is stored exactly
as typed, in the request, in history, and in an export. `RequestBuilder.build` fills them
in and the resolved strings never leave that call. A resolved value must never be written
to the database. A missing variable goes out as literal braces, so the server's error tells
the truth about what was sent.

**D2. Secrets stay masked by default.** A variable marked secret is masked in the UI, left
out of exports, and masked in a code snippet and a PDF unless the user turns the switch on
for that one sheet. `VariableResolver.mask` is the only masker.

**D3. Schema-version everything persisted.** `ApiRequest`, `Folder`, `Environment` and
`HistoryEntry` each carry `schemaVersion`. On read: migrate, or discard safely. Never crash.

**D4. Local, on-device only.** No accounts, no sync, no server of our own. History is
pruned to the retention setting once per launch, so the log cannot grow without bound.

**D5. A colour is never stored.** An environment's colour is an index into
`AppColors.catHues`; a method's colour is a hue on its enum. Both are re-derived per theme,
so they stay legible in light, dark and true black.

**D6. A 500 is a response, not an error.** `validateStatus` always returns true. Only DNS,
TLS, timeouts and cancellation are failures, and `ApiClient.send` never throws: it answers
with a named `FailureKind` and the dock shows it.

## Folder structure

```
lib/main.dart              bootstrap: prefs, database, ProviderScope
lib/app.dart               MaterialApp, theme resolution
lib/app/                   nav_bar (the pill) · nav_shell · transitions
lib/core/theme/            tokens · oklch · palette (AppColors, ThemeFamily) ·
                           typography · app_theme (the ThemeData cache)
lib/core/db/               app_db (Drift) · collections_repository ·
                           environments_repository · history_repository ·
                           app_state_repository
lib/core/http/             api_client (dio) · request_builder · variable_resolver ·
                           code_export · curl_parser · assertion_runner ·
                           load_tester · json_path
lib/core/models/           freezed models + http_method/body/auth/var enums
lib/core/routing/          routes (every path in one place)
lib/core/widgets/          THE SHARED DESIGN SYSTEM. See below.
lib/core/error/            guard (decodeOrNull / decodeAll)
lib/core/util/             ids · format (Fmt) · wallpaper_seed ·
                           platform_surfaces (the one MethodChannel)
lib/core/providers.dart    the provider graph
lib/features/              collections · workspace · explore · environments ·
                           history · analytics · testing · api_docs · more ·
                           settings · about
assets/data/               the bundled public-APIs catalogue
specs/                     the design board and performance.md (gitignored)
```

## Theme rules

- One token source: `lib/core/theme/`. A `ThemeFamily` derives every role in OKLCh into
  `AppColors`; `AppTheme` builds one **cached** `ThemeData` per (family, tone). A hex value
  or a magic size outside that layer is a bug.
- Read colours as `context.colors.<role>`, type as `AppType.<step>`, everything else from
  `Space`, `Radii`, `IconSpec`, `Motion`, `NavSpec`, `Elevations`.
- Eight families. The default, PostPurush, is the launcher icon's own green,
  `oklch(0.52 0.10 145)`, measured from the icon board's bowl: an app whose accent
  disagrees with its own icon looks like two products. The main board's original
  indigo at hue 272 is kept as the `indigo` family, alongside the six web presets,
  all numbers on the same formulas. True black ships for PostPurush, indigo and
  lithub-blue.
- **Theme caching.** Settings live in SharedPreferences and are read synchronously in
  `main`, before the first frame, so the default theme never flashes. `AppTheme.of` and
  `AppTheme.fromSeed` memoise by (family, tone) and by seed, so a theme switch is a map
  lookup, not a rebuild of every role. The wallpaper seed is read once through a
  `FutureProvider` and cached.
- Dynamic colour takes **one** wallpaper hue and derives the rest at chroma 0.11, so a
  wallpaper scheme sits in the same register as the bundled families. Fixed accents
  (methods, status bands, environment colours) are harmonised by being re-derived from the
  seven category hues against the active tone, never by being stored.
- Motion: spring for anything the finger caused, decelerate for anything the system caused.
  Honour reduced motion through `Motion.of` / `Motion.curveOf`.
- One typeface, Instrument Sans, bundled. Weights must move the `wght` axis (`AppType`
  does; `.weight(n)` for one-offs). Mono carries anything you would type.

## The common-component rule

`lib/core/widgets/` is the design system. Every feature consumes it. If you find yourself
copy-pasting a widget, extract it instead. There is one implementation of each of these:

| Need | Use |
|---|---|
| Screen top bar, pushed page | `AppHeader` + `CollapseOnScroll`, `PageScaffold` |
| Any icon action (with an unsaved dot) | `AppIconButton` |
| Button, add-row, the floating primary | `AppButton`, `AddRowButton`, `PrimaryActionButton` |
| Method chip, status chip, filter chip, segmented control, environment tile | `MethodChip`, `StatusChip`, `PillChip`, `SegmentedToggle`, `EnvTile` |
| Card, a run of hairline rows, one row, a stat figure | `AppCard`, `RowGroup`, `AppRow`, `StatCard` |
| Section header, sheet title | `SectionHeader`, `SheetTitle` |
| Bottom sheet, destructive confirm, save-or-discard | `showAppSheet`, `confirmDialog`, `askToSave` |
| Anchored menu | `showAppMenu` + `AppMenuEntry` |
| Undo strip and every toast | `AppSnackbar.info` / `.undo` / `.action` |
| A run of hairline rows too long to build at once | `SliverRowGroup` |
| The folder tree: children, contents, counts | `FolderIndex.of` |
| Empty, error, inline error, delayed loader, skeletons | `EmptyState`, `ErrorStateView`, `InlineError`, `Delayed`, `SkeletonLine`, `SkeletonRow` |
| `{{variable}}` highlighting, anywhere | `VariableText`, `VariableWellPainter`, `VariableEditingController` |
| URL bar, method picker | `UrlBar`, `MethodPicker` |
| Key/value rows (params, headers, form, variables) | `KeyValueEditor` |
| JSON viewer with folding, a short code block | `CodeView`, `CodeBlock` |
| Line chart, status distribution | `ChartCard` + `ChartSeries`, `StatusBreakdownCard` |
| Text field, search field, stepper, switch row | `LabelledField`, `SearchField`, `StepperRow`, `SwitchRow` |
| Dashed outline | `DashedBorderPainter` |

Two notes on deliberate non-dependencies, so nobody "fixes" them by adding a package:

- **No chart package.** The board's chart is three divider rules, one solid series with
  dots and one dashed comparison, with mono 9 axis labels and no fills. That is a
  `CustomPainter` (`LineChartPainter`), which is also Mull's house style and one fewer
  dependency.
- **No code-editor package.** The response viewer needs the board's own token roles,
  node folding with `{ 3 keys }` summaries, and `{{variable}}` highlighting inside string
  values. No off-the-shelf editor does that, so `JsonOutline` + `CodeView` do.

## Standing instructions

- Read the design board (path above) before any UI work.
- Mull at `/Users/gautam/Desktop/Projects/Personal/Mull` is the read-only M3E reference.
- Never break existing functionality when adding a feature.
- No new packages without stating the justification first.
- Run `dart run build_runner build` after any freezed, json_serializable or drift
  annotation change. Note: the bundled analyzer chokes on relational patterns
  (`>= 200 and < 300`) in a switch expression, so write those as if-chains.
- `flutter analyze` and `flutter test` must be clean before you call anything done.
- Edge-to-edge everywhere. Minimum touch target 48x48dp. Nav glyph targets are 44dp inside
  a 60dp pill, which is the board's geometry.
- No em dashes in any user-facing string.
- Cancel in-flight dio requests on dispose. `WorkspaceController.cancelAll` does it for the
  workspace; anything else that sends owns its own `CancelToken`.
- No analytics, no ads, no crash reporting, ever.

## Nav

Four destinations, evenly spaced, icon-only when inactive, the active one expanding into a
labelled `primaryContainer` pill: **Folders · Explore · Search · More**. No centre
action. New request is a circular button beside the pill, on the same line, and it stands
on every destination: it is the app's one primary action, and a request composed from
Explore returns to Explore. It opens the workspace on the root navigator for that reason.
The workspace hides the pill for its whole life (`navHiddenProvider`), as does every other
pushed page, and each one's primary action floats where the pill was.

Environments, Analytics, Testing, API docs and History live in More, not in the nav.
Privacy, Permissions and About sit under it too. The version on About and More is
the one Android reports for the installed package, read through
`PlatformSurfaces.appVersion`; `AboutInfo` holds only the links and the string to
show before the channel answers.

## Release

```bash
flutter build apk --release --target-platform android-arm64
```

Expected APK: around 12 to 14 MB for arm64, dominated by the Flutter engine, the bundled
Instrument Sans variable fonts and the Explore catalogue JSON. Not yet measured on this
build. R8 and resource shrinking are on by default in Flutter's release build. No signing
config yet.

## Known gotchas

Each of these cost time once. None of them is obvious from the code.

- **`@Default(schema)` does not compile.** json_serializable copies the
  annotation's expression verbatim into the `.g.dart`, where a static on the
  class is not in scope. The models use `@Default(1)` with the named constant
  beside it, and the two must be kept in step. `flutter analyze` will not catch
  this, because `.g.dart` is excluded; only a build fails.
- **Relational patterns break codegen.** `>= 200 and < 300` in a switch
  expression is valid Dart 3.13 and passes `flutter analyze`, but the analyzer
  build_runner bundles rejects it and the whole build fails. Write those as
  if-chains.
- **A Scaffold eats the bottom inset.** `NavShell`'s Scaffold sits above every
  screen, so `MediaQuery.viewInsetsOf` below it always read zero and nothing
  could react to the keyboard. `NavShell` now sets
  `resizeToAvoidBottomInset: false` and each screen's own Scaffold resizes.
  `View.of(context).viewInsets` is not a fix: it is not reactive, so the value
  goes stale the moment the keyboard closes.
- **`Flexible` next to a `Spacer` splits the free space.** Both take a flex of
  1, so a title ellipsised at half its available width. Anywhere a label should
  take the room and a trailing count only what it needs, the label is
  `Expanded` and there is no `Spacer`. This bit the request title, the response
  header's timing line and the section header's note.
- **`ColoredBox` in a `Row` collapses to nothing.** It has no intrinsic height
  and a Row centres its children, so the status-distribution bar rendered
  invisible until the Row got `crossAxisAlignment: stretch`.
- **`ReorderableListView.onReorder` is deprecated** in favour of
  `onReorderItem`, which already accounts for the removed item, so the old
  `to > from ? to - 1 : to` adjustment is wrong with it.
- **`Material` rejects `borderRadius` and `shape` together.** Passing both
  asserts at build time, not at analysis time, so it only shows up as a red
  screen. The shape carries the radius wherever a card needs an outline.
- **An overshooting curve cannot drive a layout tween.** `Curves.easeOutBack`
  is the house spring, but on `AnimatedContainer.padding` it pushes the value
  below zero and `EdgeInsets` asserts, and on `AnimatedSize` it pushes the
  width past its resting value and overflows the row. Anything that feeds
  layout uses `Motion.decelerate`; the spring belongs on colour, opacity and
  transforms, which have no floor.
- **The icon lives on its own board.** `PostPurush Icon Concepts.dc.html`,
  "1a Brace monogram, final", is the authority, not the app-icon section of the
  main board. The stem of the P is a curly brace and the bowl springs from its
  top hook: pista `#CCE6CC`, brace `#1E4120`, bowl `#417843`. Its `icon/android/`
  folder holds ready vector drawables, copied into `res/` verbatim;
  `AppMarkPainter` redraws the same two paths so the in-app mark cannot drift.
- **A `Container` clips to the outside of its border.** A filled row inside one
  paints under the 1px outline, and the outline then reads as a second line
  floating inside the group. `Material` with a `shape` clips to the inside of
  the side, which is why `AppCard` and `RowGroup` both use it.
- **Cross-fading two full-bleed children reads as a blur.** `AnimatedSwitcher`
  stacks the outgoing child over the incoming one, so for the length of the
  transition a whole page is drawn twice and looks smeared. It is right for a
  pane inside a page and wrong for the page itself; full-page state changes cut.
- **Crossing a shell branch from a pushed page.** `context.go` to a route in
  another branch rebuilds the shell *underneath* anything on the root
  navigator, leaving that page and its barrier on top of the destination.
  `openAsRequest` pops the root stack first.
- **`toImage()` hangs inside `testWidgets`.** It hands work to the engine's
  rasteriser, which the fake async of a widget test never lets complete. The
  icon generator wraps every render in `tester.runAsync`.
- **`ref` is gone by `dispose`.** A page that sets shared state on open and
  clears it on close has to capture the notifier in `initState`
  (`late final _nav = ref.read(...)`), because reading `ref` from `dispose`
  never runs and the state stays stuck. Writing the same flag from `build`
  is worse: the last build's post-frame callback lands *after* the clear.
- **Separate scrollables cannot be made to scroll together.** Giving every
  code line its own horizontal `SingleChildScrollView` made each line scroll
  by itself, and sharing one `ScrollController` between them does not fix it:
  only the one under the finger moves. The block scrolls as one sheet of text
  because there is no inner scrollable at all, just a shared offset applied
  through `Transform.translate`, with the drag recognised on every line.
- **`OverflowBox` takes the biggest size it is offered.** Giving it an
  infinite `maxWidth` so a line can lay out at its full width is right; doing
  that inside a sliver, which offers infinite height, makes the line
  infinitely tall and the list renders nothing below the first one. It needs a
  measured height, which is why `SliverCodeView` measures one line.
- **The release manifest had no `INTERNET` permission.** Flutter's template
  declares it only in `src/debug` and `src/profile`, for the tool's own
  connection. Debug builds therefore send fine and a release build cannot send
  at all, which for this app is the whole product. `src/main` declares it now.
- **Material plays the system click on every tap.** `enableFeedback` defaults
  to true on `InkWell` and friends, so a tool that should be quiet clicks like
  a dialler. Every ink widget here passes `enableFeedback: false`, and the
  theme turns it off for the Material widgets that read it from there
  (`textButtonTheme`, `iconButtonTheme`, `listTileTheme`, `popupMenuTheme`).
- **A long list in a `RowGroup` is built in full, every rebuild.** Explore's
  168 matches, the category lists, Collections and Search's results were all a
  `Column` inside a `ListView`, rebuilt on every keystroke or stream emission,
  which is why two of the Search scopes capped at 60. `SliverRowGroup` keeps
  the group's fill, outline and hairlines and builds a screenful at a time, so
  the caps are gone. API docs is the one list deliberately left eager: its
  in-page anchors are `GlobalKey`s, and `Scrollable.ensureVisible` cannot reach
  an endpoint that has not been built.
- **Deriving the folder tree per row is cubic.** Every row of Collections
  called `countIn`, which walks all folders and all requests, and each folder
  block rescanned both flat lists for its own children. `FolderIndex.of` does
  it in one pass over each list and every row is then a map lookup; the save
  sheet and API docs use it too. `countIn` stands for the single-folder case.
- **Parsing the response is the expensive thing the viewer does.** It used to
  happen in every `build`: once per fold, once per frame of a sideways drag.
  `SliverCodeView` keeps the outline until the source, fold version, colours or
  environment change, and the body editor asks `JsonOutline.isValid` rather
  than building a document it throws away.
- **The response is a real sheet.** `DraggableScrollableSheet` with the board's
  three stops as `snapSizes`, handing its `ScrollController` to the body, is
  what makes the drag and the body scroll a single gesture. A `Positioned` box
  at a fixed height looks the same standing still and is wrong the moment a
  finger touches it.
- **The workspace is a page, not a destination.** It hides the pill for its
  whole life and the shell ignores tab swipes while the pill is hidden, so a
  horizontal drag over a request cannot switch tabs behind it.
- **The emulator needs headroom.** Android refuses any install while free space
  is under roughly 10% of the data partition, whatever the APK's size, with
  `INSTALL_FAILED_INSUFFICIENT_STORAGE`. A debug APK is about 106 MB and a
  profile one about 46 MB; if installs start failing, free space on the device
  rather than shrinking the build.
