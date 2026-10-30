# Review Fix Plan — 2026-10-29

> **For Claude Code.** Built from a two-part external review of this repo (2026-10-29).
> Do **only the phase you were asked to do**, then stop and report (format at the end).
> If the code doesn't match what this plan describes (file moved, already fixed,
> different behavior), stop and say so — don't force the change.

The binding rules in `docs/PRODUCTIVE_MUSLIM_DEVELOPMENT_GUIDE.md` still apply. Where this
plan is more specific, this plan wins.

## Status — 2026-10-29 (all done items merged into `master`)

| Item | Status |
|---|---|
| 1.1 credits, 1.2 ledger, 1.3 `--no-bengali` switch, 1.4 `focusBlocking` | ✅ done |
| 1.2 worklog backfill (2026-10-27 → 29, added in this plan revision) | ⏳ not started |
| 2.1–2.4 Jamaat Focus native | ✅ done |
| 3 CI android job | ✅ done — never run on GitHub yet (branch not pushed) |
| 4.1–4.4 | ✅ done |
| 4.5 end-to-end flow test (added in this plan revision) | ⏳ not started |
| 5.1 architecture ratchet (baseline 96 → 92) | ✅ done |
| 5.2 onboarding `AppLockStore`, qibla `QiblaStore`, notifications → `JamaatFocusControl` | ✅ done |
| 5.2 `SettingsStore` + `setting_labels.dart` (pick an option, justify) | ⏳ not started |
| 5.2 `prayer_widget_service.dart` off presentation (do together with the item above) | ⏳ not started |
| 5.2 `arabicBodySize()` → injected reading preferences | ⏳ not started |
| 6 proposals (export/import, expenses+fasting → drift, Android Keystore lock) | ⏳ not written |
| Owner decisions 1–5 | ⏳ unanswered |

Findings that change this plan:
- `md-rifatkhan/hadithbangla` is gone (404); the snapshot is `azharcse14/hadithbangla`
  (fork of `mohacelhosen/hadithbangla`) — no license on any of them.
- `aminurdev/dua-ruqya-server` (90 `hm_*` duas) has no license → `NO LICENSE` in the ledger.
- Tanzil translations are non-commercial only; Pickthall and Muhiuddin Khan are `UNVERIFIED`.
- `hadith_books.json` still carries 330 hadithbangla Bengali chapter titles; the 1.3 switch
  doesn't strip them — owner to decide.
- Widget QA: with 7 days pushed, the stale state needs clock **+8 days**, not +3.
- Alarm allowlist allows every `ACTION_SHOW_ALARMS` handler (not only a default); needs a
  `<queries>` manifest entry on Android 11+.
- Cross-feature imports are 77, not ~40; data→presentation was 5 (incl. `local_auth_biometric`).
- ~~`NotificationKind.index` / `Prayer.index` build notification ids~~ — fixed 2026-10-30 (stable
  `NotificationKind.code` + explicit prayer slots, branch `fix/deep-review-2026-10-30`).
- `dart format` over `lib/` + `test/` reformats ~60 untouched files (formatter version drift).
- A fresh worktree needs `flutter pub get` before `flutter gen-l10n`, or the l10n gate fails.

Manual QA outstanding: API 36 back gesture keeps the cover; alarm not covered; Bengali
TalkBack "ফোন"; `focusBlocking=false` build on device; widget +8 days stale state; iOS widget
target (never added to the Xcode project — `ios/ProductiveMuslimWidget/SETUP.md`).

---

## Ground rules

1. **Gates before every commit** — all must pass:
   ```sh
   flutter gen-l10n && git diff --exit-code -- lib/core/l10n/gen
   flutter analyze            # zero issues
   flutter test               # all green
   flutter build apk --debug  # whenever android/, ios/ or a platform channel changed
   ```
2. **One branch per phase**, from `master`: `fix/review-p<N>-<slug>`. Conventional commits
   (`fix(scope): …`). Don't merge into `master`.
3. **Ask the owner first** before: adding any package; editing religious text (Quran,
   hadith, dua, ruqyah wording or references); anything under *Owner decisions*.
