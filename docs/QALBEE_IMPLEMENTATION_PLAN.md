# Qalbee — Implementation Plan

> **Sources:** `docs/QALBEE_DEVELOPMENT_GUIDE.md` (binding engineering rules) and `docs/design_handoff_qalbee/` (binding visual design — tokens, components, ~90 artboards). Where this plan and those documents conflict, the guide and the design handoff win.
>
> **Status:** Plan drafted 2026-06-12 against Flutter 3.44.0 stable. Re-verify package versions (§3 of the guide) at each phase's start.

---

## 1. Current Project State (audited 2026-06-12)

The repo is a near-fresh Flutter scaffold (`lib/main.dart` is the counter demo) **plus template leftovers that conflict with the guide** and must be resolved in Phase 0:

| Found in repo | Conflict |
|---|---|
| `config/{ios,android}/{dev,prod}` Google Services files, Firebase plugins in `GeneratedPluginRegistrant` (macOS/Windows), `env/.env_*` | Guide §1: no server, no analytics SDK, no network dependency for core features. Firebase must be removed entirely. |
| Recent commit added `intl`, `equatable`, `dartz` (currently not in `pubspec.yaml`; lockfile modified) | `dartz` violates §6 (in-house sealed `Result<T>` only, no external functional packages). `equatable` is unnecessary (immutable `final class` entities with manual `==`/records). `intl` stays (mandated for l10n). |
| `assets/fonts/Inter-*.ttf` | Design mandates Schibsted Grotesk / Noto Sans Bengali / IBM Plex Sans Arabic / KFGQPC Uthmanic HAFS. Inter is unused → remove. |
| `assets/animation/no_internet.json` + other Lottie files | "Offline is the normal state — never an error." No Lottie package is approved; signature motion is custom (tokens: 120/240/420ms). Remove. |
| `assets/svg/*`, `assets/images/*` (generic template icons/placeholders) | Design uses its own 24px stroke icon set (`qalbee/base.jsx` `QI` map) and **no raster images**. Remove or replace during Phase 1. |

**Toolchain:** Flutter 3.44.0 stable / Dart SDK `^3.10.1` — pin in README + CI per guide §2.

---

## 2. Fixed Stack & Package Ledger

Mandatory and exclusive: **`go_router`** (routing) + **`get_it`** (DI) + **`signals` / `signals_flutter`** (state). Nothing parallel, ever.

Likely packages (each must pass the §3 pub.dev maintenance check **at its phase**, then be logged in `docs/DEPENDENCIES.md` with date + one-line justification):

| Package | Phase | Purpose |
|---|---|---|
| `go_router`, `get_it`, `signals`, `signals_flutter` | 1 | mandated core |
| `intl` + `flutter_localizations` (SDK) | 1 | ARB l10n, locale digits |
| `shared_preferences` | 2 | settings KV (decision: settings in prefs, content/entries in drift — documented once in DEPENDENCIES.md) |
| `geolocator` | 2 | GPS coordinates |
| `timezone` | 2 | manual-city wall-clock conversion |
| `adhan_dart` | 3 | prayer times + qibla bearing (pure Dart, offline) |
| `flutter_local_notifications` | 4 | azan/jamaat/sahri/iftar/muhasaba notifications |
| `sensors_plus` (or a compass package if one passes §3) | 6 | magnetometer + accelerometer → tilt-compensated heading |
| `drift` (+ `drift_dev`, `sqlite3_flutter_libs`) | 7 | Muhasaba DB + Quran DB |
| `local_auth` | 11 | biometric app/Muhasaba lock (verify per §3; PIN fallback is in-house) |

**Write in-house (no packages):** countdown timers, Hijri (Umm al-Qura/tabular arithmetic), charts/heatmap (`CustomPainter`), JSON mapping (`fromMap`/`toMap`), `Result<T>`/`Failure` sealed types, PIN lock, motif/icons.

---

## 3. Architecture Skeleton (built in Phase 1, filled per feature)

Clean Architecture, feature-first, exactly per guide §4:

