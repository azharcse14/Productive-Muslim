# Handoff: Qalbee — Islamic Lifestyle App (full design system + all screens)

## Overview
Qalbee is an **offline-first Islamic lifestyle app** (Flutter, no backend) for a global Muslim audience: prayer times, qibla compass, Quran reader, dua/tasbih, Ramadan tools, and its differentiator — **Muhasaba**, a daily self-accountability tracker. This handoff contains the complete visual design: design tokens (light + dark), the core component library, and every screen/state, including RTL examples, notification artifacts, and store assets.

**Read `QALBEE_DESIGN_BRIEF.md` first** — it is the original product brief and contains hard product rules (positive framing, offline-is-normal, permission fallbacks) that are binding for implementation, not just design.

## About the Design Files
The files in this bundle are **design references created in HTML/JSX** — they show intended look, states, and behavior. They are **not production code**. The task is to **recreate these designs in Flutter** (the target per the brief) using idiomatic Flutter: `ThemeData` + `ThemeExtension` for tokens, real widgets, real localization (`intl`/ARB), real sensors. If the target environment ever changes, recreate in that stack's conventions instead.

View the designs by opening `Qalbee Design.html` in a browser (needs internet for fonts/React CDN). It is a pan/zoom canvas: 16 sections, ~90 artboards. Every artboard is labeled.

## Fidelity
**High-fidelity.** Colors, type sizes, spacing, radii, copy, and states are final and should be matched closely. The only stand-ins:
- Quran Arabic renders in *Scheherazade New* in the HTML preview; **production must use KFGQPC Uthmanic Script HAFS** (certified mushaf font, bundled offline).
- Status bars / home indicators are mock chrome — use real system chrome.
- Prayer-time values are sample data (Dhaka, June 2026) — compute via a calculation library (e.g. `adhan-dart`).

## Design Tokens
Canonical source: **`qalbee/tokens.css`** — every `--*` variable maps 1:1 to a Flutter theme field. Two complete themes; **dark is designed, not inverted** (teal-black `#0E1513` base, soft-white ink `#E4E9E4`, lifted low-chroma brand colors — comfortable at Fajr/Tahajjud).

### Colors (light / dark)
| Token | Light | Dark | Use |
|---|---|---|---|
| `bg` | `#F6F4EE` | `#0E1513` | screen background (warm paper / teal-black) |
| `surface` | `#FFFFFF` | `#16201D` | cards, sheets |
| `surface-2` | `#EFEBE1` | `#1D2A26` | skeletons, seg-control track, heatmap level 0 |
| `ink` | `#1F2A26` | `#E4E9E4` | primary text |
| `ink-2` | `#5A6661` | `#9BABA3` | secondary text |
| `ink-3` | `#8B958F` | `#6C7B74` | hints, disabled |
| `line` | `#E4DFD3` | `#243029` | hairlines, card borders |
| `primary` | `#15564D` | `#79C7B6` | brand teal ("qalb teal") |
| `on-primary` | `#F2F7F5` | `#07231D` | text on primary |
| `primary-soft` | `#DCE9E4` | `#1C332D` | tonal containers, active row highlight |
| `on-primary-soft` | `#123F39` | `#A7DACD` | text on primary-soft |
| `accent` | `#C08A2E` | `#E2B264` | warm honey — celebrations ONLY (streaks, iftar, qibla lock) |
| `accent-strong` | `#8F5E12` | `#E2B264` | AA-safe accent text on light |
| `accent-soft` | `#F4E6C8` | `#322817` | accent containers |
| `ok` / `ok-soft` | `#246B45` / `#DCEBDF` | `#84C9A0` / `#16271E` | completed/prayed |
| `warn` / `warn-soft` | `#8F5E12` / `#F4E6C8` | `#E2B264` / `#322817` | countdown "soon" (jamaat ≤10 min) |
| `urgent` / `urgent-soft` | `#A93B29` / `#F6DDD6` | `#E78D77` / `#36201B` | countdown "urgent" (makruh / last 20 min) — **never used for missed deeds** |
| `scrim` | `rgba(20,28,26,.45)` | `rgba(4,8,7,.6)` | sheet/dialog scrim |

All countdown state colors pass WCAG AA on their backgrounds in both themes.

