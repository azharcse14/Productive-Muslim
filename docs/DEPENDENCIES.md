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

## Decisions

- **Settings storage:** app settings will live in `shared_preferences`
  (added in Phase 2); structured content/entries live in `drift` (Phase 7+).
  Decided once per guide §3.1.
- **No packages for:** countdown timers, Hijri math, charts/heatmap,
  JSON mapping, `Result<T>`, PIN lock — implemented in-house per guide §3.1.

## Fonts & Data Licenses

| Asset | Source | License | Checked |
|---|---|---|---|
| Schibsted Grotesk (variable) | google/fonts (ofl/schibstedgrotesk) | OFL 1.1 | 2026-06-12 |
| Noto Sans Bengali (variable) | google/fonts (ofl/notosansbengali) | OFL 1.1 | 2026-06-12 |
| IBM Plex Sans Arabic (400/500/600/700) | google/fonts (ofl/ibmplexsansarabic) | OFL 1.1 | 2026-06-12 |
| KFGQPC Uthmanic Script HAFS v22 | KFGQPC via mustafa0x/qpc-fonts mirror | KFGQPC font license — embedding permitted; attribution required in About (Phase 8 verifies wording) | 2026-06-12 |