```
lib/
  config/
    app_config.dart            # app-level constants (app name, defaults, durations, limits)
    assets.dart                # typed asset path constants (fonts, DBs, motif)
    flavors.dart               # build flavor / environment switches (dev/prod) — no secrets, no network endpoints
  core/
    di/locator.dart            # single composition root, setupLocator() before runApp
    router/app_router.dart     # all routes; StatefulShellRoute.indexedStack (Home/Quran/Muhasaba/Dua/More)
    theme/                     # tokens.css → ThemeData + ThemeExtensions (light & dark)
    l10n/                      # ARB: en (template) + bn
    utils/                     # Result<T>, date utils, hijri converter, locale digit formatting
  shared/
    widgets/                   # shared dumb widgets (buttons, inputs, sheets, skeletons, ring, heatmap cell…)
    painters/                  # QalbMark / Star8 / MotifBg CustomPainters
    extensions/                # BuildContext/theme/l10n convenience extensions
  features/
    onboarding/ settings/ prayer_times/ my_mosque/ qibla/
    quran/ dua_tasbih/ muhasaba/ ramadan/ calendar/
      └── domain/{entities,repositories,usecases}   # pure Dart only
          data/{datasources,repositories,models}     # only layer touching plugins/drift
          presentation/{state,screens,widgets}       # signals stores; depends on domain only
main.dart
tool/                          # dev-time scripts: quran_db_build.dart, city_db_build.dart
```

Layer rules, DI registration conventions (lazySingleton repos, factory stores), signals patterns (one `now` signal → computeds), and routing rules (typed route constants, onboarding `redirect`, `/quran/:surah/:ayah` deep links) are as specified in guide §4 — treated as acceptance criteria for every phase below.

**Dependency direction for the top-level folders:** `config` depends on nothing; `core` and `shared` may depend on `config` but never on `features`; `features` may import `config`/`core`/`shared` plus other features' **domain interfaces only**. `shared` holds reusable presentation pieces (dumb widgets, painters, extensions); `core` holds app infrastructure (DI, router, theme, l10n, pure utils).

---

## 4. Phased Build Plan

Order follows guide §7. Each phase ends with: `flutter analyze` zero warnings, all tests green, DEPENDENCIES.md updated, and the phase's design artboards visually matched (light + dark).

### Phase 0 — Cleanup & Baseline
**Goal: a clean, guide-compliant scaffold; nothing in the repo contradicts the guide.**
- Remove Firebase: `config/`, `env/`, plugin registrations (regenerate `GeneratedPluginRegistrant` / windows plugin cmake after dependency cleanup), any platform Gradle/Podfile references.
- Remove `dartz`/`equatable` from the lockfile by cleaning `pubspec.yaml` deps; remove Inter fonts, Lottie JSONs, template SVG/PNG assets, `assets/json/demo.json`.
- `analysis_options.yaml`: `flutter_lints` latest + `strict-casts`, `strict-inference`, `strict-raw-types`, `unawaited_futures`.
- **Rewrite `README.md`** (currently the Flutter template stub): project description (what Qalbee is — offline-first, backend-less Islamic lifestyle app), feature pillars, pinned Flutter 3.44.0, setup/run instructions, architecture overview (diagram added in Phase 1), and the package policy summary linking to `docs/DEPENDENCIES.md`. The README is a living doc — every phase that adds a tool script, asset pipeline, or setup step updates it in the same change.
- Add CI (analyze + test) if/when CI is introduced.
- Set app id/name (`qalbee`), min SDK versions per current Flutter defaults.
- **Platform toolchain policy:** iOS/macOS use **Swift Package Manager only — no CocoaPods** (`flutter config --enable-swift-package-manager`; if a future plugin lacks SPM support, raise it before adding the dependency). Android stays on the **latest Flutter-template toolchain** (currently Gradle 9.1.0 / AGP 9.0.1 / Kotlin 2.3.20, Java 17) and is re-checked against the template at every Flutter upgrade.
- **Done when:** `flutter analyze` clean, `flutter run` boots an empty Material 3 app, no Firebase symbol anywhere in the tree.