4. **Never:** add `// ignore:` or loosen `analysis_options.yaml`; write a license or source
   you haven't verified (write `UNVERIFIED` instead); delete user data or bundled content;
   touch release signing.
5. **l10n:** every new user-facing string goes in `app_en.arb` **and** `app_bn.arb`
   (natural Bengali; spell নামাজ). Native strings: Android `values/` + `values-bn/`,
   iOS String Catalog (en + bn), or pushed from Dart.
6. **Docs in the same commit:** a worklog row in `docs/PRODUCTIVE_MUSLIM_PROGRESS.md`;
   update `docs/DEPENDENCIES.md` whenever packages, content or licenses change.
7. **Parallel agents:** at most one agent per phase. Phases 1–4 touch mostly separate files
   and may run in parallel worktrees. Phase 5 runs alone, after 1–4 are merged.
8. Phase 3 is small and guards every native change — do it early.

---

## Phase 1 — Release blockers: attribution, licensing, store policy

### 1.1 In-app credits and source labels

**Problem.** `creditsBody` in `lib/core/l10n/arb/app_en.arb` / `app_bn.arb` credits only
GeoNames and the fonts; nothing in `lib/` mentions Tanzil, Pickthall or Muhiuddin Khan.
Tanzil's terms ask apps to name the Tanzil Project and link to tanzil.net.
`hadithSourceNoteBn` calls hadithbangla "open source", but its upstream repo has no license.

**Do.**
- Credits: one entry per bundled source. Take names and editions from the attribution
  lines in `tool/quran_db_build.dart` and `tool/hadith_db_build.dart` — don't invent.
  - Quran text — Tanzil Project, with a tappable https://tanzil.net link (reuse
    `ExternalLauncher` from `lib/features/nearby_mosques/domain/external_launcher.dart`)
  - English translation — Mohammed Marmaduke William Pickthall
  - Bengali translation — Muhiuddin Khan (via Tanzil)
  - Hadith Arabic/English — fawazahmed0/hadith-api (Unlicense)
  - Bengali hadith — hadithbangla project (github.com/md-rifatkhan/hadithbangla)
  - Duas — the source recorded in the 2026-06-15 dua-import worklog row (Hisnul Muslim via
    aminurdev/dua-ruqya-server); ruqyah — as recorded in its 2026-06-14 worklog rows
  - City database — GeoNames (CC BY 4.0); fonts as today
- `hadithSourceNoteBn` (en + bn): drop "(open source)" — e.g. "Bengali source: hadithbangla project".

**Done when.** New `test/core/l10n/credits_copy_test.dart` (same style as
`test/core/l10n/privacy_copy_test.dart`): both ARB files contain `tanzil.net`; the English
credits name Pickthall, Muhiuddin Khan and GeoNames; no ARB string calls hadithbangla
open source (`open source` / `ওপেন সোর্স`).

### 1.2 Content and license ledger; worklog backfill

**Problem.** "Fonts & Data Licenses" in `docs/DEPENDENCIES.md` is stale: the dua row says
43 duas / 8 categories (PROGRESS says 127 / 18); `ruqyah.json`, `hadith.json` and
`hadith_books.json` have no row; the Bengali Quran translation has no license status; the
Bengali hadith row doesn't say its upstream has no license.

**Do.** One row per file in `assets/data/`, with counts read from the files themselves.
Columns: asset · source (repo + edition/path) · license as stated by the source ·
status (`OK` / `UNVERIFIED — owner to confirm` / `NO LICENSE — permission needed`) · checked date.
- Bengali hadith: `NO LICENSE — permission needed` (no LICENSE file in
  md-rifatkhan/hadithbangla; its README names no translator or publisher;
  azharcse14/hadithbangla carries the same README).
- Muhiuddin Khan translation: `UNVERIFIED`.
- fawazahmed0/hadith-api: the repo's LICENSE is the Unlicense (the ledger says CC0 — correct it).
- Backfill `docs/PRODUCTIVE_MUSLIM_PROGRESS.md`: its worklog has no rows after 2026-10-26,
  while 82 non-merge commits landed 2026-10-27 → 2026-10-29 (health tracker, content
  verification, review fixes …). Summarise them from `git log --since=2026-10-27 --no-merges`
  — one row per branch/theme, not per commit.

