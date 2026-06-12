# Qalbee — Progress Tracker

> Companion to `QALBEE_IMPLEMENTATION_PLAN.md`. Update this file in the same change as the work itself — phase status, task checkboxes, and a worklog line.
>
> **Status legend:** ⬜ Not started · 🔄 In progress · ✅ Done · ⏸️ Blocked/paused

## Phase Overview

| Phase | Title | Status | Notes |
|---|---|---|---|
| 0 | Cleanup & Baseline | ✅ | Done 2026-06-12; APK builds green on Gradle 9.1/AGP 9.0.1 |
| 1 | Foundation: Tokens, Theme, L10n, Shell | ✅ | Done 2026-06-12; 37 tests green, APK builds |
| 2 | Settings + Location | ✅ | Done 2026-06-12; 74 tests green, APK builds |
| 3 | Prayer Times Domain + Home | ✅ | Done 2026-06-12; 119 tests green, APK builds |
| 4 | Notification Scheduler | ✅ | Done 2026-06-12; 143 tests green, APK builds (deep links → Ph7, azan audio → Ph11) |
| 5 | My Mosque / Jamaat | ✅ | Done 2026-06-12 (multi-agent); 174 tests green, APK builds |
| 6 | Qibla Compass | ✅ | Done 2026-06-12 (multi-agent); 220 tests green |
| 7 | Muhasaba | ⬜ | |
| 8 | Quran | ⬜ | |
| 9 | Dua & Tasbih + Asmaul Husna | ⬜ | |
| 10 | Ramadan, Calendar, Zakat | ⬜ | |
| 11 | Onboarding, App Lock & Polish | ⬜ | |

**Phase exit gate (applies to every phase):** `flutter analyze` zero warnings · all tests green · **every feature built in the phase has its own test cases (unit + widget)** · DEPENDENCIES.md updated · README updated if setup/tooling changed · design artboards matched (light + dark) · airplane-mode check passed.

---

## Phase 0 — Cleanup & Baseline ✅

- [x] Remove Firebase: `config/`, `env/`, plugin registrations, platform build references
- [x] Clean `pubspec.yaml`/lockfile (`dartz`, `equatable`, `get`, `dio` etc. out; registrants regenerated; `cupertino_icons` also dropped — unused)
- [x] Remove template assets: Inter fonts, Lottie JSONs, template SVG/PNG, `assets/json/demo.json` (entire `assets/` removed; Phase 1 re-adds fonts)
- [x] `analysis_options.yaml`: replaced invalid template config with flutter_lints + strict-casts/inference/raw-types; deprecations & unawaited/discarded futures = errors
- [x] Rewrite `README.md` (description, pillars, pinned Flutter 3.44.0, setup, toolchain policy, policy links)
- [x] App id/name set (`com.qalbee.qalbee` / "Qalbee"); `lib/main.dart` → minimal Material 3 placeholder; smoke test updated
- [x] iOS/macOS: Swift Package Manager enabled, **no CocoaPods** (no Podfile exists)
- [x] Android latest toolchain: Gradle 8.14→9.1.0, AGP 8.11.1→9.0.1, Kotlin 2.2.20→2.3.20 (matches Flutter 3.44 template)
- [x] `flutter analyze` zero issues; `flutter test` passing
- [x] Android debug build green on new toolchain (`app-debug.apk` built, 121s)

## Phase 1 — Foundation ✅

- [x] Theme: `tokens.css` → ColorScheme + `QalbeeColors` ThemeExtension (light + dark, M3), QSpace/QRadius/QMotion tokens
- [x] Fonts bundled: Schibsted Grotesk (var), Noto Sans Bengali (var), IBM Plex Sans Arabic (4 wts), KFGQPC Uthmanic HAFS v22 (licenses logged in DEPENDENCIES.md)
- [x] Type scale (display→overline + 56px countdown numeral, fontVariations for variable fonts) + UI fallback chain
- [x] L10n: ARB en + bn (`flutter gen-l10n`), LocaleDigits helper (bn/ar/ur digit sets)
- [x] Motif: QalbMark/Star8/MotifBackground CustomPainters in `shared/painters/` (heart path hand-converted from SVG); icon set decision: Material Symbols substitute (handoff permits)
- [x] `config/` scaffold: app_config (product thresholds) / assets (font families) / flavors
- [x] Shared widget library: QButton (5 kinds × pressed/disabled/focused), QCard, QChip, QSegControl, QBanner, QSkeleton, QProgressRing, QHeatmap(Cell), QListRow, CountdownCard (5 states), QBottomNavScaffold
- [x] DI locator + go_router `StatefulShellRoute.indexedStack` shell (5 tabs, typed route constants, redirect comes with onboarding Phase 11)
- [x] Debug widget gallery route (`/dev/gallery`, linked from More tab in debug)
- [x] Tests (37 passing): LocaleDigits, Result, AppTheme/tokens, QButton (incl. semantics), CountdownCard all 5 states + dark, QHeatmap levels, router shell (5 tabs, switching, persistence, bn locale)
- [x] `docs/DEPENDENCIES.md` created; go_router 17.3.0 / get_it 9.2.1 / signals 7.1.0 / intl logged with check dates
- [x] Debug APK build green

