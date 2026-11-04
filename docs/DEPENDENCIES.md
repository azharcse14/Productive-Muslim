# Dependency Ledger

Every package must pass the guide §3 check before entering `pubspec.yaml`:
updated ≤12 months · supports current stable Flutter/Dart · null-safe ·
healthy maintenance. Log the check date and a one-line justification here.

## Packages

| Package | Version | Checked | Last publish | Justification |
|---|---|---|---|---|
| `go_router` | ^18.1.1 (locked 18.1.1) | 2026-11-02 | 2026-10-29 (18.1.2) | Mandated router (guide §2). Re-checked on pub.dev API for ^18: publisher flutter.dev, Flutter Favorite, not discontinued; 18.1.2 requires Dart ^3.12.0 / Flutter ≥3.44.0 (project: Flutter 3.47.9 / Dart 3.13.7), Dart 3 so null-safe; source in flutter/packages. pub points not yet computed for 18.1.2 (0/0 at check time) |
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
| `url_launcher` | ^6.3.3 (locked 6.3.3) | 2026-11-02 | 2026-10-02 | Opens external links (tanzil.net credit, maps for nearby mosques) behind `ExternalLauncher`; flutter.dev, Flutter Favorite, 160/160 pub points, null-safe, SwiftPM plugin; requires Dart ^3.11.0 / Flutter ≥3.41.0 |
| `shared_preferences_android` | ^2.5.4 (locked 2.5.4) | 2026-11-02 | 2026-10-27 | Direct import only for `SharedPreferencesAsyncAndroidOptions` (app-lock store in its own file, `locator.dart`); the federated Android implementation of `shared_preferences`; flutter.dev, 140/160 pub points, null-safe; requires Dart ^3.12.0 / Flutter ≥3.44.0 |
| `flutter_launcher_icons` | ^0.14.4 (locked 0.14.4) | 2026-11-02 | 2025-06-10 | dev-only: generates the Android launcher/adaptive icons from `assets/icon/` (config in `pubspec.yaml`); never shipped. fluttercommunity.dev, 150/160 pub points, null-safe, SDK `>=3.0.0 <4.0.0`, repo not archived (last commit 2025-06-10, 148 open issues). **Fails guide §3 rule 2(a):** last publish >12 months — owner to decide: exception (dev-only tool) or drop it |
| `integration_test` + `flutter_driver` | SDK | 2026-11-02 | — | dev-only: Flutter SDK packages for `integration_test/ui_audit_test.dart` driven by `test_driver/integration_test.dart` |
| `junit:junit` (Gradle, Android) | 4.13.2 | 2026-10-29 | 2021-02-13 | Android `testImplementation` only (never shipped): JVM unit tests for native code (`WidgetScheduleTest`, `FocusPlanTest`, `ShakeCounterTest`). **Exception note:** last publish >12 months, but JUnit 4 is the runner AGP's local unit tests are built on and the Android project template's default |

## Decisions

- **Settings storage:** app settings will live in `shared_preferences`
  (added in Phase 2); structured content/entries live in `drift` (Phase 7+).
  Decided once per guide §3.1.
- **No packages for:** countdown timers, Hijri math, charts/heatmap,
  JSON mapping, `Result<T>`, PIN lock — implemented in-house per guide §3.1.

## Fonts & Data Licenses

One row per file in `assets/data/` (`test/docs/content_ledger_test.dart` keeps this
complete). Counts are read from the files. Status: `OK` (license verified at the cited
source) · `UNVERIFIED — owner to confirm` · `NO LICENSE — permission needed`. Never mark
a row `OK` without citing where the license was read.