**Done when.** New `test/docs/content_ledger_test.dart`: every file in `assets/data/` is
named in `docs/DEPENDENCIES.md`. No row is `OK` without a cited source.

### 1.3 One switch to ship without Bengali full-book hadith (prepare only)

**Why.** If permission for the hadithbangla text can't be cleared before release, the
owner must be able to ship without it. Hiding the UI isn't enough: the text would still be
inside the APK and fetched at runtime.

**Do.** Don't change what ships by default.
- `tool/hadith_db_build.dart`: a `--no-bengali` flag omits `hadith_bn_section`. Document
  that such a build must bump `HadithDatabase.bundledVersion` and `PRAGMA user_version`
  together, so installed copies get replaced.
- App: when the DB has no `hadith_bn_section`, or `--dart-define=BENGALI_HADITH=false`
  (read in `lib/config/`), no code path reads Bengali sections or requests the
  hadithbangla URL; the Bengali UI shows Arabic + English with a localized note.

**Done when.** Tests: with a DB lacking `hadith_bn_section`, and separately with the flag
off, the repository serves Arabic/English and a fake `HttpGet` records zero hadithbangla
requests. Default build and all existing tests unchanged.

### 1.4 App-blocking removable at build time (Play fallback)

**Why.** `JamaatFocusService` (an AccessibilityService) covers other apps during a session.
Play requires an Accessibility API declaration and may reject it; DND-only jamaat focus
must stay shippable.

**Do.**
- Gradle property `focusBlocking` (default `true`), passed as
  `ORG_GRADLE_PROJECT_focusBlocking=false flutter build appbundle`. When `false`, the merged
  manifest contains no `JamaatFocusService`. Prefer the AGP Variant API transform of
  `SingleArtifact.MERGED_MANIFEST` (android/gradle-recipes has an example); avoid product
  flavors unless that's impossible — flavors change every `flutter build` / `flutter run` command.
- Native: `isBlockingAvailable` on the `com.productivemuslim.app/focus` channel — true only
  if the service component exists (`PackageManager.getServiceInfo`, catch
  `NameNotFoundException`). `JamaatFocus.blocking()` and `lockNafs()` respect it.
- Dart: when unavailable, hide "Lock the phone" (`focusBlockToggle`), the Nafs lock section
  and the accessibility disclosure. A stored `block` / `nafs = true` is treated as off,
  without rewriting the user's settings.
- README, "Android release signing" section: document the property.

**Done when.** With the property off, the merged manifest under `build/` has no
`JamaatFocusService`; with the default, nothing changes. Widget test: blocking unavailable →
those controls are hidden and DND-only focus still schedules.

---

## Phase 2 — Jamaat Focus native correctness (Android)

Files: `android/app/src/main/kotlin/com/productivemuslim/app/JamaatFocus.kt`,
`android/app/src/main/res/values*/`.

### 2.1 Back gesture on Android 13+ / 16

**Problem.** `JamaatFocusActivity.onBackPressed()` swallows Back. Apps targeting API 36 no
longer receive `onBackPressed` on Android 16, so the back gesture dismisses the cover.

**Do.** Report what `flutter.targetSdkVersion` resolves to. Keep `onBackPressed` for older
devices; on API 33+ also register an `OnBackInvokedCallback`
(`OnBackInvokedDispatcher.PRIORITY_DEFAULT`) that does nothing; unregister it in `onDestroy`.

**Done when.** Builds in CI. Manual QA (list it in the report): on an API 36 emulator, a
back gesture during a session leaves the cover up.

### 2.2 Allowlist and strings

- `JamaatFocus.allowed()`: also allow the default alarm/clock app (resolve
  `Intent(AlarmClock.ACTION_SHOW_ALARMS)` through PackageManager; cache it) — an alarm must
  never be covered.
- `contentDescription = "Phone"` → a string resource in `values/` and `values-bn/`.

### 2.3 Robust plan parsing

