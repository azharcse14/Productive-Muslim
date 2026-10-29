# Productive Muslim

**Productive Muslim** is an **offline-first, backend-less** Islamic lifestyle app built with Flutter for a global Muslim audience. Every core feature works with zero network — there is no server, no API of our own, no analytics SDK, and no ads.

## Feature Pillars

1. **Prayer times** — computed locally from coordinates for any city worldwide; sahri/iftar, jamaat times, and a smart contextual countdown
2. **Qibla compass** — live sensor-based compass with aligned-state feedback
3. **Quran** — offline Arabic (Uthmani) + translation reader with bookmarks
4. **Dua & Tasbih** — dua collections, digital tasbih counter, Asmaul Husna
5. **Muhasaba** — daily self-accountability tracker with custom fields and a progress dashboard (the app's differentiator)
6. **Ramadan** — roza counter, sahri/iftar countdowns, monthly calendar, zakat calculator
7. **Utilities** — combined Gregorian/Hijri/Bengali calendar, "My Mosque" jamaat configuration, rich settings

## Toolchain

- **Flutter:** 3.44.0 (stable) — pinned; run `flutter --version` to verify before working
- **Dart SDK:** `^3.10.1` (bundled with the pinned Flutter)

## Getting Started

```sh
flutter config --enable-swift-package-manager   # one-time, per machine
flutter pub get
flutter run            # any connected device/simulator
flutter analyze        # must report zero issues
flutter test           # must pass
```

## Platform Toolchain

- **iOS/macOS:** Swift Package Manager **only** — no CocoaPods, no Podfile. Plugins must support SPM.
- **Android:** latest Flutter-template toolchain — Gradle 9.1.0, AGP 9.0.1, Kotlin 2.3.20, Java 17. Re-sync with the Flutter template on every Flutter upgrade.

## Android release signing

Release builds are signed from `android/key.properties`. It and the keystore
are gitignored (`key.properties`, `*.jks`, `*.keystore`) — never commit them;
back the keystore up somewhere safe, losing it means you can't update the app.

```sh
keytool -genkey -v -keystore ~/productive-muslim-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`android/key.properties`:

```properties
storePassword=<store password>
keyPassword=<key password>
keyAlias=upload
storeFile=/Users/<you>/productive-muslim-upload.jks
```

Without that file a release build falls back to the debug key (with a Gradle
warning) — fine for `flutter run --release`, never for the Play Store.
Release builds run R8 (minify + shrinkResources); keep rules live in
`android/app/proguard-rules.pro` and `android/app/src/main/res/raw/keep.xml`.

**Play fallback — build without app blocking.** Jamaat focus's "Lock the phone"
and nafs lock run on an AccessibilityService (`JamaatFocusService`), which needs
a Play Accessibility API declaration. To ship DND-only jamaat focus instead,
set the Gradle property `focusBlocking` to `false` (default `true`):

```sh
ORG_GRADLE_PROJECT_focusBlocking=false flutter build appbundle
```

The merged manifest then has no `JamaatFocusService` (an AGP Variant API
transform in `android/app/build.gradle.kts`; the build fails if the service
can't be found, so a rename can't ship it by accident). The app detects this
at runtime and hides "Lock the phone", nafs lock and the accessibility
disclosure; stored settings are kept and treated as off.

**Ship without Bengali full-book hadith.** Rebuild the hadith DB with
`dart run tool/hadith_db_build.dart --no-bengali` (bump its `_userVersion`
and `HadithDatabase.bundledVersion` together) and build the app with
`--dart-define=BENGALI_HADITH=false`. Bengali readers then get Arabic +
English, and the hadithbangla source is never read or requested.

## Architecture

Clean Architecture, feature-first. Top-level layout under `lib/`:

```
config/      app-level constants, typed asset paths, flavor switches
core/        DI (get_it), routing (go_router), theme, l10n, pure utils
shared/      reusable dumb widgets, CustomPainters, extensions
features/    one folder per feature, each with domain / data / presentation
```

- **domain** is pure Dart (no Flutter imports); **data** is the only layer touching plugins/DB; **presentation** depends on domain only.
- State management is **signals** (`signals_flutter`), DI is **get_it** (single composition root), routing is **go_router** (single route table). Nothing parallel to these is permitted.

Full details: [`docs/PRODUCTIVE_MUSLIM_DEVELOPMENT_GUIDE.md`](docs/PRODUCTIVE_MUSLIM_DEVELOPMENT_GUIDE.md) (binding engineering rules), [`docs/PRODUCTIVE_MUSLIM_IMPLEMENTATION_PLAN.md`](docs/PRODUCTIVE_MUSLIM_IMPLEMENTATION_PLAN.md) (phased plan), [`docs/PRODUCTIVE_MUSLIM_PROGRESS.md`](docs/PRODUCTIVE_MUSLIM_PROGRESS.md) (live progress).

## Design

The complete high-fidelity design (tokens, components, ~90 artboards, light + dark + RTL) lives in [`docs/design_handoff_productive_muslim/`](docs/design_handoff_productive_muslim/) — open `Productive Muslim Design.html` in a browser. `productive_muslim/tokens.css` is the canonical token source and maps 1:1 to `lib/core/theme/` (`ProductiveMuslimColors` ThemeExtension + QSpace/QRadius/QMotion + QType scale).

- **Fonts (bundled):** Schibsted Grotesk (UI), Noto Sans Bengali, IBM Plex Sans Arabic, KFGQPC Uthmanic HAFS (Quran only). Licenses in `docs/DEPENDENCIES.md`.
- **L10n:** ARB files in `lib/core/l10n/arb` (en template + bn); run `flutter gen-l10n` after editing.
- **Widget gallery:** in debug builds, More tab → Widget Gallery (`/dev/gallery`) shows the component library in the current theme.

## Dependency Policy (strict)

- Prefer Dart/Flutter built-ins over packages; write small things in-house (countdowns, Hijri math, charts, JSON mapping, `Result<T>`).
- Before adding **any** package, verify on pub.dev: updated ≤12 months, supports current stable, null-safe, healthy maintenance. Log every approved package with date + justification in `docs/DEPENDENCIES.md` (created in Phase 1).
- Zero deprecated APIs, zero analyzer warnings — enforced via `analysis_options.yaml` (strict-casts / strict-inference / strict-raw-types; deprecations and unawaited futures are errors).

## Hard Product Rules

- **Offline is the normal state** — never an error for core features
- **No guilt framing** — missed deeds are neutral, progress copy is encouraging
- Every permission denial has a designed fallback (location → manual city; notifications → app stays fully useful)
- All user-facing strings via ARB (`en` template + `bn`); layouts direction-aware (RTL-ready)
