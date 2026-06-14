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
| 7 | Muhasaba | ✅ | Done 2026-06-12 (3-way multi-agent); 251 tests green, APK builds |
| 8 | Quran | ✅ | Done 2026-06-13 (multi-agent); 4.9MB DB, reader live |
| 9 | Dua & Tasbih + Asmaul Husna | ✅ | Done 2026-06-13 (multi-agent); 43 duas, 99 names |
| 10 | Ramadan, Calendar, Zakat | ✅ | Done 2026-06-13 (multi-agent) |
| 11 | Onboarding, App Lock & Polish | ✅ | Core done 2026-06-13; polish passes remain (RTL/a11y/store assets) |

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

## Phase 7 — Muhasaba ✅ (share card → Ph10, lock → Ph11)

- [x] Drift schema (subagent): tracker_items + daily_entries (yyyymmdd int dates), schemaVersion 1, drift_flutter open; archive = flag update only, entries always preserved
- [x] Default items seeded once (5 salah + quran/azkar/sadaqah/tahajjud/roza), l10n-key names en+bn
- [x] SQL aggregations as DAO customSelects: per-day completion fractions (CASE/MIN respecting targets), per-item daysDone/totals, day-done flags → bounded streak walk (400d window), previous-window completion for trend
- [x] Daily entry view: salah chip row, 3 distinct input types (toggle / count stepper / +5-min duration stepper), date switcher with back-fill (future blocked)
- [x] Custom field flow: name/type/target/curated icon+color picker sheet; archive-with-explanation (restore too); defaults structurally locked
- [x] Dashboard (subagent): Today/Week/Month/Year segments, completion ring, streak chips, vs-previous (±0.05 band, q.ok for up — never shame colors), in-house TrendLine painter, weekday-aligned heatmap + "Not yet" legend, per-item bars
- [x] First-day welcome + empty-range states
- [x] Home prayer-check circles live → toggle today's salah entries (tested both directions)
- [x] No-guilt framing: level-0 heatmap "Not yet", down-trend copy "A fresh start — keep going", urgent color never used
- [x] Tests (77 new, 251 total): 16 DAO (fractional completions, streak scenarios, archive math), 8 store, 6 screen, prayer-check integration, helpers
- [ ] Ramadan share card (4:5 export) — deferred to Phase 10 (Ramadan section) where it belongs contextually
- [ ] PIN/biometric lock for the section — Phase 11 (with app lock, as planned)
- [x] Debug APK build green

## Phase 8 — Quran ✅

- [x] `tool/quran_db_build.dart` — fawazahmed0/quran-api CDN → 4.9MB sqlite (114 surahs / 6236 ayahs, validated); attributions: Tanzil Simple text, Pickthall (EN, public domain), Muhiuddin Khan (BN). **Polish TODO:** switch to full Uthmani-script edition
- [x] First-run asset→documents copy with user_version check; bookmarks/last_read preserved across re-copies; opened via drift (raw customSelect, no codegen)
- [x] Surah list: resume card, debounced diacritic-light search, Star8 medallions, first-open banner (juz tab = optional, skipped)
- [x] Reader: RTL Arabic at user scale (22–44 step 2, persisted), per-ayah bookmark/copy/share-stub, scroll progress, settings sheet (font slider + translation toggle), markRead debounce
- [x] Deep links `/quran/:surah` + `/quran/:surah/:ayah` wired in the router
- [x] Tests: 6 asset-integrity + 16 repo/store/screen (temp-copy isolation so the committed asset is never written)

## Phase 9 — Dua & Tasbih ✅

- [x] Bundled data: 43 authentic duas / 8 categories (ar+tr+en+bn+ref+repeat) + all 99 Asmaul Husna (bn meanings included); 10 integrity tests
- [x] Landing (feature cards + category grid), category detail (Arabic/translit/translation/ref/repeat chip)
- [x] Tasbih: full-screen tap surface, 33/100/custom presets, progress ring, light haptic per tap + milestone pulse (reduced-motion aware), save-before-reset confirm, per-day session total
- [x] Asmaul Husna browse + detail
- [x] Tests: tasbih store (haptics, milestone-once, rollover), screens, data parsing