`windows()` calls `toLong()` and `schedule()` casts `pair[0] as Number`; corrupt prefs crash
the receiver/service. Use `toLongOrNull()` / safe casts and drop malformed entries.

### 2.4 Native unit tests (none exist today)

- `android/app/build.gradle.kts`: `testImplementation("junit:junit:4.13.2")`; tests in
  `android/app/src/test/kotlin/com/productivemuslim/app/`.
- Extract the pure decisions from `JamaatFocus` into a Context-free `object FocusPlan`:
  parse windows, pick the due window (`now`, `lastStart`, 30-min manual grace), next alarm
  time, allowlist decision. `JamaatFocus` calls it; behavior unchanged.
- `ShakeCounterTest`: 5 samples ≥ 2.7 g, ≥ 250 ms apart, within 3 s fire once; 2.69 g is
  ignored; samples < 250 ms apart count once; a 5th shake outside the 3 s window doesn't
  fire; the counter resets after firing.
- `FocusPlanTest`: due window; manual session (`end = -1`) inside/after the grace period;
  the same `lastStart` never restarts; next alarm = earliest future start or the active end;
  malformed entries skipped; allowlist cases incl. dialer, keyboard (IME) and clock.

**Done when.** `cd android && ./gradlew :app:testDebugUnitTest` passes (run
`flutter build apk --debug` once first so Gradle is configured).

---

## Phase 3 — CI builds what ships

**Problem.** `.github/workflows/ci.yml` runs gen-l10n, analyze and test only. Kotlin, Swift,
manifest merging and R8 never compile in CI.

**Do.** Add a job `android` on `ubuntu-latest`:
checkout → `actions/setup-java@v4` (temurin, 17) → `subosito/flutter-action@v2`
(3.44.0, stable, cache) → `flutter pub get` → `flutter build apk --debug` →
`flutter build apk --release` (falls back to debug signing without `key.properties` — fine
for CI, and it exercises R8) → `cd android && ./gradlew :app:testDebugUnitTest`.