### Typography — three script systems
| Role | Font | Notes |
|---|---|---|
| Latin/UI | **Schibsted Grotesk** (variable) | also default numerals, tabular for countdowns |
| Bengali | **Noto Sans Bengali** | full conjunct rendering; Bengali digits `০১২…` |
| Quran Arabic | **KFGQPC Uthmanic Script HAFS** | non-negotiable; harakat must render; preview stand-in is Scheherazade New |
| UI Arabic (RTL locale) | **IBM Plex Sans Arabic** | Eastern Arabic digits `٠١٢…` |

Type scale (size/line-height · weight): display 34/1.12·700 (−0.6 tracking) · headline 26/1.18·700 · title 19/1.25·600 · title-sm 16.5/1.3·600 · body 15/1.5·400 · label 13/1.35·600 · caption 11.5/1.4·500 · overline 11·700 (+1.4 tracking, uppercase). Countdown hero numeral: 56px·700, −1.5 tracking, tabular. UI must survive system font scaling to **1.5×** (wrap, never truncate — Bengali labels run 1.5–2× longer). The **Quran reader has its own independent user scale: 22–44px in steps of 2**, persisted separately.

### Spacing / radius / elevation / motion
- Spacing: 4pt grid — 4, 8, 12, 16, 20, 24, 32, 40.
- Radius: sm 10 · md 14 · lg 20 · xl 28 · full (pill). Cards lg; hero countdown xl; sheets 24 top corners.
- Elevation: only 2 levels. e-1 resting card, e-2 sheet/dialog (exact shadows in tokens.css; dark uses deeper black shadows).
- Motion: fast 120ms (state/ripple/tick) · med 240ms (sheets, navigation) · slow 420ms (splash, streak celebration, qibla lock). Ease `cubic-bezier(.4,0,.2,1)`. **All signature motion disabled under reduced-motion** — cut, don't animate.
- Touch targets ≥ 48dp.

### Signature motif — the qalb mark
One motif everywhere: an **8-fold star (two interlaced squares, rounded corners) holding a heart**. SVG geometry in `qalbee/base.jsx` (`QalbMark`, `Star8`, `MotifBg`, `HEART_PATH`). Rules: max one motif treatment per screen; background tiling ≤6% opacity (hero cards & splash only); never rotated off-axis; the heart appears only in the full mark, app icon, and Muhasaba tab icon.

## Screens / Views
Implementation order and full layout/state detail are in the canvas (section numbers match):
1. **01–02 Foundations & components** — build tokens + these widgets first: `CountdownCard` (5 states: calm/amber/urgent + Ramadan sahri/iftar), `PrayerTable` row, 3 tracker item types (toggle/count/duration), heatmap cell (5 levels, 13dp, r3.5), progress ring, bottom nav (5 tabs: Home/Quran/Muhasaba/Dua/More), buttons (primary/tonal/outline/ghost/accent × default/pressed/disabled/focused), inputs, sheets, dialogs.
2. **03 Splash** — mark draws in ≤2s, never blocks (no network).
3. **04 Onboarding** — Welcome → Language → Location (GPS or manual city; permission priming BEFORE OS dialog; **denied → manual picker fallback**) → Madhab (pre-selected by region, "affects Asr only") → Calculation method (auto-suggested by country) → Notification priming (+ denied state) → Bismillah finish. Re-enterable from Settings.
4. **05 Home** — header (tappable location, tri-calendar date), smart countdown hero (retargets waqt start → jamaat → waqt end; Ramadan overrides: pre-Fajr "Sahri ends in", Asr→Maghrib "Iftar in"), prayer table with current-waqt highlight + check→Muhasaba, sahri/iftar row, "Set jamaat" quiet affordance. Adapts: 360×640 compact (countdown 36px, dense 40dp rows, 11px nowrap times) and tablet two-column.
5. **06 Qibla** — dial with gold aligned state (±3°, haptic), calibration figure-8, sensor-unavailable fallback (verbal bearing), location-needed state, distance to Kaaba.
6. **07 Quran** — surah list (star-number medallion, search, juz tab, resume card), ayah-by-ayah reader (per-ayah bookmark/copy/share/play, sticky header + progress, translation-on & Arabic-only modes), reading-settings sheet, first-open & search-empty states.
7. **08 Dua & Tasbih** — categories grid, dua detail (Arabic/transliteration/translation/reference + repeat ring), full-screen tasbih (33/100/custom presets, ring, milestone pulse at target, save-before-reset confirm, session history line), Asmaul Husna.
8. **09 Muhasaba** — daily entry (salah chip row + tracker list, date switcher with back-fill), custom field flow (name/type/target/icon/color, **archive not delete** — history preserved), dashboard (Today/Week/Month/Year/Custom range, completion ring, per-item bars, heatmap, streaks, vs-previous-period), first-day & empty-range states, PIN+biometric lock, Ramadan share card (4:5 export).
9. **10 Ramadan** — roza counter, dual countdowns, month sahri/iftar table, zakat calculator (local, nisab check, breakdown), fitra card. Seasonal: lives in "More" year-round, promoted during Ramadan.
10. **11 My Mosque** — per-prayer **fixed time OR offset** (Maghrib defaults offset +5), reminder toggle + lead time, multiple profiles, optional seasonal profile.
11. **12 Settings** — grouped: calculation (location/madhab/method/per-prayer ±minutes/high-latitude), notification matrix (per-prayer azan/beep/silent/off + Ramadan extras), appearance/language, privacy (app lock, run setup again, credits).
12. **13 Calendar** — Gregorian+Hijri+Bengali per cell, Islamic dates legend, day popover with all three dates + prayer times.
13. **14 RTL** — full mirror set (Home/Quran/Settings, Arabic): leading edge flips, chevrons/back flip, Eastern Arabic numerals.
14. **15 Notifications** — azan (action "Mark as prayed"), jamaat, sahri 30-min, iftar (celebratory, accent), evening muhasaba nudge (max one), streak milestone; in-app denied education.
15. **16 Icon & store** — adaptive icon (66% safe zone, works at 48px), feature graphic, 6 screenshot frames.

