# Dependency Ledger

Every package must pass the guide §3 check before entering `pubspec.yaml`:
updated ≤12 months · supports current stable Flutter/Dart · null-safe ·
healthy maintenance. Log the check date and a one-line justification here.

## Packages

| Package | Version | Checked | Last publish | Justification |
|---|---|---|---|---|
| `go_router` | ^17.3.0 | 2026-06-12 | 2026-06-02 | Mandated router (guide §2); flutter.dev maintained |
| `get_it` | ^9.2.1 | 2026-06-12 | 2026-02-20 | Mandated service locator (guide §2) |
| `signals` | ^7.1.0 | 2026-06-12 | 2026-05-29 | Mandated state management (guide §2) |
| `signals_flutter` | ^7.1.0 | 2026-06-12 | 2026-05-29 | Widget bindings for signals (guide §2) |
| `intl` | ^0.20.2 | 2026-06-12 | 2025-01-24 | Mandated l10n/formatting (guide §3.4). **Exception note:** last publish >12 months, but it is the Dart-team package version-pinned by `flutter_localizations` (SDK) — effectively part of the SDK release train |
| `flutter_localizations` | SDK | 2026-06-12 | — | Flutter SDK l10n delegates |
| `flutter_lints` | ^6.0.0 | 2026-06-12 | — | Official lint set (guide §6); dev-only |
| `shared_preferences` | ^2.5.5 | 2026-06-12 | 2026-03-25 | App settings KV (guide §3.1 decision below); flutter.dev; SPM-ready |
| `geolocator` | ^14.0.2 | 2026-06-12 | 2025-07-02 | GPS coordinates (guide §3.4); Baseflow, actively maintained; geolocator_apple ships Package.swift (SPM-only iOS policy holds) |
| `timezone` | ^0.11.0 | 2026-06-12 | 2026-01-07 | IANA wall-clock conversion for manually selected cities (guide §5) |
| `shared_preferences_platform_interface` | ^2.4.2 | 2026-06-12 | — | dev-only: in-memory prefs for tests |
| `adhan_dart` | ^2.0.1 | 2026-06-12 | 2026-05-11 | Prayer time + qibla calculation, pure Dart, offline (guide §3.4); wrapped behind PrayerDayRepository |
| `flutter_local_notifications` | ^22.0.0 | 2026-06-12 | 2026-06-07 | Azan/jamaat/sahri/iftar/muhasaba local notifications (guide §3.4); ships Package.swift (SPM-only iOS holds); requires Android core-library desugaring (desugar_jdk_libs 2.1.5) |
| `sensors_plus` | ^7.0.0 | 2026-06-12 | 2025-09-11 | Magnetometer + accelerometer for the qibla compass (guide §3.4 — no maintained compass package passed review, so tilt compensation is in-house in CompassMath); flutter community plus; ships Package.swift |
| `drift` | ^2.34.0 | 2026-06-12 | 2026-06-10 | Typed SQLite for Muhasaba (guide §3.4); SQL-side aggregations |
| `drift_flutter` | ^0.3.0 | 2026-06-12 | — | Official drift platform setup (replaces manual sqlite3_flutter_libs wiring) |
| `sqlite3` | ^3.3.2 | 2026-06-12 | 2026-05-26 | Native sqlite bindings; `sqlite3_flutter_libs` is EOL — 3.x bundles natively |
| `drift_dev` + `build_runner` | ^2.34.0 / ^2.15.0 | 2026-06-12 | 2026-06-10 / 2026-04-30 | dev-only codegen for drift tables |
| `path_provider` + `path` | ^2.1.5 / ^1.9.x | 2026-06-12 | — | App-dir path for the copied Quran DB (flutter.dev) |
| `local_auth` | ^3.0.1 | 2026-06-12 | 2026-02-25 | Biometric app lock (flutter.dev); local_auth_darwin ships Package.swift |
| `crypto` | ^3.x | 2026-06-12 | — | SHA-256 PIN hashing (dart.dev) — raw PIN never stored |

## Decisions

- **Settings storage:** app settings will live in `shared_preferences`
  (added in Phase 2); structured content/entries live in `drift` (Phase 7+).
  Decided once per guide §3.1.
- **No packages for:** countdown timers, Hijri math, charts/heatmap,
  JSON mapping, `Result<T>`, PIN lock — implemented in-house per guide §3.1.

## Fonts & Data Licenses

| Asset | Source | License | Checked |
|---|---|---|---|
| World city DB (assets/data/cities.json, 33,824 cities) | GeoNames cities15000 via `tool/city_db_build.dart` | CC BY 4.0 — attribution in Settings → Credits | 2026-06-12 |
| Quran DB (assets/data/quran.db, 4.9 MB, 114/6236) | Tanzil Quran Text (Simple) via fawazahmed0/quran-api (Unlicense), built by `tool/quran_db_build.dart` | Quran text: Tanzil.net terms (redistribution w/ attribution). EN: Pickthall (public domain). BN: Muhiuddin Khan. **TODO Phase 11 polish:** switch to full Uthmani-script edition (U+06E1 small-sukun aware) for mushaf fidelity | 2026-06-12 |
| Hadith DB (assets/data/hadith.db, 24 MB, full text 9 books — 72,784 ara/eng + 34,312 bn hadith, gzip-blob per section) | fawazahmed0/hadith-api (CC0, ara/eng) + azharcse14/hadithbangla (bn) — **snapshotted once** by `tool/hadith_db_build.dart`; runtime no longer depends on either source (network is only a fallback for gaps); both pinned to commit SHAs in `lib/config/content_sources.dart` (hadith-api `df57907`, hadithbangla `3de802c`, resolved 2026-10-29), online fallback capped at 4 MiB per section | Hadith text CC0 (fawazahmed0); Bengali translation via hadithbangla — attribution in Settings → Credits | 2026-06-15 |
| Dua collection (assets/data/duas.json, 43 duas / 8 categories) | Hisnul-Muslim-style compilation (Quran/Sunnah texts, not copyrightable); refs cited per dua | attributions in-app via reference field | 2026-06-12 |
| Asmaul Husna (assets/data/asmaul_husna.json) | Public religious data, curated in-repo | — | 2026-06-12 |
| Schibsted Grotesk (variable) | google/fonts (ofl/schibstedgrotesk) | OFL 1.1 | 2026-06-12 |
| Noto Sans Bengali (variable) | google/fonts (ofl/notosansbengali) | OFL 1.1 | 2026-06-12 |
| IBM Plex Sans Arabic (400/500/600/700) | google/fonts (ofl/ibmplexsansarabic) | OFL 1.1 | 2026-06-12 |
| KFGQPC Uthmanic Script HAFS v22 | KFGQPC via mustafa0x/qpc-fonts mirror | KFGQPC font license — embedding permitted; attribution required in About (Phase 8 verifies wording) | 2026-06-12 |
