# Productive Muslim — Development Guide

> **Audience of this document:** This guide instructs the coding agent ("Claude Code") building Productive Muslim. Follow it strictly. Where this document and convenience conflict, this document wins.

---

## 1. Product Summary (context for every coding decision)

**Productive Muslim** is an **offline-first, backend-less** Islamic lifestyle app in Flutter for a global audience. All core features work with zero network: prayer/sahri/iftar times (computed locally from coordinates), qibla compass (sensors), Quran/dua (bundled assets), Muhasaba tracker (local DB), Ramadan tools, Hijri calendar, jamaat-time configuration, notifications.

There is **no server, no API of our own, no analytics SDK, no ads**. Do not introduce any network dependency for core features.

---

## 2. Tech Stack (fixed — do not substitute)

- **Flutter:** latest **stable** channel at project start. Run `flutter upgrade` and pin the version in `README` and CI. Use Material 3 (`useMaterial3` is the default in current Flutter; never disable it).
- **Dart:** latest stable bundled with that Flutter. Set `environment: sdk` in `pubspec.yaml` to the current stable lower bound.
- **Routing:** `go_router`
- **Dependency injection / service locator:** `get_it`
- **State management:** `signals` (signals.dart — `signals_flutter` for widget bindings)

These three are mandatory and exclusive: do **not** add provider, riverpod, bloc, getx, auto_route, injectable codegen, or any parallel state/DI/routing solution.

---

## 3. Package Policy (strict)

1. **Prefer Dart/Flutter built-ins over packages.** If the problem is solvable with the SDK in reasonable code, write it ourselves. Examples:
   - Date/duration math, countdown timers → `DateTime`, `Duration`, `Timer.periodic` / `Stream.periodic`. No third-party countdown packages.
   - Hijri conversion → implement the Umm al-Qura / tabular Islamic calendar arithmetic in pure Dart (well-tested), OR justify a package per rule 2. Do not pull a heavy dependency for date math.
   - Simple charts (progress bars, trend line, heatmap) → custom `CustomPainter` widgets. Do **not** add fl_chart/syncfusion for a heatmap and one line chart we can paint ourselves.
   - JSON parsing → hand-written `fromMap/toMap` or Dart 3 records; **no** json_serializable/freezed codegen.
   - Local key-value prefs → `shared_preferences` is acceptable (maintained, flutter.dev), but simple app settings may also live in the DB; decide once, document it.
2. **Before adding ANY package**, verify on pub.dev: (a) updated within the last 12 months, (b) supports the current stable Flutter/Dart, (c) null-safe, (d) healthy maintenance signals (issues triaged, not archived). If a package fails any check, do not use it — find an alternative or implement in-house. Record every approved package and the date checked in `docs/DEPENDENCIES.md` with one line of justification.
3. **No deprecated anything.** No deprecated packages, no deprecated Flutter/Dart APIs. `flutter analyze` must report zero deprecation warnings. Examples of the standard to uphold: use `PopScope` (not `WillPopScope`), modern `MaterialState`→`WidgetState` APIs, current theme APIs, `Color.withValues` style modern APIs where applicable — always prefer the replacement the deprecation message names.
4. **Likely-needed packages (verify each per rule 2 at implementation time; do not assume):**
   - `adhan_dart` — prayer time + qibla angle calculation (pure Dart, offline)
   - `geolocator` — GPS coordinates
   - Compass heading: evaluate at implementation time — if no well-maintained compass package passes rule 2, compute heading from `sensors_plus` magnetometer+accelerometer with tilt compensation in-house.
   - `drift` — SQLite (typed, maintained) for Quran/dua content DB and Muhasaba entries
   - `flutter_local_notifications` — azan/jamaat/reminders
   - `timezone` — correct wall-clock times for manually selected foreign cities
   - `intl` + `flutter_localizations` (SDK) — l10n via ARB files
   - `signals` / `signals_flutter`, `go_router`, `get_it` — as mandated
   If any of these fails the maintenance check at build time, stop and choose/implement an alternative; note it in `DEPENDENCIES.md`.

---

## 4. Architecture — Clean Architecture, feature-first