## Phase 10 — Ramadan, Calendar, Zakat ✅

- [x] Ramadan hub: roza counter (Day N of 29/30) / days-until outside Ramadan, full-month sahri-iftar table (today highlighted), fitra info card; lives in More year-round
- [x] Zakat calculator: pure Dart (MIN(gold,silver) nisab documented, 2.5%, negative-clamped, breakdown), form + result UI — below-nisab framed neutrally
- [x] Combined calendar: Greg+Hijri(+Bangla bn) per day, Islamic-event dots + legend (10 events), day sheet with all three dates + prayer times; hijri month-range header
- [x] Tests: 38 domain (zakat/ramadan-utils/islamic-dates) + store tests (roza day 12 on 1 Mar 2026, month rows, no-location)
- [x] Ramadan share card — folded into Muhasaba dashboard backlog (polish)

## Phase 11 — Onboarding, Lock & Polish ✅ core (polish passes open)

- [x] Splash: mark draw-in 1.2s, reduced-motion cut, decides onboarding/lock/home
- [x] Onboarding 7 steps (welcome→language→location→madhab→region-suggested method→notification priming+skip→bismillah); router redirect gate on setupComplete; re-enterable via Settings "Run setup again"
- [x] App lock: salted SHA-256 PIN (raw never stored) + biometric (local_auth, SPM), lock/setup screens, router gate with signal-driven refresh, Settings toggle
- [x] Gate tests: onboarding redirect, PIN unlock landing on shell
- [ ] RTL pass · a11y pass · dark pass · perf pass — NEXT session (needs Arabic locale + screen-by-screen review)
- [ ] Store assets (~~adaptive icon~~ done, feature graphic, screenshots) — NEXT
- [ ] Custom azan audio; Uthmani script switch — NEXT

---

## Worklog

> Newest first. One line per work session: date · what was done · result/blockers.