If the runner runs out of memory (`android/gradle.properties` asks for `-Xmx8G`), write
`org.gradle.jvmargs=-Xmx4g` to `~/.gradle/gradle.properties` inside the job (user-home
properties override the project's).

Optional job `ios` on `macos-latest`: `flutter build ios --no-codesign --debug` — ask the
owner before adding it.

**Done when.** CI is green on the branch, and locally a deliberately broken Kotlin line
(reverted, never committed) makes `flutter build apk --debug` fail.

---

## Phase 4 — Data integrity

### 4.1 `TrackerKind`: stable persisted codes

**Problem.** `lib/features/muhasaba/data/repositories/muhasaba_repository_impl.dart` writes
`item.kind.index`, reads `TrackerKind.values[row.kind]` and compares
`== TrackerKind.yesNo.index` in SQL. Reordering the enum would silently change every stored
tracker; an unknown value throws `RangeError`.

**Do.** In `lib/features/muhasaba/domain/entities/tracker_item.dart`:

```dart
/// Persisted in the muhasaba DB — never change or reuse a code; append new kinds.
enum TrackerKind {
  yesNo(0),
  count(1),
  duration(2);

  const TrackerKind(this.code);
  final int code;

  static TrackerKind? fromCode(int code) { /* null for unknown */ }
}
```

The codes equal today's indexes, so no migration is needed. The repository uses `code` /
`fromCode`; a row with an unknown code is skipped (`debugPrint`), never deleted or rewritten.

**Done when.** Pin test: the codes are exactly `[0, 1, 2]`. Repository test: a row with kind
`99` doesn't crash and isn't returned. Existing migration tests pass. Grep `lib/` for any
other enum persisted by `.index` / `.values[` and list what you find in the report.

### 4.2 Pin remote hadith sources; bound downloads

**Problem.** The runtime fallback
(`lib/features/hadith/data/hadith_book_remote_data_source.dart`) and
`tool/hadith_db_build.dart` read mutable refs:
`cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/…` and
`raw.githubusercontent.com/azharcse14/hadithbangla/main/…`. `httpGetString`
(`lib/features/hadith/data/http_fetcher.dart`) has no size limit.

**Do.**
- Pin each source to a full commit SHA (resolve with `git ls-remote <repo-url> HEAD`; if you
  can't tell which revision built the bundled snapshot, use HEAD and say so). Keep the SHAs
  in one pure-Dart constants file (e.g. `lib/config/content_sources.dart`) used by both the
  app and the tool; if the tool can't import it, duplicate it and add a test that both match.
- `httpGetString`: add `maxBytes`. Measure the largest decompressed section in
  `assets/data/hadith.db` and set the limit to about twice that; exceeding it throws, and the
  repository maps that to a failure.

**Done when.** Tests: no source URL contains `@1` or `/main`; an oversize body yields a
failure result.

### 4.3 Home widget: 7-day schedule, honest stale state, localized native text

**Problem.**
- `lib/features/home_widget/data/prayer_widget_service.dart` and
  `lib/features/home_widget/domain/widget_payload.dart` push today + tomorrow only. After
  about 2 days without opening the app, Android falls back to `widget_prayer` and iOS to the
  last pushed snapshot → a prayer that already passed is shown as "next".
- iOS polls every 15 min (`.after(now.addingTimeInterval(900))`) although only the app can
  produce new data.
- Hardcoded English in native code: `ProductiveMuslimWidgetProvider.kt` ("Set up",
  "Open the app to set your location") and `ProductiveMuslimWidget.swift` (the same, plus
  "Next Prayer").

**Do.**
- Push `AppConfig.notificationSchedulingWindow` (7 days) of prayer starts, plus one
  five-time strip per day keyed by its day start (replacing `widget_times` /
  `widget_times_next` / `widget_day_flip`); native picks the strip whose day contains now.
  Native code must tolerate the old keys for the first launch after an upgrade.
- Past the last pushed start: show a localized "open the app" state — never stale times.
  iOS: reload policy `.never` in that state (the app already calls `reloadAllTimelines()`
  whenever it pushes).
- Strings: Dart pushes the setup/stale texts in the payload (so they follow the in-app
  language); native resources (Android `values/` + `values-bn/`, iOS String Catalog en + bn)
  cover the never-configured state before Dart has ever run. "Productive Muslim" (brand) stays.

**Done when.** `test/features/home_widget/widget_payload_test.dart` covers 7 days, a DST
change and no location. Kotlin: the next-prayer / strip / stale picker is a pure function
with unit tests (Swift mirrors it; keep that code trivial). Manual QA: device clock +3 days →
the widget shows the open-app state.

### 4.4 Small fix

`lib/features/calculators/domain/usecases/fitra_calculator.dart`: the header comment says
≈ 3.0 kg / ≈ 1.5 kg, but the values are 3.30 / 1.65 kg. Fix the comment only.

### 4.5 One end-to-end flow test (no device needed)

**Problem.** `integration_test/ui_audit_test.dart` is a manual screenshot audit
(`flutter drive`); nothing checks that the main flow works end to end.

**Do.** Read `test/widget_test.dart` and `test/core/router/app_router_test.dart` first and
extend them rather than duplicate. Using the fakes in `test/helpers/`, one test walks: fresh
install → complete onboarding with a manual city → Home shows the countdown → the fake
notification scheduler received a non-empty plan.

**Done when.** It runs under plain `flutter test` (so CI runs it) and fails if any step of
that flow breaks.

---

## Phase 5 — Architecture ratchet (run alone, after Phases 1–4 are merged)

### 5.1 Import rules in `test/core/architecture_test.dart`

Keep the existing check and add these. Composition roots (`lib/main.dart`, `lib/core/di/`,
`lib/core/router/`) are exempt. Resolve relative and `package:productive_muslim/` imports
to file paths before checking.

1. `domain/` imports no Flutter and no third-party package.
2. `data/` never imports a `presentation/` file.
3. `presentation/` never imports a `data/` file.
4. A feature imports another feature only through that feature's `domain/`.
5. `presentation/` never imports `shared_preferences`, `drift`, `sqlite3`, `geolocator`,
   `sensors_plus`, `flutter_local_notifications`, `local_auth`, `url_launcher` or `path_provider`.
6. Files under `presentation/widgets/` don't reference `GetIt` / `locator`.

Today's code breaks these (review count: 4 data→presentation, 3 presentation→data, ~40
cross-feature presentation imports, 11 presentation files importing shared_preferences, plus
widget-level GetIt lookups). Put every current offender in a `const _baseline = <String>{…}`
(`'from -> to'`) so the test passes now, and add a second test that fails when a baseline
entry is no longer a violation — the list may only shrink.

**Done when.** The test passes on current code; a new violating import fails it; fixing a
violation without deleting its baseline entry fails it.

### 5.2 First refactors (one commit each; no behavior change; shrink the baseline as you go)

- App-scoped `SettingsStore` and `setting_labels.dart` (16 and 12 importers in other
  features): move them to `lib/core/settings/`, or expose a read-only settings interface from
  `lib/features/settings/domain/`. Pick one and justify it in the report.
- onboarding: `AppLockStore` depends on domain interfaces (biometric + lock storage), not on
  `AppLockDataSource`; `local_auth_biometric.dart` stops importing presentation.
- qibla: `QiblaStore` depends on a domain sensor interface, not on `sensor_data_source.dart`.
- notifications: `notification_settings_screen.dart` reaches `JamaatFocusBridge` through a
  domain interface.
- `prayer_widget_service.dart`: stop importing presentation (`home_formatting.dart`,
  `settings_store.dart`, `setting_labels.dart`).
- `arabicBodySize()` (a global that reads `GetIt.I<QuranStore>()`): replace it with an
  injected reading-preferences value.

---

## Phase 6 — Propose first; implement only after the owner approves

Write a short design for each in the report. Don't implement until approved.

- **Export all / Import.** One versioned JSON
  (`{"format": "productive_muslim_backup", "version": 1, …}`) with: muhasaba items + entries,
  fasting log + qaza counter, tasbih, Quran bookmarks + last read, dua/hadith favorites,
  mosque profiles, health weights, expenses + budgets, settings. Never the app-lock record.
  Transport: expenses use the clipboard today (see the comment near the top of
  `lib/features/expenses/presentation/screens/expense_screen.dart`); a file or share sheet
  needs a new package → guide §3 check + owner approval. Import: validate, show counts,
  merge (skip duplicates) by default.
- **Expenses and fasting → drift.** `docs/DEPENDENCIES.md` decided that entries live in
  drift, but expenses rewrite one growing JSON blob in SharedPreferences on every change.
  Plan: domain/data layers, drift tables, a one-time import from the old prefs keys (keep the
  keys for one release), migration tests.
- **Android lock record in Android Keystore**, mirroring iOS `LockKeychain` (a
  non-exportable AES-GCM key). Don't use androidx.security-crypto (deprecated).

---

## Owner decisions — ask, don't decide

1. Expenses: keep whole taka, or store minor units for global currencies (cents; KWD has
   3 decimals)?
2. `web/`, `linux/`, `windows/` (and `macos/`): delete or support? There is no `kIsWeb`
   handling, 5 files in `lib/` import `dart:io`, and CI builds none of them.
3. Nafs lock: add a short "locking in 5 s — Cancel" step before a strict session starts
   (protection against accidental shakes)?
4. Bengali full-book hadith: ship / ship after permission / ship without it (1.3).
5. Play builds: `focusBlocking` on or off by default (1.4)?

## Owner tasks — not for Claude Code

- Play Console: Accessibility API declaration for Jamaat Focus / Nafs lock (demo video if
  requested).
- Identify the translator/publisher behind the hadithbangla Bengali text; get written
  permission or replace the source.
- Confirm Tanzil's current terms of use and the credits wording.
- Real devices (Samsung, Xiaomi, Realme, Vivo/Oppo): during a strict session the user can
  still reach Settings → Accessibility and turn the service off, and an alarm stays visible.

---

## Report at the end of each phase

- Branch and commits
- Files changed, and what was deliberately left alone
- Tests added; `flutter test` count before → after; `flutter analyze` result
- Manual QA still needed
- Open questions, and anything in this plan that turned out to be wrong