### Phase 1 — Foundation: Tokens, Theme, L10n, Shell (design canvas §01–02)
**Goal: every later screen is assembled from these parts; no feature code yet.**
- **Theme:** map `qalbee/tokens.css` 1:1 → `ColorScheme` + `ThemeExtension`s (`QalbeeColors` for bg/surface-2/ink-2/ink-3/line/primary-soft/accent/ok/warn/urgent + soft variants/scrim; `QalbeeMotion` 120/240/420ms; spacing 4pt consts; radius sm10/md14/lg20/xl28). Dark theme is its own designed palette, not an inversion. No inline `Color(0xFF…)` in feature widgets — lint-check by convention/review.
- **Typography:** bundle Schibsted Grotesk (variable), Noto Sans Bengali, IBM Plex Sans Arabic, KFGQPC Uthmanic HAFS (verify license/attribution → About credits). Type scale per handoff (display 34 → overline 11; countdown numeral 56 tabular). Per-locale font fallback chains.
- **L10n:** ARB setup (`en` template + `bn`), `intl` digit formatting helper (Western/Bengali/Eastern Arabic). Rule from day one: no hardcoded user-facing strings.
- **Motif & icons:** port `QalbMark`/`Star8`/`MotifBg`/`HEART_PATH` from `base.jsx` to `CustomPainter`s in `shared/painters/`; recreate or substitute the 24px ~1.7px-stroke icon set.
- **Config scaffold:** `config/` lands here — `app_config.dart` (defaults like jamaat lead time, countdown thresholds), `assets.dart` (typed asset paths), `flavors.dart` (dev/prod switches; no secrets or endpoints — the app has no backend).
- **Shared widget library** in `shared/widgets/` (each with default/pressed/disabled/focused; skeleton loading variants): buttons (primary/tonal/outline/ghost/accent), inputs, segmented control, sheets (24px top radius, scrim), dialogs, progress ring, heatmap cell (5 levels, 13dp, r3.5), bottom nav (5 tabs; heart appears only in Muhasaba tab icon per motif rules).
- **DI + Router:** `setupLocator()`; `StatefulShellRoute.indexedStack` with 5 placeholder tabs; route-name constants; redirect stub reading `setupComplete`.
- **Widget gallery:** a debug-only route showing the component library in both themes (serves as living visual regression surface).
- **Tests:** golden/widget tests for countdown-card shell states and buttons; unit tests for digit formatting.

### Phase 2 — Settings + Location (canvas §12)
**Goal: the substrate every other feature reads. Everything downstream depends on `PrayerParams` and location.**
- **Domain:** `AppSettings`, `LocationConfig` (`gps(lat,lng,resolvedName)` | `manualCity(cityId)` sealed), `PrayerParams` (method, madhab, high-latitude rule, per-prayer ±minute offsets), theme/locale prefs, notification matrix model (consumed in Phase 4).
- **City DB:** `tool/city_db_build.dart` builds a bundled asset (~worldcities: name/country/lat/lng/IANA tz) from a permissively-licensed source (GeoNames or SimpleMaps free tier — record license in DEPENDENCIES.md). Searchable manual picker.
- **Timezone:** device location → `toLocal()`; manual city → `timezone` package with the city's IANA zone. This rule is enforced in one datasource, tested.
- **Data:** `shared_preferences`-backed settings repo; `geolocator` wrapper with permission flow (priming → OS dialog → **denied ⇒ manual picker fallback**, never a dead end).
- **Presentation:** grouped Settings screen (calculation / notifications stub / appearance & language / privacy stub / about+credits / "run setup again" stub).
- **Tests:** settings round-trip, timezone conversion for foreign cities (e.g. Dhaka user viewing Mecca), city search.

### Phase 3 — Prayer Times Domain + Home (canvas §05)
**Goal: the app's heart — correct times anywhere on earth + the smart countdown.**
- **Domain:** `PrayerDay` (5 waqts + sunrise, sahri end = Fajr, iftar = Maghrib), `Waqt`, `CountdownTarget`; `GetPrayerDay(params, location, date)` wrapping `adhan_dart` behind a data-layer interface.
- **Smart countdown:** pure function `CountdownTarget resolve(now, PrayerDay, JamaatConfig, ramadanMode)` — before waqt → waqt start; after start & jamaat configured & future → jamaat; else → waqt end; Ramadan: pre-Fajr → sahri end, Asr→Maghrib → iftar. **Exhaustive unit tests for every branch** (incl. no-jamaat, midnight rollover, DST edges, high latitudes).
- **Hijri converter** (in-house Umm al-Qura/tabular, `core/utils/`) with test vectors — needed by Home's tri-calendar header (and Phases 10–11).
- **Presentation:** Home per design — header (tappable location, Gregorian+Hijri+Bengali date), countdown hero card (calm/amber/urgent + 2 Ramadan states, 240ms color transitions, 56px tabular numeral), prayer table (current-waqt highlight, jamaat column, check→Muhasaba affordance stub, quiet "Set jamaat"), sahri/iftar row. One `Timer.periodic` → one `now` signal; only the countdown subtree rebuilds per tick. Compact 360×640 + tablet adaptations.
- **Tests:** state machine (most important suite in the app), prayer param mapping, widget tests for all 5 countdown card states.