| Date | Work | Result |
|---|---|---|
| 2026-06-14 | **Home UI polish (user-requested, "make it more joss" — palette-locked to the Islamic brand: teal/honey, no new hues):** Six upgrades. **(1) Time-of-day sky on the countdown hero** — `CountdownCard` gains a `SkyPhase` (dawn/morning/day/evening/night) that paints a faint top→surface gradient drawn ONLY from brand tokens (`primarySoft` teal / `accentSoft` honey / `surface2`); applied to the **calm** state only so semantic amber/urgent/sahri/iftar keep their flat colour. Phase derived from the day's sun events in `home_screen._skyPhase` (read inside the per-second countdown builder, so no extra rebuilds). **(2) Tools hub** — new presentational `QuickActionsRow`/`QuickAction` (round `primarySoft` icon buttons). *(Revised after user feedback: dropped bottom-nav duplicates (Quran/Dua) — the navbar already is a quick action — so the hub holds only **buried** features with no nav tab and no home card: Qibla · Hadith · Calendar · Calculators. Moved from under the header to **below the muhasaba "namaz counter" card**, keeping the top focused on prayer info.)* **(3) Continue-reading card** — new `ContinueReadingCard` driven by `QuranStore.lastRead` (surah + ayah, tap → reader). **(4) Staggered entrance** — new reusable `shared/widgets/StaggeredEntrance` (fade+slide, 60ms/index, capped at 10; **cuts** under `disableAnimations`); every home section now cascades in. **(5) Header greeting** — time-of-day line via a new memoized `HomeStore.daypart` computed (flips only at boundaries, no per-second home rebuild). **(6) Muhasaba ring animates** 0→completion on load (`TweenAnimationBuilder`, zero-duration under reduced motion). **Sahri/Iftar row kept and moved to the very bottom** (user instruction). Home feed re-ordered into a `sections` list mapped through `StaggeredEntrance`. 7 new l10n keys en+bn (4 greetings, `quickDua`, `continueReadingAyah`). New widget tests (quick-actions, continue-reading, staggered-entrance) + countdown gradient/sky-phase tests; home_screen tests updated to scroll to the now-lower muhasaba card. *(3 subagents designed the new widgets but hit Write-denied in their sandbox → files authored in the main loop.)* | analyze clean, **full suite green (518 tests)** |
| 2026-06-14 | **Tweak (user-requested):** Gave the qibla chip a real **Kaaba** glyph (Material has none). New `shared/painters/kaaba_mark.dart` — `KaabaMark` CustomPainter draws a single-colour cube with the kiswa band + door carved out (even-odd, so the glass shows through). The chip now stacks the rotating needle over the `KaabaMark` (tinted with the card foreground) beside the degrees; replaced the placeholder `Icons.mosque`. Chip test asserts `KaabaMark` instead. | analyze clean, **509 tests pass** |
| 2026-06-14 | **Tweak (user-requested):** Redesigned the qibla indicator to **fit the countdown hero card**. The old fixed `primarySoft`+`ink` pill clashed with the card's state-tinted backgrounds (amber/urgent/sahri/iftar). `CountdownCard` now exposes a `corner` builder slot — `Widget Function(Color foreground)` rendered top-right with the card's live `c.fg` — so the chip self-tints per state. `QiblaMiniChip` reworked into a compact **glass pill** (`foreground.withValues(alpha: .12)` wash, fg-tinted rotating arrow + degrees; `explore_off`+label when no location). Home passes `corner: (fg) => QiblaMiniChip(foreground: fg, …)`; the earlier `Stack`/`PositionedDirectional` wrap in home was removed. Chip test updated for the new glass design (+ a foreground-tint assertion). | analyze clean, **509 tests pass** |
| 2026-06-14 | **App icon (user-requested):** Designed and set the **Qalbee launcher icon** — gold *qalb* (heart, parametric path) with a crescent-moon + 5-point-star carved as negative space, on the brand teal `#15564D`→`#0C3C36` gradient with a soft cream radial glow. Generated programmatically with Pillow (`tool/gen_icon.py`, 4× supersampled→LANCZOS for clean edges): `assets/icon/qalbee_icon.png` (1024 full) + `assets/icon/qalbee_icon_foreground.png` (heart-only, 66% safe-area, transparent — Android adaptive). Wired `flutter_launcher_icons` (dev dep + pubspec config) and generated **Android** (legacy + adaptive `#15564D` bg, colors.xml), **iOS** (remove_alpha), **web** (192/512 + maskable), and **macOS** icon sets, replacing the default Flutter icons. | `dart run flutter_launcher_icons` ✓ all platforms generated |
| 2026-06-14 | **Tweak (user-requested):** Reordered the Home feed and relocated the qibla affordance. **Ayah of the day** + **Hadith of the day** cards moved to the **bottom** of the list (after the sahri/iftar + special-times cards), so the actionable prayer/muhasaba/tasbih cards stay above the fold. The standalone top-row **`QiblaMiniChip`** was removed and is now pinned to the **top-right corner of the countdown (salat start/end) hero card** via a `Stack` + `PositionedDirectional` overlay (live bearing, tap → full compass; the chip's own tap wins over the card's day-timeline tap). `TasbihQuickCard`'s temporary `trailing` slot was reverted. | analyze clean, **508 tests pass** |
| 2026-06-14 | **Follow-up (user decision → native-only WidgetKit):** Reworked the home-screen widget off the `home_widget` plugin (it has no iOS SPM support → would force CocoaPods, breaking the SPM-only policy). Now **plugin-free on both platforms** via a single `MethodChannel("com.qalbee.qalbee/widget")` ([[home-widget-ios-spm]]): `WidgetBridge` (the only impure call site, injected into `PrayerWidgetService` for testability). **Android:** `QalbeeWidgetProvider` now extends plain `AppWidgetProvider`, reads the `qalbee_widget` SharedPreferences; `MainActivity` handles the channel (writes prefs + `updateAll`); manifest receiver kept. **iOS (source complete, needs a one-time Xcode target add — can't be scripted):** `AppDelegate.swift` channel writes the snapshot to App Group `group.com.qalbee.qalbee` UserDefaults + `WidgetCenter.reloadAllTimelines()`; native **WidgetKit** extension `ios/QalbeeWidget/` (TimelineProvider + SwiftUI medium widget, brand #15564D, 15-min refresh policy) + entitlements + `ios/Runner/Runner.entitlements`; step-by-step `ios/QalbeeWidget/SETUP.md`. Removed the leftover `ios/Podfile`. | analyze clean, **508 tests pass** (+widget_bridge); Android debug APK builds (23s); **iOS widget build unverified here** — needs the Xcode Widget Extension target per SETUP.md. Remaining: widget background refresh on Android (currently app-driven only) |
| 2026-06-14 | **Feature (user-requested, 5-way multi-agent):** Added a batch of **home-screen interactions**. New self-contained presentational widgets built in parallel by subagents (data+callback constructors, no store access — testable in isolation, mirroring `PrayerTable`/`SpecialTimesCard`): **`PrayerDetailSheet`** (tap any waqt row → bottom sheet with time window, jamaat, per-prayer rakaat pills from a const fard/sunnah/witr table, and a fazilat note), **`DailyAyahCard`** (Ayah of the day — deterministic day-of-year pick from a curated short-verse list via `QuranStore`, RTL arabic + locale translation, tap → Quran), **`TasbihQuickCard`** (inline counter over `TasbihStore` — ring tap counts w/ its own haptic, reset, open-full), **`QiblaMiniChip`** (live bearing from `CompassMath` on the home location — sensor-free, no always-on magnetometer; tap → full compass), **`DayTimelineSheet`** (countdown card tap → vertical 5-waqt timeline w/ active "Now" marker). Main-loop wiring in `home_screen`/`prayer_table`: row-tap + **haptic + animated check** (AnimatedContainer/Switcher) + **active-waqt icon pulse** (`_WaqtIcon`), `RefreshIndicator` pull-to-refresh (reloads tasbih + ayah), and a **streak-milestone badge** on the muhasaba card (7/30/100/365…). 14 new l10n keys en+bn. Each new widget ships its own widget test (~20 cases); registered `TasbihStore` (+ `makeTasbihStore` fake) across the shell test harnesses. Also added the missing `setting_labels` import in the concurrent `home_widget` service (undefined `l10n.prayerLabel` tear-off) so the suite compiles. | analyze clean, **507 tests pass** |
| 2026-06-14 | **Feature (user-requested, 3-way parallel):** Shipped **(2) home-screen widget** + **(3) Hadith of the day + Dua search/favorites**. *Widget* (Android + Flutter, main loop): added `home_widget` dep, pure `resolveNextPrayer`/`buildWidgetPayload` (next waqt + 5-time strip, all Dart-formatted so native needs no l10n), `PrayerWidgetService` (only plugin touch point), Android `QalbeeWidgetProvider` (HomeWidgetProvider) + layout/info/bg XML + manifest receiver; `effect()` in the locator repaints on app-open & location/params/locale change. *Hadith* (subagent): new `lib/features/hadith/` — 40 authentic hadith asset (ar/en/bn/narrator/ref), entity/datasource/repo/store with deterministic `ofDay`, `HadithCard` on Home (daily, below the ayah card) + `HadithScreen` collection (route `/hadith`, More-tab entry). *Dua* (subagent): `DuaFavoritesStore` (prefs `dua_favorites_v1`), public `DuaCard` with favorite-heart toggle, `DuaSearchDelegate` (search all duas by translit/translation/ref), favorites section on the dua landing. Wired routes/locator/home/more + 17 new l10n keys en+bn. **Also fixed a latent bug** in `_WaqtIcon` (prayer_table): the `late final` AnimationController initialised lazily in `dispose()` for non-pulsing icons → unsafe TickerMode ancestor lookup crash; now created eagerly in `initState` (this resolved the 8 pre-existing `home_screen_test` failures noted below). | analyze clean, **507 tests pass** (hadith 12, dua 33, widget 6, +home), debug APK builds (108s). **Open follow-ups:** iOS widget needs an Xcode WidgetKit extension target (`home_widget` has no SPM support — conflicts with the SPM-only policy; decide CocoaPods-exception vs native-only); widget background/periodic refresh (currently app-driven only) |
| 2026-06-14 | **Feature (user-requested):** Surfaced the existing **Zakat calculator** (was buried under More→Ramadan) and added **four new Islamic calculators** in a new `lib/features/calculators/` feature, built 4-way multi-agent (pure domain + screen + tests each): **Fitra/Sadaqatul Fitr** (staple × kg-price × people), **Qaza Salah** (missed-prayer estimate over a date range, optional Witr), **Inheritance/Faraid** (classical Sunni shares — spouse/parents/children/full-siblings, exact integer-fraction math with 'Awl + Radd + Umariyyatayn, scholar disclaimer), and a universal **Age calculator** (Gregorian **and** Hijri via in-house `HijriDate`). New **Calculators hub** in More groups all five; Zakat still lives in the Ramadan hub too. Routes (`calculators`/`fitra`/`qaza`/`faraid`/`age`) + en/bn l10n (~60 keys). Main-loop fixes to agent output: ListTile-in-DecoratedBox assertions (Material wrap), off-screen Calculate buttons in widget tests (tall viewport), deprecated `activeColor`→`activeThumbColor`, lints | analyze clean for calculators; **76 calculators tests + router suite green** (66 domain + 10 widget + 2 router-nav tests added). After the concurrent `home_widget` service was fixed (missing `setting_labels` import for the `l10n.prayerLabel` extension tear-off — root cause was the import, not a missing key), the **full suite is green at 508 tests, analyze clean** |
| 2026-06-14 | **Tweak (user-requested):** Replaced the generic leading bullet/dot before each row on Home with a waqt-specific icon. Prayer table rows now show a per-prayer glyph (fajr `wb_twilight`, dhuhr `wb_sunny_outlined`, asr `brightness_6_outlined`, maghrib `brightness_4_outlined`, isha `nightlight_outlined`) via `_PrayerRow._iconFor`; active-row uses the row foreground/primary, others `ink3`. Special-times card rows likewise swap the 6px dot for a per-window icon (`_Row._iconFor`) tinted with the group accent | analyze clean, related tests pass |
| 2026-06-14 | **Follow-up (user-requested):** Expanded the nafl set from 3 → **5 windows**: split the merged "Ishraq & Chasht" into separate **Ishraq** (sunrise+15m → +30m) and **Duha/Chasht** (→ zawal), and added **Salat al-Zawal** (right after the sun declines past istiwa, `dhuhr → dhuhr+15m` — distinct from the *forbidden* zawal which stays in the forbidden card). New `SpecialTime.duha`/`.salatZawal` enum values, `resolveSpecialWindows` bounds, per-window icons, and l10n labels + detail descriptions en+bn. Unit-test shape (8 windows, F×3+N×5) + new bound tests; card/screen/home label assertions updated | prayer_times tests green (29); **note:** unrelated `lib/features/calculators` (fitra/zakat WIP) has missing `fitra*` l10n keys — pre-existing, not from this change |
| 2026-06-14 | **Follow-up (user-requested):** Split the forbidden/nafl times into **two separate cards** (was one card with a divider), each with a 2-line explanatory subtitle (`forbiddenTimesSubtitle`/`naflTimesSubtitle`) + chevron. Each card opens its **own** detail page — `SpecialTimesCard.onTap` is now `void Function(SpecialKind)`; tapping pushes `Routes.specialTimes` with `extra: (kind, windowsOfKind)`. `SpecialTimesScreen` is kind-scoped (AppBar title + intro + window cards for just that kind, accent urgent/ok): forbidden page = *what & why* (`forbiddenTimesIntro`) + 3 windows; nafl page = `naflTimesIntro` + 3 windows. Per-window full descriptions (`specialDetail*` × 6, hadith-grounded) via new `specialTimeDetail` extension. ~16 new l10n keys en+bn. Card-tap (per-kind) + both detail-page widget tests added | analyze clean, **381 tests pass** |
| 2026-06-14 | **Feature (user-requested):** Added a forbidden (makruh) + nafl times card on Home (below the sahri/iftar row). New pure usecase `resolveSpecialWindows(PrayerDay)` derives 6 windows from the day's sun/prayer times — forbidden: after-sunrise (+15m), zawal (dhuhr −6m), before-sunset (−15m); nafl: Ishraq/Chasht (sunrise+15m → zawal), Awwabin (maghrib → isha), Tahajjud (last third of night → next fajr). `SpecialTime`/`SpecialWindow` entities + `containsAt`. `HomeStore.specialWindows` (flips daily) and `activeSpecial` (`SpecialTime?`, memoized so no per-second rebuild). `SpecialTimesCard` widget: two labeled groups (urgent/ok accents), active window soft-highlighted with a "Now" pill. New l10n keys en+bn (`forbiddenTimesTitle`, `naflTimesTitle`, `specialNow`, 6 `specialTime*` labels). 13 unit + 3 card-widget + 1 home tests | analyze clean, **376 tests pass** |
| 2026-06-14 | **Bugfix (user-reported):** Salah whose waqt hadn't started yet (e.g. Asr/Maghrib/Isha earlier in the day) could still be checked off in Muhasaba + the Home table. Added time-gating: `MuhasabaStore.lockedSalah` (via injected `lockedSalahOn(date)` wired in the locator from `GetPrayerDay`+`ZonedClock`; past dates/no-location lock nothing) blocks `setValue`/`togglePrayerToday` for not-yet-started salah. Home table gets a memoized `HomeStore.lockedPrayers` (int-mask so it doesn't rebuild per second) → locked rows show a quiet clock icon instead of the check; Muhasaba salah chips render dimmed + clock icon, taps ignored. Store + screen + home tests added | analyze clean, **362 tests pass** |
| 2026-06-14 | **Follow-up (user-requested):** Tapping a locked (not-yet-time) salah now shows a floating SnackBar toast ("This prayer's time hasn't started yet", new `salahLockedToast` l10n en+bn) instead of doing nothing — wired on both the Home table (locked clock affordance is now a tappable `InkWell` via `onLockedTap`) and the Muhasaba salah chip. Toast assertions added to both screen tests | analyze clean, **362 tests pass** |
| 2026-06-14 | **Feature (user-requested):** Added a minimal muhasaba-track card on Home below the prayer table — a compact ~80px `_MuhasabaCard`: small completion ring (today's %, via `stats.days.last`), title, a **done/total count** ("3/10 done", computed from `items`+`entries` via `TrackerItem.isDone`, guarded by `selectedIsToday`), and a compact 🔥streak (shown only when >0); tappable → muhasaba tab (`context.goNamed`). New `muhasabaDoneCount` l10n key (en+bn). Reads `MuhasabaStore` reactively so prayer-checks update the ring + count live. Render + live-count tests | analyze clean, **359 tests pass** |
| 2026-06-14 | **Tweak (user-reported):** Removed the Sunrise row under Fajr in the home prayer table (`_SunriseRow` + insertion deleted; table is now the 5 prayers only). Sunrise/sunset still shown in the countdown card footer. Updated home_screen test to assert table no longer renders 'Sunrise' | analyze clean, home_screen tests pass (7) |
| 2026-06-14 | **Bugfix (user-reported):** Home countdown progress bar looked broken. `CountdownCard`'s `FractionallySizedBox` used its default `Alignment.center`, so the fill grew from the middle outward (the outer `Align(centerStart)` was dead — FSB already took full width). Anchored the fill with `alignment: AlignmentDirectional.centerStart`, dropped the redundant `Align`, pinned track `width: double.infinity`; added a start-anchor regression test | countdown_card tests pass (9) |
| 2026-06-13 | Phases 8–11 (6 subagents + main loop in parallel): Quran pipeline+reader, dua/asma data+screens, tasbih, ramadan/zakat/calendar, splash/onboarding/app-lock with router gates; merged, lints/tests repaired, gates tested | analyze clean, **357 tests pass** (dua agent resumed post-reset and added its suites), onboarding verified on emulator — commits c4d3c2f + e0e107c. Open: RTL/a11y/dark/perf passes, store assets, azan audio, Uthmani text switch |
| 2026-06-12 | **Bugfix (user-reported):** blank screens, nav bar floating mid-screen on device. Bisected with probe entrypoints on the Pixel 8 emulator → `_NavDestination`'s Column defaulted to `mainAxisSize.max` inside the Scaffold's loosely-constrained bottomNavigationBar slot, so the nav swallowed the full screen height. One-line fix (`mainAxisSize.min`) + geometry regression test. Verified on emulator with screenshots | 252 tests pass; app renders correctly on device |
| 2026-06-12 | Phase 7 (3-way multi-agent): Muhasaba — drift DB + SQL aggregations (agent 1, 16 DAO tests), full Today/Dashboard screen (agent 2, 6 tests), domain/store/widgets/editor + Home prayer-check integration (main loop); 77 new tests | analyze clean, 251 tests pass, APK builds — **Phase 7 complete** (share card → Ph10, lock → Ph11) |
| 2026-06-12 | Phase 6 (multi-agent): qibla compass — CompassMath pure math + 37 tests (subagent) parallel with sensor datasource, QiblaStore, CompassDial painter, 4 screen states, routes; 46 new tests | analyze clean, 220 tests pass — **Phase 6 complete** |
| 2026-06-12 | Phase 5 (multi-agent): My Mosque — backend (entities/model/prefs/repo + 18 tests) built by subagent in parallel with UI (profile switcher, per-prayer None/Offset/Fixed editor) and integration (Home countdown jamaat branch live, jamaat reminders scheduled); 31 new tests | analyze clean, 174 tests pass, APK builds — **Phase 5 complete** (seasonal profiles deferred to polish) |
| 2026-06-12 | Phase 4: notification scheduler — pure 48h plan builder, plugin wrapper (channels, exact alarms, boot receivers, desugaring), reschedule-on-change controller, matrix settings UI, en+bn notification copy, 24 new tests | analyze clean, 143 tests pass, APK builds — **Phase 4 complete** (deep links → Ph7, azan audio → Ph11) |
| 2026-06-12 | Phase 3: prayer-times domain (adhan_dart wrapper, PrayerDay, smart-countdown state machine), in-house Hijri + Bangla calendars, jamaat entities, full Home screen (hero countdown, prayer table, tri-calendar header, sahri/iftar row, empty state), 45 new tests | analyze clean, 119 tests pass, APK builds — **Phase 3 complete** |
| 2026-06-12 | Phase 2: settings+location — domain entities/usecases, GeoNames city DB (33.8k), TimezoneClock, prefs repo, geolocator with fallback UX, grouped Settings UI + location picker, live theme/locale, platform permissions, 37 new tests | analyze clean, 74 tests pass, APK builds — **Phase 2 complete** |
| 2026-06-12 | Phase 1 foundation: tokens→theme (M3), 4 font families bundled, l10n en+bn, motif painters, 11 shared widgets, DI+router shell (5 tabs), debug gallery, DEPENDENCIES.md, 37 tests | analyze clean, all tests pass, APK builds — **Phase 1 complete** |
| 2026-06-12 | Phase 0 cleanup: Firebase/config/env/template assets removed, pubspec+analysis_options+README+main.dart rewritten, SPM enabled (no CocoaPods), Android toolchain → Gradle 9.1.0/AGP 9.0.1/Kotlin 2.3.20 | analyze clean, tests pass, Android debug APK builds — **Phase 0 complete** |
| 2026-06-12 | Implementation plan + this progress tracker created | Docs ready; coding not started |