| Asset | Source (repo + edition/path) | License as stated by the source | Status | Checked |
|---|---|---|---|---|
| `assets/data/cities.json` — 34,740 cities | GeoNames `cities15000` + `BD` dumps (https://download.geonames.org/export/dump/) via `tool/city_db_build.dart` | CC BY 4.0 (https://download.geonames.org/export/dump/readme.txt) — attribution in Settings → Credits | OK | 2026-10-29 |
| `assets/data/quran.db` — Arabic text (114 surahs / 6,236 ayahs) | Tanzil Quran Text (Simple), https://tanzil.net, via https://github.com/fawazahmed0/quran-api edition `ara-quransimple`, built by `tool/quran_db_build.dart`. The tool now reads commit `93e6f64` (`ContentSources.quranApiSha`, HEAD of branch `1`, resolved 2026-11-02); the bundled db was built earlier from the moving `@1`, but GitHub's history shows none of the files the tool reads (`ara-quransimple`, `eng-mohammedmarmadu`, `ben-muhiuddinkhan`, `info.json`) changed after 2022-10-05, so the inputs match | Tanzil: CC BY 3.0; verbatim copies only, name the Tanzil Project and link to tanzil.net, keep the copyright notice "in all files derived from" the text (https://tanzil.net/docs/text_license). quran-api repo: Unlicense | UNVERIFIED — owner to confirm (name + link are in Settings → Credits; quran.db carries no Tanzil notice, and the fawazahmed0 copy has not been compared with Tanzil's) | 2026-10-29 |
| `assets/data/quran.db` — English translation | Mohammed Marmaduke William Pickthall, "The Meaning of the Glorious Koran" (1930), via fawazahmed0/quran-api `eng-mohammedmarmadu` (from Tanzil) | None stated. Tanzil's translations page: "for non-commercial purposes only", otherwise permission from the translator or publisher (https://tanzil.net/trans/). Translator died 1936 | OK — non-commercial use per Tanzil's terms (https://tanzil.net/trans/, re-read 2026-11-04: "for non-commercial purposes only"; ≤3 translations, so no link-back required). The app is free, with no ads or purchases; any monetization needs the translator's/publisher's permission first | 2026-11-04 |
| `assets/data/quran.db` — Bengali translation | Muhiuddin Khan, via fawazahmed0/quran-api `ben-muhiuddinkhan` (from Tanzil) | None stated. Tanzil's translations page: non-commercial only, otherwise permission from the translator or publisher (https://tanzil.net/trans/) | OK — non-commercial use per Tanzil's terms (https://tanzil.net/trans/, re-read 2026-11-04: "for non-commercial purposes only"; ≤3 translations, so no link-back required). The app is free, with no ads or purchases; any monetization needs the translator's/publisher's permission first | 2026-11-04 |
| `assets/data/hadith.db` — Arabic + English (9 books, 35,717 hadith each) and Bengali for 40 Hadith Nawawi + Muwatta Malik (1,882 hadith) | https://github.com/fawazahmed0/hadith-api editions `ara-*`, `eng-*`, `ben-nawawi`, `ben-malik` (jsDelivr, pinned to commit `df57907` in `lib/config/content_sources.dart`, resolved 2026-10-29), table `hadith_section`, built by `tool/hadith_db_build.dart`; online fallback capped at 4 MiB per section | Unlicense (https://github.com/fawazahmed0/hadith-api/blob/1/LICENSE) — the old ledger said CC0, which was wrong | OK | 2026-10-29 |
| `assets/data/hadith.db` — Bengali, 6 books (Bukhari, Muslim, Abu Dawud, Tirmidhi, Nasai, Ibn Majah; 330 chapters, 34,312 hadith) | hadithbangla: snapshot of `azharcse14/hadithbangla`, pinned to commit `3de802c` in `lib/config/content_sources.dart` (`{folder}/Chapter/{n}.json`), a fork of `mohacelhosen/hadithbangla`; the README credits `md-rifatkhan/hadithbangla` (that repo now returns 404). Table `hadith_bn_section` | None. No LICENSE file in azharcse14 or mohacelhosen (GitHub API: no license); the README names no translator or publisher | NO LICENSE — permission needed | 2026-10-29 |
| `assets/data/hadith_books.json` — catalog: 9 books, 397 sections + 330 Bengali chapter titles | Book/section metadata from fawazahmed0/hadith-api (`info.json`); `sections_bn` titles from hadithbangla (as above) | fawazahmed0: Unlicense. hadithbangla: none | NO LICENSE — permission needed (the Bengali chapter titles; the rest is OK) | 2026-10-29 |
| `assets/data/hadith.json` — 40 hadith of the day (9 topics) | Curated in-repo (2026-06-13/14); each entry cites its collection + number (e.g. Sahih Bukhari 1). Source of the English/Bengali wording not recorded | Not recorded | UNVERIFIED — owner to confirm | 2026-10-29 |
| `assets/data/duas.json` — 156 duas / 20 categories | 90 (`hm_*` ids) imported from Hisnul Muslim `dua_main.sqlite` in https://github.com/aminurdev/dua-ruqya-server (2026-06-15); the other 66 curated in-repo with per-dua references | aminurdev/dua-ruqya-server: none (no LICENSE file; GitHub API: no license). Arabic is Qur'an/Sunnah text; the translations and transliterations are someone's work | NO LICENSE — permission needed (the 90 imported duas) | 2026-10-29 |
| `assets/data/ruqyah.json` — 11 categories / 37 passages | Curated in-repo (2026-06-14) from the Qur'an and sahih hadith, reference per passage. Source of the English/Bengali wording not recorded. Bengali transliteration (`trBn`, 2026-11-04): 8 copied from the matching `duas.json` entries, 29 written in-repo from the Arabic by Claude at the owner's request (house style of `duas.json`) — not scholar-reviewed | Not recorded | UNVERIFIED — owner to confirm | 2026-10-29 |
| `assets/data/tibb_nabawi.json` — 1 category / 27 narrations | Curated in-repo (2026-10-29) from Bukhari, Muslim, the Sunan and Qur'an 16:69; reference + grading per item. Arabic checked against the fawazahmed0/hadith-api text; English/Bengali translation and notes written in-repo; Bengali transliteration (`trBn`, 2026-11-04) written in-repo from the Arabic by Claude at the owner's request — not scholar-reviewed | Hadith text public domain; wording in-repo | UNVERIFIED — owner to confirm | 2026-10-29 |
| `assets/data/asmaul_husna.json` — 99 names | Curated in-repo (2026-06-12); source of the meanings not recorded | Not recorded | UNVERIFIED — owner to confirm | 2026-10-29 |
| `assets/data/rasul_names.json` — 27 names of the Prophet ﷺ | Compiled in-repo (2026-11-03) from Quran ayat, Bukhari 3532 / Muslim 2354–2355, Muslim 2276, Shama'il at-Tirmidhi, Sirah; per-name `ref` in the JSON | Quran/hadith text is public domain; EN/BN meanings written in-repo | UNVERIFIED — owner/scholar review of names, Arabic and meanings pending | 2026-11-03 |
| `assets/data/prophets.json` — 25 prophets named in the Quran (timeline-tree) | Drafted in-repo by Claude (2026-11-04) from the Quran and hadith; per-prophet refs in the JSON, checked against the bundled quran.db/hadith.db | Quran/hadith text public domain; EN/BN summaries written in-repo | UNVERIFIED — scholar review pending | 2026-11-04 |
| `assets/data/quran_stories.json` — Quran stories | Drafted in-repo by Claude (2026-11-04) from the Quran / hadith collections; per-story refs in the JSON, checked against the bundled quran.db/hadith.db | Quran/hadith text public domain; EN/BN retellings written in-repo | UNVERIFIED — scholar review pending | 2026-11-04 |
| `assets/data/hadith_stories.json` — Hadith stories | Drafted in-repo by Claude (2026-11-04) from the Quran / hadith collections; per-story refs in the JSON, checked against the bundled quran.db/hadith.db | Quran/hadith text public domain; EN/BN retellings written in-repo | UNVERIFIED — scholar review pending | 2026-11-04 |
| Schibsted Grotesk (variable) | https://github.com/google/fonts `ofl/schibstedgrotesk` | OFL 1.1 (`OFL.txt` in that folder) | OK | 2026-10-29 |
| Noto Sans Bengali (variable) | https://github.com/google/fonts `ofl/notosansbengali` | OFL 1.1 (`OFL.txt` in that folder) | OK | 2026-10-29 |
| IBM Plex Sans Arabic (400/500/600/700) | https://github.com/google/fonts `ofl/ibmplexsansarabic` | OFL 1.1 (`OFL.txt` in that folder) | OK | 2026-10-29 |
| KFGQPC Uthmanic Script HAFS v22 | KFGQPC via `mustafa0x/qpc-fonts` mirror | KFGQPC font license — embedding permitted, attribution required (credited in Settings → Credits); wording not re-checked | UNVERIFIED — owner to confirm | 2026-06-12 |

Quran DB TODO (unchanged): switch to the full Uthmani-script edition (U+06E1 small-sukun
aware) for mushaf fidelity.