## Phase 2 — Settings + Location ✅

- [x] Domain: AppSettings, LocationConfig (sealed gps/manualCity), City, PrayerParams (12 methods, madhab, high-lat, ±minute offsets), NotificationMatrix; repositories + 4 use cases — pure Dart
- [x] `tool/city_db_build.dart` → 33,824 cities (GeoNames cities15000, CC BY 4.0 logged), population-ranked JSON asset (1.7 MB)
- [x] Timezone rule: GPS→toLocal, manual city→IANA via `timezone` pkg, one `TimezoneClock` (ZonedClock interface), DST + date-line tested
- [x] Prefs-backed settings repo (atomic JSON blob, forward-compatible mapper); geolocator behind `DeviceLocationSource` seam; sealed LocationFailures with denied→manual-picker fallback UX
- [x] Settings screen — 5 designed groups (calculation/notifications/appearance/privacy/about+credits), option sheets, per-prayer minute steppers; theme+locale apply live via app-scoped SettingsStore signals
- [x] Location picker — GPS path with priming text + denied/service-off banners, debounced city search with skeletons
- [x] Platform: Android location permissions, iOS NSLocationWhenInUse string
- [x] Tests (74 passing total): mapper round-trips, prefs round-trip, city search (prefix/diacritics/limit), tz conversion (Dhaka/London DST/date-line), location permission matrix, store persistence, settings screen widget tests
- [x] Debug APK build green

## Phase 3 — Prayer Times + Home ✅

- [x] Domain: PrayerDay (waqt starts/ends incl. overnight isha + fajrTomorrow), ActiveWaqt, CountdownTarget (kind/at/window/progress); adhan_dart wrapped behind PrayerDayRepository, UTC→wall via ZonedClock
- [x] Smart countdown pure function `resolveCountdownTarget` + `countdownUrgencyFor` — exhaustive branch tests (pre-fajr, gap, jamaat future/past/fixed/offset/none, midnight rollover, Ramadan sahri/iftar overrides, urgency thresholds)
- [x] Hijri converter (in-house tabular/Kuwaiti, civil epoch) + Bangla calendar (BD 2019 revision) with test vectors incl. design-brief sample dates
- [x] JamaatConfig sealed entities (fixed/offset/none) defined early for the state machine (full My Mosque feature = Phase 5)
- [x] Home screen: tri-calendar header (Gregorian·Hijri·Bangla for bn), countdown hero (5 states, 240ms transitions), prayer table (active-waqt highlight, Set-jamaat affordance, sunrise row, check stub), sahri/iftar row, empty-location state with CTA
- [x] One 1s `now` signal; computeds memoize so only the countdown subtree ticks
- [x] Compact <700dp adaptation (36px numeral, dense rows)
- [x] Tests (45 new, 119 total): state machine, activeWaqt boundaries, hijri/bangla calendars, adhan mapping (madhab/method/adjustments/ordering/plausibility), Home widget tests with fake clock (tick, states, empty)
- [x] Debug APK build green

## Phase 4 — Notifications ✅ (two follow-ups deferred)