### Phase 4 — Notification Scheduler (canvas §15)
- `NotificationScheduler` behind a domain interface; schedules next ~48h (azan per matrix: sound/beep/silent/off, sahri warning ~30min, iftar celebratory, jamaat reminder lead time, muhasaba evening nudge — max one) on app open and after settings/location/jamaat change.
- Android exact-alarm permission flow + battery-optimization guidance screen; iOS permission priming + denied-state education (app stays fully useful).
- Notification content per the designed artifacts (azan with "Mark as prayed" action → deep link into Muhasaba/Home).
- Settings notification matrix UI goes live.
- **Tests:** scheduling-window computation (pure logic extracted from the plugin wrapper), reschedule triggers.

### Phase 5 — My Mosque / Jamaat (canvas §11)
- **Domain:** `JamaatEntry = fixed(TimeOfDay) | offset(Duration) | none` (sealed); `MosqueProfile` (multiple, one active; Maghrib default offset +5; optional seasonal pair). Persist in drift or prefs (decide with the Phase 7 DB — likely drift once it lands; until then prefs JSON is acceptable if documented).
- Countdown integration: jamaat branch of the state machine now driven by real config; jamaat reminders into the scheduler.
- **Tests:** jamaat resolution (fixed vs offset vs none, seasonal switch), countdown integration cases.

### Phase 6 — Qibla Compass (canvas §06)
- Bearing from `adhan_dart` `Qibla`; heading from `sensors_plus` magnetometer+accelerometer with tilt compensation in-house (unless a compass package passes §3 — decide and log).
- Aligned state at ±3° tolerance: gold accent visual + haptic; calibration figure-8 prompt; sensor-unavailable fallback (verbal bearing, e.g. "Qibla is 278° W-NW"); location-needed state; distance to Kaaba detail.
- **Tests:** bearing math, alignment-tolerance logic, heading-smoothing unit tests.

### Phase 7 — Muhasaba (canvas §09 — the differentiator, most design attention)
- **Drift arrives here.** Schema: `tracker_items(id, name, type yesNo|count|duration, dailyTarget?, icon, color, isDefault, archived)` + `daily_entries(itemId, date, value)`. **Archive, never hard-delete.**
- Default items seeded (5 prayers individually, Quran, hadith, roza, azkar, sadaqah, tahajjud…).
- **Aggregations in SQL (drift DAO queries, tested):** range completion %, per-item totals, streaks, heatmap intensities, vs-previous-period trend — not in-memory loops over history.
- **Screens:** daily entry (salah chip row + three input types, one-thumb, date switcher with back-fill), custom-field flow (name/type/target/icon/color, archive flow with "history preserved" explanation), dashboard (Today/Week/Month/Year/Custom range; completion ring, per-item bars, GitHub-style heatmap and trend line as `CustomPainter`), first-day & empty-range states, Ramadan share card (4:5 export image via `RepaintBoundary`).
- **Hard product rule everywhere: no guilt framing** — level-0 heatmap reads "not yet", no red/"failed" for missed deeds (urgent color is reserved for waqt countdown only).
- Home prayer-table check affordance now writes Muhasaba entries.
- **Tests:** DAO aggregation/streak queries (the second-most-important suite), widget tests for the three tracker row types.

### Phase 8 — Quran (canvas §07)
- **`tool/quran_db_build.dart`:** builds bundled SQLite from Tanzil/QUL sources (Arabic Uthmani + at least one English + one Bangla translation; store attributions → About). Asset copied to app dir on first run, opened via drift. Schema: `surahs`, `ayahs(id, surah, number, arabic, translation)`, `bookmarks`, `last_read`.
- **Screens:** surah list (star-number medallion, search, juz tab, "Continue reading" resume card), reader (ayah-by-ayah, HAFS font, per-ayah bookmark/copy/share/play-placeholder, sticky header + progress, translation-on & Arabic-only modes, independent user font scale 22–44px step 2 persisted separately), reading-settings sheet, first-open & search-empty states. Night-reading comfort in dark theme is paramount.
- **Performance:** lazy slivers/`ListView.builder` with item extents where possible.
- Deep link `/quran/:surah/:ayah` wired for notification taps.
- **Tests:** DB pipeline output integrity (114 surahs, 6236 ayahs, non-empty fields), bookmark/last-read repo, search.

### Phase 9 — Dua & Tasbih + Asmaul Husna (canvas §08)
- Dua content into the bundled DB (extend the `tool/` pipeline; sourced collections with attribution): categories grid → detail (Arabic/transliteration/translation/reference, repeat ring for repeatable duas).
- **Tasbih:** full-screen tactile counter — 33/100/custom presets, progress ring, haptic every tap, milestone pulse at target (420ms, reduced-motion: cut), save-before-reset confirm, session history line (drift table).
- Asmaul Husna 99-name browse + detail.
- **Tests:** counter/session logic, preset/target behavior.