```
lib/
  core/                      # shared, feature-agnostic
    di/locator.dart          # get_it registrations (single composition root)
    router/app_router.dart   # go_router config (single source of routes)
    theme/                   # tokens, light/dark ThemeData
    l10n/                    # generated localizations
    utils/                   # pure helpers (date, hijri, formatting)
    widgets/                 # shared dumb widgets
  features/
    prayer_times/
      domain/
        entities/            # PrayerDay, Waqt, JamaatConfig (pure Dart, immutable)
        repositories/        # abstract repository interfaces
        usecases/            # e.g. GetPrayerDay, GetSmartCountdownTarget
      data/
        datasources/         # adhan calc wrapper, drift DAOs, prefs
        repositories/        # interface implementations
        models/              # persistence/DTO models + mappers to entities
      presentation/
        state/               # signals-based controllers/stores
        screens/
        widgets/
    qibla/
    quran/
    dua_tasbih/
    muhasaba/
    ramadan/
    my_mosque/
    settings/
    onboarding/
    calendar/
main.dart
```

### Layer rules (enforced, no exceptions)
- **domain** depends on nothing but Dart. No Flutter imports, no packages (except pure-Dart calc libs wrapped behind interfaces if unavoidable — prefer wrapping in data layer instead).
- **data** implements domain interfaces; only layer that touches drift, geolocator, adhan_dart, prefs, sensors, notifications plugin.
- **presentation** depends on domain only (via use cases / repository interfaces resolved through get_it). It never imports data-layer classes.
- Cross-feature access goes through domain interfaces, never by importing another feature's presentation/data.

### Dependency injection (get_it)
- One composition root: `core/di/locator.dart` with `setupLocator()` called in `main()` before `runApp`.
- Register: data sources & repositories as `lazySingleton`; use cases as `factory` or `lazySingleton` (stateless); presentation stores as `factory` (or scoped manually per screen lifecycle — dispose signals effects in `dispose`).
- No `GetIt.I` calls scattered in widgets — resolve in screen-level state objects / constructors so widgets stay testable.

### State management (signals)
- Each screen/feature gets a plain Dart **store/controller class** holding `signal`s, `computed`s, and methods; created via get_it, disposed properly (dispose `effect`s and `Timer`s).
- Derive, don't duplicate: e.g. `currentWaqt`, `countdownTarget`, `countdownLabel`, `countdownColorState` are `computed` from a single `now` signal ticked by one `Timer.periodic` — not separate mutable states.
- Widgets consume via `Watch`/`watch(context)` from `signals_flutter`. Keep rebuild scopes tight (watch the smallest signal needed).
- Async: model loading/error explicitly (sealed result types — see §6), no swallowed futures.

### Routing (go_router)
- All routes declared in `core/router/app_router.dart`. Use `StatefulShellRoute.indexedStack` for the bottom navigation (Home / Quran / Qibla / Dua / Muhasaba) so tab state persists.
- Typed route names as constants; no raw string paths sprinkled in widgets.
- Onboarding gate via `redirect` reading a "setupComplete" flag; deep-link friendly paths (e.g. `/quran/:surah/:ayah` for notification taps).

---

## 5. Domain Logic Requirements (implement exactly)

- **Prayer times:** computed locally via adhan_dart from `(lat, lng, date, CalculationMethod, Madhab, HighLatitudeRule, per-prayer minute offsets)`. Sahri end = Fajr start; Iftar = Maghrib. All user-tunable parameters live in settings and flow through one `PrayerParams` entity.
- **Timezone correctness:** times for the *device's own* location may use `toLocal()`; times for a *manually selected* city MUST convert through `timezone` package using that city's IANA timezone. City DB (bundled asset, ~world cities with name/country/lat/lng/tz) is required for manual selection.
- **Smart countdown state machine:** before waqt start → target waqt start; after start and jamaat configured & future → target jamaat; else → target waqt end. Ramadan overrides: pre-Fajr targets sahri end; Asr→Maghrib window targets iftar. Encode as a pure function `CountdownTarget resolve(now, PrayerDay, JamaatConfig, ramadanMode)` with exhaustive unit tests.
- **Jamaat config:** per prayer = `fixed(TimeOfDay)` | `offset(Duration)` | `none` (sealed class). Multiple mosque profiles; one active. Optional seasonal profiles.
- **Muhasaba:** `TrackerItem {id, name, type(yesNo|count|duration — sealed), dailyTarget?, isDefault, archived}` + `DailyEntry {itemId, date, value}`. Items are archived, never hard-deleted. Dashboard aggregations (range completion %, per-item totals, streaks, heatmap intensities) are SQL via drift — written as DAO queries with tests, not in-memory loops over full history.
- **Quran data:** bundled SQLite (built from Tanzil/QUL sources at dev time by a script in `tool/`), copied from assets to app dir on first run, opened via drift. Schema: `surahs`, `ayahs(id, surah, number, arabic, translation)`, `bookmarks`, `last_read`. Translation attributions stored and surfaced in About.
- **Notifications:** schedule next ~48h of prayer/jamaat/sahri/iftar notifications on app open and reschedule after settings/location change. Android: request exact-alarm permission flow + battery-optimization guidance screen. All scheduling in one `NotificationScheduler` service behind a domain interface.
- **Qibla:** bearing from adhan_dart `Qibla`; heading from compass sensor; aligned state when |heading − bearing| ≤ tolerance with haptic feedback.