- [x] `NotificationScheduler` domain interface; only `LocalNotificationsScheduler` (data) touches the plugin; pure `buildNotificationPlan` fills a 48h window from 3 computed days
- [x] Reschedule triggers: app open + debounced effect on location/params/matrix/locale changes (`NotificationController`); no location ⇒ cancelAll
- [x] Android: exact-alarm permission flow (`SCHEDULE_EXACT_ALARM`, falls back to inexact), boot/app-update receivers, `POST_NOTIFICATIONS`, core-library desugaring; battery-optimization guidance banner. iOS: permission request + denied education ("app stays fully useful")
- [x] Notification content per design §15: azan (per-matrix azan/beep/silent channels, "Mark as prayed" action), jamaat lead reminder, sahri warning, celebratory iftar, single evening muhasaba nudge — localized en+bn, foreign-city times convert via `utcInstantOf`
- [x] Notification matrix UI live: per-prayer 4-mode segments, sahri/iftar/jamaat/muhasaba toggles with lead-time steppers, linked from Settings
- [x] Tests (24 new, 143 total): plan builder (modes, leads, window/boundary trims, jamaat resolution, sorted unique ids), reschedule orchestration, utcInstantOf round-trip, controller triggers (debounce, locale re-resolution, idempotent start), matrix screen widget tests
- [ ] Notification-tap deep links (payload → route) — wired when target screens exist (Phase 7)
- [ ] Custom azan audio asset — polish pass (Phase 11)
- [x] Debug APK build green

## Phase 5 — My Mosque / Jamaat ✅ (seasonal profiles deferred)

- [x] Domain: MosqueProfile (Maghrib +5 default via `create`), MosqueState (multi-profile, active id, `activeConfig` fallback), repository + use cases (JamaatEntry sealed types landed in Ph3) — *built by subagent in parallel*
- [x] Persistence: prefs JSON blob `mosque_state_v1` (documented; migrates to drift if needed later); forward-compatible mapper skips corrupt/unknown entries
- [x] My Mosque screen: profile switcher chips + add/delete dialogs, per-prayer None/Offset/Fixed segments with offset steppers and time picker, reminder hint; reachable from More tab and Home's "Set jamaat"
- [x] Countdown integration: HomeStore.jamaatConfig now computed from MosqueStore.activeConfig; prayer-table jamaat column live; NotificationController reschedules on jamaat changes and passes config to the plan (jamaat reminders now fire)
- [x] Tests (31 new, 174 total): entities/model/datasource (subagent), store (defaults, per-profile updates, active switching, delete fallback), screen widgets (dialog flow, segments, switcher), Home integration ("JAMAAT IN" countdown + table times)
- [ ] Seasonal (summer/winter) profile pair — deferred as designed "advanced optional" (revisit in Phase 11 polish)
- [x] Debug APK build green

## Phase 6 — Qibla ✅

- [x] In-house `CompassMath` (pure Dart, subagent-built): great-circle qibla bearing, haversine distance, tilt-compensated heading from raw accel+mag (documented axis convention), shortest-arc smoothing, angular difference, 16-wind cardinals — decision logged: no compass package passed §3, sensors_plus raw streams + in-house math
- [x] Aligned state ±3°: gold dial/needle/arc + edge-triggered haptic (mediumImpact); CompassDial CustomPainter per ui.jsx spec (world-fixed tick ring, N in urgent color, center qalb medallion)
- [x] States: calibration banner (field-magnitude heuristic, figure-8 copy), sensor-unavailable verbal fallback ("Qibla is at N° WNW from north"), location-needed CTA; distance to Kaaba as quiet detail
- [x] Routes: `/qibla` top-level — Home header compass shortcut + More tab entry
- [x] Tests (46 new, 220 total): 37 math tests (reference bearings ±1.5°, wrap cases, synthetic tilt vectors), store (status transitions, smoothing convergence, single-fire haptic), screen states. Subagent caught a spec error: Dhaka→Kaaba is ~5,173 km, not ~4,780
- [x] analyze clean; debug APK verifying

## Phase 7 — Muhasaba ⬜

- [ ] Drift schema: tracker_items + daily_entries; archive-not-delete
- [ ] Default items seeded
- [ ] SQL aggregations (completion %, totals, streaks, heatmap, trend) as DAO queries
- [ ] Daily entry screen (3 input types, date switcher/back-fill)
- [ ] Custom field flow + archive flow
- [ ] Dashboard (range selector, ring, bars, heatmap, streaks, vs-previous)
- [ ] First-day & empty-range states; share card (4:5 export)
- [ ] Home prayer-check → Muhasaba writes
- [ ] No-guilt framing verified on every surface
- [ ] Tests: DAO aggregations/streaks, tracker row widgets

## Phase 8 — Quran ⬜