### Phase 10 — Ramadan, Calendar, Zakat (canvas §10, §13)
- **Ramadan section:** roza counter (day N of 29/30), dual sahri/iftar countdowns (reuse countdown machinery), full-month sahri-iftar table, fitra info card. Lives in "More" year-round; promoted (tab/menu elevation) during Ramadan — driven by the Hijri converter.
- **Zakat calculator:** pure-Dart local computation (assets/liabilities form, nisab check, breakdown) with unit tests.
- **Calendar:** combined Gregorian+Hijri+Bengali month grid, Islamic important dates + legend, day popover (three dates + that day's prayer times).
- **Tests:** hijri↔gregorian round-trips across years, Ramadan detection, zakat math.

### Phase 11 — Onboarding, App Lock & Polish (canvas §03–04, §14, §16)
- **Splash:** mark draw-in ≤2s, never blocks, light+dark, reduced-motion = cut.
- **Onboarding:** Welcome → Language → Location (GPS or manual; priming before OS dialog; denied → manual fallback) → Madhab (region pre-select, "affects Asr only") → Calc method (country auto-suggest) → Notification priming (+ denied state) → Bismillah finish. Gate via go_router `redirect` on `setupComplete`; re-enterable from Settings.
- **App lock:** PIN (in-house) + biometric (`local_auth` if it passes §3); whole-app and/or Muhasaba-only lock per design.
- **Polish passes (each a checklist run over every screen):**
  1. **RTL pass** — Arabic locale mirror set (Home/Quran/Settings per design §14); `EdgeInsetsDirectional` everywhere already, verify chevrons/back flip, Eastern Arabic digits.
  2. **Accessibility pass** — AA contrast both themes, ≥48dp targets, 1.5× font scale without truncation, semantics labels, no color-only signaling.
  3. **Dark-theme pass** — every screen against designed dark palette.
  4. **Performance pass** — countdown rebuild scope, Quran scroll jank, painter repaint bounds.
- **Store assets:** adaptive icon (66% safe zone, works at 48px, qalb motif), feature graphic, 6 screenshot frames.

---

## 5. Cross-Cutting Workstreams (run alongside every phase)

- **Documentation:** `README.md` kept current every phase (description, setup, architecture diagram, tool scripts, dependency policy); brief `///` docs on public domain APIs; final README/architecture-diagram review in Phase 11.
- **`docs/DEPENDENCIES.md`** — created in Phase 1; every package logged (name, version, date checked, §3 checklist result, justification). Asset/data licenses (fonts, city DB, Tanzil/QUL, dua sources) logged here too.
- **Testing bar — every feature ships with test cases (hard rule, user-mandated):** no phase closes without tests for the feature it built. Per feature that means: unit tests for all domain logic (entities, use cases, pure functions), repository/datasource tests where there is mapping or query logic, and widget tests for the feature's key screens/components and their states (loading/empty/error included). Domain layer targets near-full coverage. Priority suites: countdown state machine > muhasaba aggregations/streaks > hijri conversion > timezone conversion > jamaat resolution > zakat. Run `flutter analyze` + `flutter test` before every commit; zero warnings and a green suite are hard gates. Test files mirror `lib/` structure under `test/`.
- **L10n discipline:** every new string lands in `en` ARB + `bn` translation in the same change.
- **Design fidelity:** each phase's screens compared against the corresponding artboards (`Qalbee Design.html`) in both themes before the phase closes.
- **Airplane-mode check:** at the end of every phase, core flows verified with all radios off.

## 6. Definition of Done (release gate — mirrors the two hard-rules checklists)

- [ ] Only go_router + get_it + signals; no parallel routing/DI/state anywhere
- [ ] Every dependency passed §3 and is in DEPENDENCIES.md; zero deprecated APIs; zero analyzer warnings
- [ ] Domain layer is pure Dart (no Flutter imports) — verifiable by grep/CI
- [ ] All core features work in airplane mode
- [ ] All strings in ARB (en + bn); layouts direction-aware; RTL set matches design §14
- [ ] Smart-countdown state machine fully unit-tested (every branch incl. Ramadan + no-jamaat)
- [ ] Muhasaba items archived, never deleted; history preserved
- [ ] No guilt/shame framing in any progress UI; urgent color never used for missed deeds
- [ ] Quran uses KFGQPC Uthmanic HAFS with correct harakat; translation attributions in About
- [ ] All countdown color states AA-compliant in both themes
- [ ] Permission-denied fallbacks implemented for location & notifications
- [ ] Light + dark designed states for every screen; splash ≤2s and never blocks