---

## 6. Code Quality Standards

- **Lints:** `flutter_lints` latest, plus tighten in `analysis_options.yaml`: `strict-casts`, `strict-inference`, `strict-raw-types`. Zero analyzer warnings policy.
- **Use modern Dart 3+ features:** sealed classes + exhaustive `switch` expressions for states/types, records for light tuples, pattern matching, class modifiers (`final class` by default), `const` everywhere possible.
- **Immutability:** entities and signal values are immutable; mutations create new instances.
- **Error handling:** repository/usecase results use a small in-house sealed `Result<T>`/`Failure` type (no external functional packages). No bare `catch` without typed handling; never silently ignore errors.
- **Async hygiene:** no unawaited futures (lint-enforced), cancel timers/streams/effects in dispose.
- **Testing:** unit tests required for all domain logic — prayer param mapping, smart-countdown state machine (every branch incl. Ramadan + no-jamaat), hijri conversion, jamaat resolution, muhasaba aggregations/streaks, timezone conversion for foreign cities. Widget tests for countdown card states and tracker entry rows. Target: domain layer near-full coverage.
- **Localization:** all user-facing strings via ARB (`intl`) from day one — no hardcoded strings in widgets. English template + Bangla. Use `EdgeInsetsDirectional`/`AlignmentDirectional` and directional icons everywhere (RTL readiness is mandatory even before Arabic ships). Numerals formatted per-locale via `intl`.
- **Theming:** all colors/typography/spacing from the design-token theme (ThemeData extensions for custom tokens like countdown state colors). No inline `Color(0xFF...)` in feature widgets.
- **Performance:** Quran reader uses lazy `ListView.builder`/slivers with item extents where possible; heatmap/charts as efficient `CustomPainter`; countdown ticks update only the countdown subtree (1s timer → one signal).
- **Documentation:** brief `///` docs on public domain APIs; `README` with setup, architecture diagram, and the dependency policy; `docs/DEPENDENCIES.md` ledger.

---

## 7. Build Order (work in this sequence)

1. Project scaffold: latest stable Flutter, lints, theme tokens, l10n setup, get_it locator, go_router shell with placeholder tabs.
2. Settings + location feature (GPS + manual city DB + timezone) — everything depends on it.
3. Prayer-times domain (params → PrayerDay) + Home screen with smart countdown (full state machine + tests).
4. Notifications scheduler (azan + sahri/iftar) with exact-alarm handling.
5. My Mosque (jamaat config) + countdown/jamaat integration + jamaat reminders.
6. Qibla compass.
7. Muhasaba (DB schema, entry screen, custom fields, dashboard aggregations).
8. Quran (asset DB pipeline in `tool/`, list + reader + bookmarks).
9. Dua & Tasbih, Asmaul Husna.
10. Ramadan section, Hijri/combined calendar, zakat calculator.
11. Onboarding flow + app lock + polish (RTL pass, accessibility pass, dark-theme pass).

## 8. Hard Rules Checklist (verify continuously)

- [ ] Only go_router + get_it + signals for routing/DI/state — nothing parallel
- [ ] Every dependency passed the §3 maintenance check and is logged in DEPENDENCIES.md
- [ ] Zero deprecated APIs, zero analyzer warnings
- [ ] domain layer is pure Dart with no Flutter imports
- [ ] Core features work in airplane mode
- [ ] All strings in ARB; all layouts direction-aware
- [ ] Smart-countdown state machine fully unit-tested
- [ ] Archived (not deleted) muhasaba items; history preserved
