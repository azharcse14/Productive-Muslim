# Productive Muslim — Claude Code memory

Binding engineering rules (loaded every session):
@docs/PRODUCTIVE_MUSLIM_DEVELOPMENT_GUIDE.md

That guide's §7 "Build Order" is history — every phase is done. Current state and worklog:
`docs/PRODUCTIVE_MUSLIM_PROGRESS.md`. Open review work: `docs/REVIEW_FIX_PLAN.md` — read it
only when asked to work on it.

## Gates — before every commit

- `flutter gen-l10n`, then `git diff --exit-code -- lib/core/l10n/gen`
- `flutter analyze` → zero issues. Never add `// ignore:` or loosen `analysis_options.yaml`.
- `flutter test` → all green. New behavior ships with tests (unit for domain, widget for UI).
- Changed `android/`, `ios/` or a platform channel → `flutter build apk --debug`;
  Kotlin tests: `cd android && ./gradlew :app:testDebugUnitTest`.

## Rules that drifted before

- Layers: domain is pure Dart; only `data/` touches plugins, prefs, databases and platform
  channels; `presentation/` imports domain, `core/` and `shared/`. Reach another feature only
  through its `domain/`. `test/core/architecture_test.dart` enforces this (baseline from
  `docs/REVIEW_FIX_PLAN.md` Phase 5) — the baseline may only shrink.
- Persisted enums: an explicit stable code or `.name` — never `.index`.
- Strings: every user-facing string in both `app_en.arb` and `app_bn.arb` (spell নামাজ).
  Native strings too: Android `values/` + `values-bn/`, iOS String Catalog, or pushed from Dart.
- Packages: guide §3 check, a `docs/DEPENDENCIES.md` row, and the owner's OK first.
- Bundled content (`assets/data/`): source + license row in `docs/DEPENDENCIES.md` and in
  the in-app credits. Unknown license → write UNVERIFIED and ask. Never guess.
- Bundled DB change (quran.db / hadith.db): bump `bundledVersion` and `PRAGMA user_version`
  together.
- Muhasaba schema change: bump `schemaVersion`, add the migration step, export the schema to
  `drift_schemas/`, regenerate `test/features/muhasaba/data/generated/`, extend
  `muhasaba_migration_test.dart`.
- Religious text (Quran, hadith, dua, ruqyah wording and references): don't edit unless the
  task says so — flag suspected errors instead.
- Log every change set in the PROGRESS.md worklog, in the same commit.

## Working style

- One branch per change set (`fix/…`, `feat/…`), conventional commits (`fix(scope): …`).
  Don't merge into `master`; stop and report.
- Parallel agents: never two in the same feature folder, or in `lib/core/`, at once.