- [ ] `tool/quran_db_build.dart` (Tanzil/QUL; attributions stored)
- [ ] First-run asset→app-dir copy; drift open
- [ ] Surah list (search, juz, resume card)
- [ ] Reader (per-ayah actions, sticky header, translation/Arabic-only, 22–44px scale)
- [ ] Reading-settings sheet; first-open & search-empty states
- [ ] Deep link `/quran/:surah/:ayah`
- [ ] Tests: DB integrity (114/6236), bookmarks/last-read, search

## Phase 9 — Dua & Tasbih ⬜

- [ ] Dua content pipeline + categories → detail
- [ ] Tasbih counter (presets, ring, haptics, milestone pulse, save-before-reset, history)
- [ ] Asmaul Husna browse + detail
- [ ] Tests: counter/session logic

## Phase 10 — Ramadan, Calendar, Zakat ⬜

- [ ] Roza counter + dual countdowns + month table + fitra card; seasonal promotion
- [ ] Zakat calculator (pure Dart, nisab, breakdown) + tests
- [ ] Combined calendar (Greg+Hijri+Bengali, legend, day popover)
- [ ] Tests: hijri round-trips, Ramadan detection, zakat math

## Phase 11 — Onboarding, Lock & Polish ⬜

- [ ] Splash (≤2s, reduced-motion cut)
- [ ] Onboarding 7 steps + redirect gate + re-enterable from Settings
- [ ] App lock: PIN (in-house) + biometric
- [ ] RTL pass · Accessibility pass · Dark-theme pass · Performance pass
- [ ] Store assets (adaptive icon, feature graphic, 6 screenshots)
- [ ] Definition-of-Done checklist (plan §6) fully verified

---

## Worklog

> Newest first. One line per work session: date · what was done · result/blockers.

| Date | Work | Result |
|---|---|---|
| 2026-06-12 | Phase 6 (multi-agent): qibla compass — CompassMath pure math + 37 tests (subagent) parallel with sensor datasource, QiblaStore, CompassDial painter, 4 screen states, routes; 46 new tests | analyze clean, 220 tests pass — **Phase 6 complete** |
| 2026-06-12 | Phase 5 (multi-agent): My Mosque — backend (entities/model/prefs/repo + 18 tests) built by subagent in parallel with UI (profile switcher, per-prayer None/Offset/Fixed editor) and integration (Home countdown jamaat branch live, jamaat reminders scheduled); 31 new tests | analyze clean, 174 tests pass, APK builds — **Phase 5 complete** (seasonal profiles deferred to polish) |
| 2026-06-12 | Phase 4: notification scheduler — pure 48h plan builder, plugin wrapper (channels, exact alarms, boot receivers, desugaring), reschedule-on-change controller, matrix settings UI, en+bn notification copy, 24 new tests | analyze clean, 143 tests pass, APK builds — **Phase 4 complete** (deep links → Ph7, azan audio → Ph11) |
| 2026-06-12 | Phase 3: prayer-times domain (adhan_dart wrapper, PrayerDay, smart-countdown state machine), in-house Hijri + Bangla calendars, jamaat entities, full Home screen (hero countdown, prayer table, tri-calendar header, sahri/iftar row, empty state), 45 new tests | analyze clean, 119 tests pass, APK builds — **Phase 3 complete** |
| 2026-06-12 | Phase 2: settings+location — domain entities/usecases, GeoNames city DB (33.8k), TimezoneClock, prefs repo, geolocator with fallback UX, grouped Settings UI + location picker, live theme/locale, platform permissions, 37 new tests | analyze clean, 74 tests pass, APK builds — **Phase 2 complete** |
| 2026-06-12 | Phase 1 foundation: tokens→theme (M3), 4 font families bundled, l10n en+bn, motif painters, 11 shared widgets, DI+router shell (5 tabs), debug gallery, DEPENDENCIES.md, 37 tests | analyze clean, all tests pass, APK builds — **Phase 1 complete** |
| 2026-06-12 | Phase 0 cleanup: Firebase/config/env/template assets removed, pubspec+analysis_options+README+main.dart rewritten, SPM enabled (no CocoaPods), Android toolchain → Gradle 9.1.0/AGP 9.0.1/Kotlin 2.3.20 | analyze clean, tests pass, Android debug APK builds — **Phase 0 complete** |
| 2026-06-12 | Implementation plan + this progress tracker created | Docs ready; coding not started |
