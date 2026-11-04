# Review Fix Plan — 2026-10-29

> **For Claude Code.** Built from a two-part external review of this repo (2026-10-29).
> Do **only the phase you were asked to do**, then stop and report (format at the end).
> If the code doesn't match what this plan describes (file moved, already fixed,
> different behavior), stop and say so — don't force the change.

The binding rules in `docs/PRODUCTIVE_MUSLIM_DEVELOPMENT_GUIDE.md` still apply. Where this
plan is more specific, this plan wins.

## Status — updated 2026-11-04 (all done items merged into `master`)

| Item | Status |
|---|---|
| 1.1 credits, 1.2 ledger, 1.3 `--no-bengali` switch, 1.4 `focusBlocking` | ✅ done |
| 1.2 worklog backfill (2026-10-27 → 29, added in this plan revision) | ✅ done 2026-11-04 (10-29 already had rows) |
| 2.1–2.4 Jamaat Focus native | ✅ done |
| 3 CI android job | ✅ done — never run on GitHub yet (branch not pushed) |
| 4.1–4.4 | ✅ done |
| 4.5 end-to-end flow test (added in this plan revision) | ✅ done 2026-11-04 (`test/widget_test.dart`) |
| 5.1 architecture ratchet (baseline 96 → 92) | ✅ done |
| 5.2 onboarding `AppLockStore`, qibla `QiblaStore`, notifications → `JamaatFocusControl` | ✅ done |
| 5.2 `SettingsStore` + `setting_labels.dart` (pick an option, justify) | ✅ done 2026-11-04 — moved to `lib/core/settings/` (app-scoped like theme/router; an interface would have one implementation) |
| 5.2 `prayer_widget_service.dart` off presentation (do together with the item above) | ✅ done 2026-11-04 |
| 5.2 `arabicBodySize()` → injected reading preferences | ✅ already done — reads `ReaderTextSizeScope` (InheritedWidget), no `GetIt` |
| 6 proposals (export/import, expenses+fasting → drift, Android Keystore lock) | ✅ decided 2026-11-04 — Keystore and export/import dropped; expenses → drift done (see Owner decisions) |
| Owner decisions 1–5 | ✅ all decided (1 on 2026-11-03; 2–5 on 2026-11-04, see Owner decisions) |

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
- `tool/hadith_db_build.dart`: a `--no-bengali` flag omits `hadith_bn_section`. Installed
  copies get replaced because `HadithDatabase.ensureCopied` re-copies when the copy's
  `hadith_bn_section` presence differs from `BENGALI_HADITH` (no version bump needed;
  the earlier "bump `bundledVersion` + `PRAGMA user_version`" rule was never applied by
  the strip tool — fixed 2026-11-04, `fix/hadith-strip-version`).
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

### Proposals (written 2026-11-04 — awaiting owner approval)

Checked against code on 2026-11-04: expenses and fasting still persist from their
presentation stores (`ExpenseStore`, fasting store) into `SharedPreferencesAsync`; expenses
already export/import a CSV (`ExpenseStore.exportCsv` / `importCsv`, budgets excluded); the
Android lock record is plain prefs (iOS uses `LockKeychain`). Branch
`feat/expense-sadaqah-backup` (separate worktree) is also touching expense backup —
coordinate before starting the first two.

1. **Export all / Import.** A `BackupRepository` in a new `lib/features/backup/` (domain
   interface + data impl) asks each feature's domain repository for a `Map` section and
   writes `{"format": "productive_muslim_backup", "version": 1, "exportedAt": …, "sections":
   {"muhasaba": …, "fasting": …, "tasbih": …, "quran": …, "favorites": …, "mosques": …,
   "health": …, "expenses": …, "settings": …}}`. Muhasaba rows come from drift DAOs (items
   by stable id, entries by `(itemId, date)`); never the app-lock record or PIN. Transport:
   clipboard first (no package, same as expenses today); a file/share-sheet needs a package
   → guide §3 + owner OK. Import: parse → validate `format`/`version` and each section's
   shape → preview counts per section → merge, skipping duplicates by natural key (expense
   id, `(itemId, date)`, bookmark `surah:ayah`); unknown sections ignored, a newer
   `version` refused. Tests: round-trip per section, duplicate import is a no-op, corrupt
   input changes nothing.
2. **Expenses and fasting → drift.** Add `expenses`, `budgets` and `fast_days` tables to the
   muhasaba drift DB (one user DB): bump `schemaVersion`, migration step, export the schema
   to `drift_schemas/`, regenerate the test schemas, extend `muhasaba_migration_test.dart`
   (CLAUDE.md rule). Domain entities + repository interfaces; data impl with DAOs; stores
   switch to the repositories. On first launch after upgrade a one-time importer copies the
   old prefs keys into the tables inside one transaction and sets a `migrated` flag; the old
   keys stay one release, then are removed. Amounts stay minor units. Tests: importer
   (empty, normal, corrupt prefs), DAO aggregations (month totals, category filter),
   migration test.
