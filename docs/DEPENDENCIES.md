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
| `assets/data/quran.db` — Arabic text (114 surahs / 6,236 ayahs) | Tanzil Quran Text (Simple), https://tanzil.net, via https://github.com/fawazahmed0/quran-api edition `ara-quransimple` (jsDelivr `@1`), built by `tool/quran_db_build.dart` | Tanzil: CC BY 3.0; verbatim copies only, name the Tanzil Project and link to tanzil.net, keep the copyright notice "in all files derived from" the text (https://tanzil.net/docs/text_license). quran-api repo: Unlicense | UNVERIFIED — owner to confirm (name + link are in Settings → Credits; quran.db carries no Tanzil notice, and the fawazahmed0 copy has not been compared with Tanzil's) | 2026-10-29 |
| `assets/data/quran.db` — English translation | Mohammed Marmaduke William Pickthall, "The Meaning of the Glorious Koran" (1930), via fawazahmed0/quran-api `eng-mohammedmarmadu` (from Tanzil) | None stated. Tanzil's translations page: "for non-commercial purposes only", otherwise permission from the translator or publisher (https://tanzil.net/trans/). Translator died 1936 | UNVERIFIED — owner to confirm (likely public domain by age) | 2026-10-29 |
| `assets/data/quran.db` — Bengali translation | Muhiuddin Khan, via fawazahmed0/quran-api `ben-muhiuddinkhan` (from Tanzil) | None stated. Tanzil's translations page: non-commercial only, otherwise permission from the translator or publisher (https://tanzil.net/trans/) | UNVERIFIED — owner to confirm | 2026-10-29 |
| `assets/data/hadith.db` — Arabic + English (9 books, 35,717 hadith each) and Bengali for 40 Hadith Nawawi + Muwatta Malik (1,882 hadith) | https://github.com/fawazahmed0/hadith-api editions `ara-*`, `eng-*`, `ben-nawawi`, `ben-malik` (jsDelivr, pinned to commit `df57907` in `lib/config/content_sources.dart`, resolved 2026-10-29), table `hadith_section`, built by `tool/hadith_db_build.dart`; online fallback capped at 4 MiB per section | Unlicense (https://github.com/fawazahmed0/hadith-api/blob/1/LICENSE) — the old ledger said CC0, which was wrong | OK | 2026-10-29 |
| `assets/data/hadith.db` — Bengali, 6 books (Bukhari, Muslim, Abu Dawud, Tirmidhi, Nasai, Ibn Majah; 330 chapters, 34,312 hadith) | hadithbangla: snapshot of `azharcse14/hadithbangla`, pinned to commit `3de802c` in `lib/config/content_sources.dart` (`{folder}/Chapter/{n}.json`), a fork of `mohacelhosen/hadithbangla`; the README credits `md-rifatkhan/hadithbangla` (that repo now returns 404). Table `hadith_bn_section` | None. No LICENSE file in azharcse14 or mohacelhosen (GitHub API: no license); the README names no translator or publisher | NO LICENSE — permission needed | 2026-10-29 |
| `assets/data/hadith_books.json` — catalog: 9 books, 397 sections + 330 Bengali chapter titles | Book/section metadata from fawazahmed0/hadith-api (`info.json`); `sections_bn` titles from hadithbangla (as above) | fawazahmed0: Unlicense. hadithbangla: none | NO LICENSE — permission needed (the Bengali chapter titles; the rest is OK) | 2026-10-29 |
| `assets/data/hadith.json` — 40 hadith of the day (9 topics) | Curated in-repo (2026-06-13/14); each entry cites its collection + number (e.g. Sahih Bukhari 1). Source of the English/Bengali wording not recorded | Not recorded | UNVERIFIED — owner to confirm | 2026-10-29 |
| `assets/data/duas.json` — 156 duas / 20 categories | 90 (`hm_*` ids) imported from Hisnul Muslim `dua_main.sqlite` in https://github.com/aminurdev/dua-ruqya-server (2026-06-15); the other 66 curated in-repo with per-dua references | aminurdev/dua-ruqya-server: none (no LICENSE file; GitHub API: no license). Arabic is Qur'an/Sunnah text; the translations and transliterations are someone's work | NO LICENSE — permission needed (the 90 imported duas) | 2026-10-29 |
| `assets/data/ruqyah.json` — 11 categories / 37 passages | Curated in-repo (2026-06-14) from the Qur'an and sahih hadith, reference per passage. Source of the English/Bengali wording not recorded | Not recorded | UNVERIFIED — owner to confirm | 2026-10-29 |
| `assets/data/tibb_nabawi.json` — 1 category / 27 narrations | Curated in-repo (2026-10-29) from Bukhari, Muslim, the Sunan and Qur'an 16:69; reference + grading per item. Arabic checked against the fawazahmed0/hadith-api text; English/Bengali translation and notes written in-repo | Hadith text public domain; wording in-repo | UNVERIFIED — owner to confirm | 2026-10-29 |
| `assets/data/asmaul_husna.json` — 99 names | Curated in-repo (2026-06-12); source of the meanings not recorded | Not recorded | UNVERIFIED — owner to confirm | 2026-10-29 |
| Schibsted Grotesk (variable) | https://github.com/google/fonts `ofl/schibstedgrotesk` | OFL 1.1 (`OFL.txt` in that folder) | OK | 2026-10-29 |
| Noto Sans Bengali (variable) | https://github.com/google/fonts `ofl/notosansbengali` | OFL 1.1 (`OFL.txt` in that folder) | OK | 2026-10-29 |
| IBM Plex Sans Arabic (400/500/600/700) | https://github.com/google/fonts `ofl/ibmplexsansarabic` | OFL 1.1 (`OFL.txt` in that folder) | OK | 2026-10-29 |
| KFGQPC Uthmanic Script HAFS v22 | KFGQPC via `mustafa0x/qpc-fonts` mirror | KFGQPC font license — embedding permitted, attribution required (credited in Settings → Credits); wording not re-checked | UNVERIFIED — owner to confirm | 2026-06-12 |

Quran DB TODO (unchanged): switch to the full Uthmani-script edition (U+06E1 small-sukun
aware) for mushaf fidelity.