## Interactions & Behavior (hard rules from the brief)
- **No guilt framing, ever**: missed deeds are neutral, never red/"failed"; heatmap level 0 reads "not yet"; copy is encouraging ("Better than last week").
- **Offline is the normal state** — never an error for core features; only audio download / future mosque finder may reference the network.
- **Every permission denial has a designed fallback path** (location → manual city; notifications → app stays fully useful).
- Countdown color transitions: calm → amber (jamaat ≤10 min) → urgent (last 20 min of waqt), animated at 240ms.
- Haptics: tasbih every tap, qibla on align, milestone pulse.
- States required for every interactive component: default/pressed/disabled/focused; every data view: loading (skeleton)/empty/error/permission-denied.

## State Management (suggested)
- `SettingsState`: location (mode+coords/city), madhab, calc method, per-prayer offsets, high-latitude rule, locale, theme, notification matrix, app-lock config.
- `PrayerSchedule`: derived daily times + current waqt + countdown target (pure function of settings + clock; drives the smart countdown state machine).
- `MosqueProfiles`: list of profiles, active id, per-prayer fixed/offset entries, seasonal pair.
- `MuhasabaStore`: item definitions (incl. archived), per-day entries keyed by date, derived streaks/aggregates. Local persistence only (e.g. Drift/Hive/Isar).
- `QuranState`: last-read bookmark, per-ayah bookmarks, font size, translation toggle.
- All persistence is on-device; there is no backend.

## Assets
- Fonts: Schibsted Grotesk, Noto Sans Bengali, IBM Plex Sans Arabic (Google Fonts / bundle); **KFGQPC Uthmanic Script HAFS** from KFGQPC (license permits app embedding — verify attribution requirements).
- Qalb mark + motif: vector geometry in `qalbee/base.jsx` (export to SVG/Flutter `CustomPainter`).
- Icons: 24px stroke set (~1.7px) defined in `qalbee/base.jsx` `QI` map — recreate or substitute a matching stroke icon set.
- No raster images anywhere in the design.

## Files
- `Qalbee Design.html` — open this; the full canvas (all sections/artboards).
- `QALBEE_DESIGN_BRIEF.md` — original product brief (binding rules + full screen inventory checklist).
- `qalbee/tokens.css` — **canonical design tokens**, light + dark.
- `qalbee/base.jsx` — motif, icon set, phone frame, primitive controls.
- `qalbee/ui.jsx` — countdown card, prayer table, tracker items, heatmap, ring, nav, compass, notification card.
- `qalbee/sec-*.jsx` — per-section screen definitions (foundations, components, splash/onboarding, home/qibla, quran/dua, muhasaba, misc, rtl/notif/store).
- `design-canvas.jsx` — canvas viewer shell (not part of the app design).