3. **Android lock record in Android Keystore.** Kotlin `LockKeystore` mirroring iOS
   `LockKeychain`: a non-exportable AES-256-GCM key (`KeyGenParameterSpec`, alias
   `pm_lock`, no user-auth requirement so the lock screen can read it), ciphertext + IV in a
   private `SharedPreferences` file excluded from backup. Same three string calls over the
   existing method channel as iOS, so `KeychainPrefs` on the Dart side just stops being
   iOS-only. Migration: on first read, move the plain prefs record into the Keystore store
   and delete the plain copy. Key loss (restore to a new device, Keystore reset) reads as
   "no lock" plus the existing PIN-reset path — never a crash. No androidx.security-crypto.
   Tests: Robolectric/JVM unit test for encrypt/decrypt + migration, Dart test for the
   channel fallback; `flutter build apk --debug`.

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

### Decided 2026-11-04 (owner delegated: "sob tumi decision niye kore felo")

Decided by Claude, each checked by a second, independent agent against the code.
1. **Minor units** — already done (owner-approved wave 1, 2026-11-03).
2. **Android + iOS only** — `web/`, `linux/`, `windows/`, `macos/` deleted
   (`chore/drop-desktop-web`).
3. **Nafs lock 5 s cancel — yes**, native (the shake is caught by the
   AccessibilityService in the background): `feat/nafs-lock-countdown`.
4. **Bengali full-book hadith — ship only after written permission.** Release
   builds strip it (`tool/strip_bengali_hadith.dart` + `BENGALI_HADITH=false`,
   `docs/RELEASE_CHECKLIST.md`); dev builds keep it.
5. **`focusBlocking` stays on for Play** — Play allows non-tool accessibility use
   for focus blockers with a declaration + disclosure; Settings, the installer
   and Play stay reachable during a session. Rejection → rebuild with
   `focusBlocking=false`.

