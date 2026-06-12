# Qalbee — Design Brief

> **Audience of this document:** This brief instructs the design agent ("Claude Design") to produce the complete visual design system and screen designs for Qalbee. Read this entire document before producing any design. Nothing listed here may be skipped or merged away.

---

## 1. Product Overview

**Qalbee** (from *qalb*, قلب — the heart) is an offline-first Islamic lifestyle app for a **global Muslim audience**. It is built in Flutter, has **no backend**, and works fully without internet.

Core promise: *a companion for the heart's daily deen* — accurate prayer times anywhere on earth, qibla direction, Quran, dua, and a unique self-accountability (Muhasaba) tracker.

### Feature pillars
1. **Prayer times** — location-based calculation (any city worldwide), sahri/iftar, jamaat times, smart countdown
2. **Qibla compass** — live sensor-based compass
3. **Quran** — offline Arabic + translation reader
4. **Dua & Tasbih** — dua collections, digital tasbih counter, Asmaul Husna
5. **Muhasaba** — daily good-deed tracker with custom fields and progress dashboard (the app's differentiator)
6. **Ramadan** — roza counter, sahri/iftar countdowns, monthly calendar, zakat calculator
7. **Utilities** — Hijri calendar, settings, "My Mosque" jamaat configuration

---

## 2. Brand & Aesthetic Direction

### Identity
- The brand concept is the **qalb (heart)** — purification, reflection, tranquility. The design should feel like a quiet moment of worship: calm, warm, dignified. Not corporate, not gamified-loud, not template "green mosque app".
- Avoid the clichés of the category: no glossy mosque-dome photo headers, no harsh neon green, no cluttered ad-style home screens (the Muslim Pro look). Qalbee should feel closer to a premium habit/meditation app in polish, but unmistakably Islamic in soul.
- A subtle geometric Islamic pattern language (derived from one chosen motif — e.g. an 8-fold star or a heart-derived arabesque) may be used as the **signature element**, applied with restraint (backgrounds at low opacity, section dividers, the splash mark). Choose ONE motif and use it consistently everywhere.

### Color
- Designer chooses the final palette, but it must satisfy:
  - A calm, spiritual primary (deep teal / midnight / forest family are candidates — avoid pure saturated green #00FF00 territory)
  - A warm accent for moments of celebration (streaks, iftar time, completed days)
  - Full **light and dark themes** designed from day one. Dark theme is not an inversion — design it deliberately (many users use this app at Fajr/Tahajjud in the dark; dark theme must be comfortable at night, low luminance, no pure white text on pure black).
  - Semantic countdown colors: neutral/green (time remaining), amber (jamaat ≤10 min / urgency), red-ish (makruh window / last 20 min of waqt). These must pass WCAG AA contrast in both themes.
- Define the palette as named design tokens (e.g. `primary`, `surface`, `accentWarm`, `stateUrgent`...) — the dev team maps these 1:1 to Flutter ThemeData.

### Typography
- **Three script systems must coexist:** Latin, Bengali, and Arabic (plus RTL languages later: Urdu, Arabic UI).
  - Latin/UI: one clean, characterful sans (variable font preferred).
  - Bengali: a font with proper conjunct rendering (e.g. Noto Serif/Sans Bengali class).
  - Arabic Quran text: **KFGQPC Uthmanic Script HAFS** (or equivalent certified mushaf font) — non-negotiable for the Quran reader; harakat must render correctly. UI Arabic (labels) may use a separate modern Arabic UI font.
- Define a full type scale (display, headline, title, body, label, caption) with sizes for both phone and large-font accessibility settings. Quran reader has its own independent, user-adjustable scale.
- Numerals: support both Western (123) and Bengali (১২৩) / Eastern Arabic (١٢٣) digits depending on locale — show this in mockups.

### Motion
- Gentle, purposeful. Signature moments: splash mark animation, countdown tick, qibla alignment feedback, tasbih tap ripple, streak celebration. Everything else stays quiet. Respect reduced-motion settings.

### Tone of copy in designs
- Encouraging, never guilt-inducing. Progress framing is always positive ("Better than last week"), never "Failed" / red shame states for missed deeds. This is a hard product rule — reflect it in every dashboard/empty/zero state.

---

## 3. Global Design Requirements (apply to every screen)

- **Both themes** (light + dark) for every screen.
- **RTL mirrored layouts** — provide at least one full RTL example set (Arabic locale) covering Home, Quran reader, and Settings; all components must be direction-aware.
- **Localization-proof layouts** — labels will be 1.5–2x longer in Bengali/Indonesian than English; no fixed-width text containers that truncate.
- **Offline is the normal state** — never design "no internet" as an error for core features. The only online-optional features are audio recitation download and (future) mosque finder.
- **Accessibility:** WCAG AA contrast, minimum 48dp touch targets, support for system font scaling up to 1.5x without breakage, meaningful states without color-only signaling.
- **Component states:** for every interactive component provide default / pressed / disabled / focused; for every data view provide loading (skeleton, not spinner where possible), empty, error, and permission-denied states.
- Design at 390×844 baseline; show how Home and Quran adapt to small (360×640) and large/tablet widths.

---

## 4. Screen Inventory — design EVERY item below

### 4.1 Splash Screen
- Animated brand mark (the qalb/heart-pattern motif resolving into the logo). Duration ≤ 2s, skippable feel — splash never blocks on network (there is no network dependency).
- Light + dark variants. App name "Qalbee" with tagline.

### 4.2 Onboarding (first launch only — design the full flow)
1. **Welcome** — brand story in one screen (what Qalbee is, 1 line).
2. **Language selection** — English default; Bangla, (later Arabic, Urdu, Indonesian, Turkish). This screen appears before anything else after welcome.
3. **Location setup** — two paths side by side: "Use my location (GPS)" and "Choose city manually" (search list with country flags). Include the permission-priming explanation BEFORE the OS dialog, and the **permission-denied fallback state** (gracefully routes to manual city picker).
4. **Madhab selection** — Hanafi / Shafiʿi with a one-line friendly explanation ("affects Asr time only"). Default pre-selected by region.
5. **Calculation method** — auto-suggested from country, changeable, with "you can change this later in Settings" note.
6. **Notification permission priming** — explain azan + jamaat + muhasaba reminders, then OS prompt; include denied-state design.
7. **Finish / "Bismillah" moment** — a brief delightful transition into Home.
- Onboarding must be re-enterable from Settings ("Run setup again").

### 4.3 Home Screen
- Header: location name (tappable → location settings), today's date in three calendars (Gregorian + Hijri + Bengali where locale relevant).
- **Hero: smart countdown card** — current prayer name + one large countdown that contextually targets: next waqt start → jamaat (if configured) → waqt end. Label changes accordingly ("Asr starts in / Jamaat in / Asr ends in"). Color state transitions (neutral → amber → urgent). Design all three states.
- **Ramadan override states:** pre-Fajr shows "Sahri ends in" priority; Asr→Maghrib window shows "Iftar in". Design both.
- Daily prayer table: 5 prayers + sunrise; columns for start–end, jamaat time (if set), and a check/track affordance linked to Muhasaba. Current waqt row highlighted.
- Sahri & Iftar times row (always visible; elevated during Ramadan).
- Empty/edge: jamaat not configured (row shows subtle "Set jamaat" affordance, no nagging).

### 4.4 Qibla Compass
- Full-screen compass: Kaaba direction needle/arrow, current heading in degrees + cardinal text.
- **Aligned state:** distinct visual + (described) haptic when pointing within tolerance — design the locked/aligned celebration subtly.
- Calibration prompt state (figure-8 instruction, illustrated), sensor-unavailable state, location-needed state.
- Show distance to Kaaba as a quiet detail.

### 4.5 Quran
- **Surah list:** 114 entries — Arabic name, transliteration, translated name, ayah count, revelation place icon; search; juz tab optional. "Continue reading" resume card at top (last bookmark).
- **Reader:** ayah-by-ayah layout — Uthmani Arabic prominent, translation beneath; per-ayah actions (bookmark, copy, share, play-audio placeholder). Sticky surah header with progress. Font-size control. Design both translation-on and Arabic-only modes. Night-reading comfort is paramount in dark theme.
- States: first-open (no bookmark), search-empty.

### 4.6 Dua & Tasbih
- Dua categories grid/list (morning–evening, food, sleep, travel, etc.) → dua detail (Arabic, transliteration, translation, reference, counter if repeatable).
- **Tasbih counter:** full-screen tappable counter — big count, target presets (33/100/custom), progress ring, haptic on tap, milestone pulse at target, reset with confirm, session history line. This screen should feel tactile and beautiful; it's a daily-touch surface.
- **Asmaul Husna:** 99 names browse view + detail.

### 4.7 Muhasaba (the differentiator — give it the most design attention)
- **Daily entry screen:** today's checklist — default items (5 prayers individually, Quran, hadith, roza, azkar, sadaqah, tahajjud...) + user's custom items. Three input types rendered distinctly: yes/no toggle, count stepper (with target), duration. Quick, one-thumb completion. Date switcher to back-fill yesterday.
- **Custom field creation flow:** name, type (yes/no, count, duration), optional daily target, icon/color pick from a curated set. Also: archive (not delete) flow with explanation that history is preserved.
- **Dashboard:** period selector (Today / Week / Month / Year / Custom range with date-range picker). Contents: overall completion %, per-item progress bars, **calendar heatmap** (GitHub-style intensity), streak highlights, trend line vs previous period. All framed positively.
- **Empty states:** first day (welcoming explanation of muhasaba), no data in selected range.
- **Privacy:** optional PIN/biometric lock state for this section — design the lock screen.
- Period summary share-card (e.g. Ramadan summary) as a designed exportable image.

### 4.8 Ramadan
- Roza counter (day N of 29/30, remaining), big sahri/iftar countdowns, full-month sahri-iftar table, zakat calculator (input form + result), fitra info card. Design how this section appears/disappears seasonally (tab swap or menu entry outside Ramadan).

### 4.9 My Mosque (jamaat configuration)
- Mosque name, per-prayer jamaat entry where each prayer independently chooses **fixed time** or **offset from waqt** (Maghrib defaults to offset +5). Jamaat reminder toggle + lead-time picker. Multiple mosque profiles (home/work) with an active-profile switcher. Seasonal profile (summer/winter) as an advanced optional section.

### 4.10 Settings
- Location (GPS/manual, current city display), madhab, calculation method, **per-prayer minute adjustment (+/- offsets)**, high-latitude rule (under "advanced"), notification matrix (per-prayer: azan sound / beep / silent / off; sahri & iftar alerts; jamaat reminder; muhasaba evening reminder), theme (light/dark/system), language, Quran font size shortcut, app lock, about/credits (translation attributions required), "run setup again".
- Settings must be scannable — grouped sections, not one endless list.

### 4.11 Calendar
- Combined Gregorian + Hijri (+ Bengali) month view, Islamic important dates marked with a legend, date-detail popover showing all three dates + that day's prayer times.

### 4.12 Notifications (design these as artifacts!)
- Android/iOS notification mockups for: azan (with prayer name + time, action: "Mark as prayed"), jamaat reminder, sahri warning (e.g. 30 min), iftar moment (celebratory tone), muhasaba evening nudge, streak milestone. Include the in-app notification-permission-denied education state.

### 4.13 App Icon & Store Assets
- App icon (adaptive Android + iOS), feature graphic concept, and 4–6 store screenshot frames with captions. Icon must work at 48px and carry the qalb motif.

---

## 5. Deliverables & Order of Work

1. **Design tokens + theme spec** (colors, type scale, spacing, radius, elevation, motion durations) — light & dark.
2. **Core component library:** countdown card (all states), prayer table row, tracker item (3 types), heatmap cell spec, compass dial, tasbih counter, buttons/inputs/sheets/dialogs, navigation bar.
3. **Screens** in this order: Splash → Onboarding flow → Home → Qibla → Muhasaba (entry, custom-field, dashboard) → Quran → Dua/Tasbih → My Mosque → Settings → Ramadan → Calendar → Notifications → Icon/store.
4. Every screen delivered in light + dark; Home, Quran, Settings additionally in RTL.

## 6. Hard Rules Checklist (verify before finishing)

- [ ] No screen or state from section 4 omitted
- [ ] Light + dark for everything; RTL set provided
- [ ] No guilt/shame framing anywhere in progress UI
- [ ] Quran Arabic uses certified mushaf-grade font treatment
- [ ] All countdown color states designed and AA-compliant
- [ ] Permission-denied fallbacks designed for location & notifications
- [ ] Offline never presented as an error for core features
- [ ] One consistent signature motif, used with restraint
