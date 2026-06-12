# Qalbee — Progress Tracker

> Companion to `QALBEE_IMPLEMENTATION_PLAN.md`. Update this file in the same change as the work itself — phase status, task checkboxes, and a worklog line.
>
> **Status legend:** ⬜ Not started · 🔄 In progress · ✅ Done · ⏸️ Blocked/paused

## Phase Overview

| Phase | Title | Status | Notes |
|---|---|---|---|
| 0 | Cleanup & Baseline | ✅ | Done 2026-06-12; APK builds green on Gradle 9.1/AGP 9.0.1 |
| 1 | Foundation: Tokens, Theme, L10n, Shell | ⬜ | |
| 2 | Settings + Location | ⬜ | |
| 3 | Prayer Times Domain + Home | ⬜ | |
| 4 | Notification Scheduler | ⬜ | |
| 5 | My Mosque / Jamaat | ⬜ | |
| 6 | Qibla Compass | ⬜ | |
| 7 | Muhasaba | ⬜ | |
| 8 | Quran | ⬜ | |
| 9 | Dua & Tasbih + Asmaul Husna | ⬜ | |
| 10 | Ramadan, Calendar, Zakat | ⬜ | |
| 11 | Onboarding, App Lock & Polish | ⬜ | |

**Phase exit gate (applies to every phase):** `flutter analyze` zero warnings · all tests green · DEPENDENCIES.md updated · README updated if setup/tooling changed · design artboards matched (light + dark) · airplane-mode check passed.

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

## Phase 1 — Foundation ⬜

- [ ] Theme: `tokens.css` → ColorScheme + ThemeExtensions (light + dark)
- [ ] Fonts bundled: Schibsted Grotesk, Noto Sans Bengali, IBM Plex Sans Arabic, KFGQPC HAFS (+ license/attribution noted)
- [ ] Type scale + per-locale fallback chains
- [ ] L10n: ARB en + bn, digit formatting helper
- [ ] Motif: QalbMark/Star8/MotifBg painters in `shared/painters/`; icon set decision
- [ ] `config/` scaffold: app_config / assets / flavors
- [ ] Shared widget library (buttons, inputs, seg control, sheets, dialogs, ring, heatmap cell, bottom nav) with all interaction states
- [ ] DI locator + go_router shell (5 tabs, route constants, redirect stub)
- [ ] Debug widget gallery route
- [ ] Tests: button/countdown-shell goldens, digit formatting
- [ ] `docs/DEPENDENCIES.md` created; go_router/get_it/signals/intl logged

## Phase 2 — Settings + Location ⬜

- [ ] Domain: AppSettings, LocationConfig (sealed), PrayerParams, notification matrix model
- [ ] `tool/city_db_build.dart` + bundled city DB (license logged)
- [ ] Timezone rule: device→toLocal, manual city→IANA tz (single datasource, tested)
- [ ] Prefs-backed settings repo; geolocator wrapper with denied→manual fallback
- [ ] Settings screen (grouped sections)
- [ ] Tests: settings round-trip, foreign-city tz conversion, city search

## Phase 3 — Prayer Times + Home ⬜

- [ ] Domain: PrayerDay/Waqt/CountdownTarget; adhan_dart wrapped in data layer
- [ ] Smart countdown pure function `resolve(...)` — exhaustive branch tests
- [ ] Hijri converter (in-house) + test vectors
- [ ] Home screen: header, countdown hero (5 states), prayer table, sahri/iftar row
- [ ] One `now` signal; countdown-subtree-only rebuilds
- [ ] Compact (360×640) + tablet adaptations
- [ ] Tests: state machine, param mapping, countdown card widget states

## Phase 4 — Notifications ⬜

- [ ] NotificationScheduler behind domain interface; ~48h window; reschedule triggers
- [ ] Android exact-alarm flow + battery-optimization guidance; iOS priming + denied education
- [ ] Notification content per design artifacts; "Mark as prayed" deep link
- [ ] Settings notification matrix UI live
- [ ] Tests: scheduling-window logic, reschedule triggers

## Phase 5 — My Mosque / Jamaat ⬜

- [ ] Domain: JamaatEntry sealed (fixed/offset/none), MosqueProfile (multi, active, seasonal)
- [ ] Persistence (documented choice) + profile switcher UI
- [ ] Countdown jamaat branch on real config; jamaat reminders scheduled
- [ ] Tests: jamaat resolution, countdown integration

## Phase 6 — Qibla ⬜

- [ ] Bearing via adhan_dart; tilt-compensated heading (package decision logged)
- [ ] Aligned state ±3° + haptic; calibration, sensor-unavailable, location-needed states
- [ ] Distance to Kaaba
- [ ] Tests: bearing math, tolerance, smoothing

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
| 2026-06-12 | Phase 0 cleanup: Firebase/config/env/template assets removed, pubspec+analysis_options+README+main.dart rewritten, SPM enabled (no CocoaPods), Android toolchain → Gradle 9.1.0/AGP 9.0.1/Kotlin 2.3.20 | analyze clean, tests pass, Android debug APK builds — **Phase 0 complete** |
| 2026-06-12 | Implementation plan + this progress tracker created | Docs ready; coding not started |