Phase 6: **Android Keystore lock — dropped** (`app_lock.xml` is already excluded
from cloud backup and device transfer and holds only a salted hash; the data it
guards sits unencrypted in the same sandbox, so encryption would only slow a
root-level attacker). **Expenses + budgets → drift — done** (fasting stays in
prefs: a small bounded list). **Export all / Import — dropped for now**: Android
Auto Backup + device transfer already carry every user file and preference
(only `bundled/` and `app_lock.xml` are excluded) and iOS device backups carry
the app's data, so a same-platform phone change keeps everything; expenses also
export/import CSV. What's left is Android ↔ iOS moves — not worth ~9
serializers, a native document picker and merge logic before 1.0. Revisit if
users ask (design above; transport would be a file via the share channel, as
the clipboard breaks past Android's ~1 MB Binder limit).

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

---

## UI review follow-ups — 2026-11-02

The full UI review was fixed on `fix/ui-design-system`, `fix/ui-features-a` and `fix/ui-features-b`, all merged into `master`. What is still open:

- [x] **Full `flutter test` on merged master.** Each feature branch passed the full suite, but nobody has run it on the merge result. The merge was urgent, so only `flutter analyze` and the l10n diff were checked.
- [x] **Home dua-of-the-day transliteration.** In `prayer_times/presentation/screens/home_screen.dart`, pass `transliteration: dua.transliterationFor(code)` to `DuaOfDayCard` so the screen reader gets a `semanticsLabel`.
- [x] **Ruqyah categories still use `MaterialPageRoute`.** Done for ruqyah, dua and hadith on `feat/routes-shell-lock` (2026-11-03, `integrate/followups-2`). Add a named route in `app_router.dart` and use `context.pushNamed`. (2026-11-03: left as is — dua and hadith sub-screens use the same `MaterialPageRoute` push; do all of them together or drop the item.)
- [x] **Remove dead ARB keys.** `muhasabaIconOption` and `muhasabaColorOption` are no longer used; delete them from en and bn.
- [x] **Owner to confirm these behaviour changes:** — accepted 2026-11-04 (all four are accessibility/layout fixes), except the biometric message, which was a bug: a cancel no longer says "unavailable" (`fix/lock-biometric-cancel`).
  - The calendar screen's side padding went from 20dp to 12dp, to get 48dp day cells.
  - `QCard`'s default padding went from 18 to 20.
  - The lock screen now shows "Biometric unavailable" even when the user cancels the biometric prompt.
  - The prayer table puts the time range on a second line when text is scaled above 1.3x.
- [ ] **Manual QA.** No device run has been done yet. Check on a 360dp screen at 1.0x, 1.5x and 2.0x text, in light and dark mode, in Bangla and English, and with TalkBack/VoiceOver on.
- [x] **Countdown card test.** Add a widget test for the new eyebrow/corner row.
- [x] **Muhasaba Today swipe.** — kept as is (decided 2026-11-04): the chevrons cover it. The day-swipe `GestureDetector` was left unchanged because the chevrons already do the same job. Review it if it still matters.

---

## UX review follow-ups — 2026-11-02 (second pass)

A second, end-user UX review ran across all features. Three fix branches were merged into
`master` via `integrate/ux-review`: `fix/ux-shell-notif-settings`, `fix/ux-prayer-mosque-qibla`
and `fix/ux-ramadan-calendar-calc`. Where they overlapped with the earlier `fix/ui-features-*`
merge, the version already on master was kept (QBanner `onTap`, prayer-table `_nameAndTime`,
`rescheduleFailed`, `l10n.retry`, `QListRow` switch rows, `context.clockTime`). Still open:

### 5 failing tests on master after this merge — fixed 2026-11-03 (`fix/review-followups`)

All come from the overlap with `fix/ui-features-*`: our tests expect the dropped variant.
- [x] `home_screen_test.dart`: "exact-alarm banner has a visible button and a dismiss" (× dropped; delete or rewrite for `onTap`).
- [x] `home_screen_test.dart`: "nearby mosques action says it opens Maps".
- [x] `age_screen_test.dart`: "an as-of date before the birth date blocks Calculate" (rewritten in the merge; picker flow needs checking).
- [x] `my_mosque_screen_test.dart`: "mode segments and the minute value name their prayer" (minute-value `Semantics` dropped in favour of master's `ConstrainedBox`).
- [x] `notification_settings_screen_test.dart`: "a failed reschedule shows a banner and retry clears it" (two versions of the same test merged).

### Unmerged WIP branches (stopped mid-gate, never gated)

Both branches start from `feb94c9`, so they predate `fix/ui-features-b`, which already fixed
many of the same findings. Don't merge them as they are. Take only what's still missing, on a
fresh branch from `master`.

- [x] **`fix/ux-quran-hadith-dua`** (`b900a57`). Ported 2026-11-03 (see PROGRESS). Still missing on master:
  - Bangla surah-search hint: name in English/Arabic, or a number.
  - `2:255` jump from the surah search.
  - Bookmarks sheet: build rows with `ListView.builder`, and undo for more than the last removal.
  - Tasbih:
    - "Today" count includes the round in progress.
    - Optional auto-start of the next round at the target.
    - Asks to save or reset when the phrase is changed mid-round.
  - Hadith: search relabelled "Search topics", and a favourite toggle.
  - Duas: favourites shown above the category grid, with undo when one is removed.
  - Quran screen: an "unavailable" state when `quran.db` fails (see the `ponytail:` note in `locator.dart`).
  - Reader:
    - The font slider's semantics formatter.
    - "Go to ayah" updates "Continue reading".
    - "Ayah {n}" on the resume card.
    - The medallion text uses `FittedBox`.
  - Other screens:
    - Tibb Nabawi list built with `ListView.builder`.
    - The Asma sheet scrolls.
    - The Asma quiz confirms before back.
  - Keep the screen on in Tasbih and the Quran reader (native flag, no package).
- [x] **`fix/ux-muhasaba-trackers`** (`eb9eee3`). Ported 2026-11-03 (see PROGRESS). Still missing on master:
  - Fasting: prev/next month so past months' fasts can be logged; a snackbar when a future or Eid day is tapped.
  - Muhasaba:
    - Tapping a yes/no row toggles it.
    - The archive explanation text is corrected.
    - The duration dialog shows its unit, and durations display as "8 h" / "1 h 30 min".
  - Health: add or edit weight for past days.
  - Editor sheets (tracker, expense): a close/Cancel button.
  - Expense category rows: button semantics.
  - Achievement card semantics.
  - Achievements screen guard when `QuranStore` is unregistered.
  - Expense: a clearer message for amounts that must be whole numbers.

### Owner-approved features (not started)

- [x] **Muhasaba dashboard custom date range** (design brief §4.7, `showDateRangePicker`).
- [x] **Quran juz tab + per-ayah share** (design brief §4.5).
- [x] **Expense decimal amounts + currency.** Amounts move to minor units; needs a storage
  migration (follow the schema-change rules in CLAUDE.md if the expense table is in the muhasaba DB).
- [x] **Full hadith DB search** across all bundled collections, not only curated topics.

### Smaller open items from the merged branches

- [x] **Home exact-alarm banner.** (dismissible, persisted) It can't be dismissed. The second pass's × was dropped in
  favour of master's tappable banner. Add a persisted "don't remind" setting if users ask for it.
- [x] **Battery optimisation.** (direct list via a platform channel) The button opens app info; the direct
  `ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS` list needs a new platform channel.
- [x] **Persistent badge-unlock toast.** (now in the app shell) It only fires while Muhasaba is open; it belongs in the app shell.
- [ ] **Owner decisions:**
  - ~~Bengali date in calendar cells (design handoff §13).~~ Done `b5dbe37`.
  - Bengali surah names, which need a licensed source. — deferred 2026-11-04 until a licensed source exists (religious text, owner sign-off).
  - ~~Settings lives under the More branch while Qibla/Calendar are root routes (bottom bar
    shows on one, not the other).~~ Done: bottom bar only on the five tab roots; every secondary page full-screen (design shows the bar on Settings/Calendar/Ramadan — owner may want those three in the More branch).
- [x] **Full `flutter test` passes on a quiet machine.** 1560 green on `integrate/followups-2` with `-j 2`. During the parallel runs some tap tests
  failed under load and passed when rerun alone.
