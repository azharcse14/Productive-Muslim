# Full-project review follow-ups — 2026-11-02

A read-only review of the whole project, followed by fixes on five branches. All five were
merged into `master` via `integrate/review-fixes`: `fix/review-muhasaba`,
`fix/review-fasting-expenses`, `fix/review-prayer-widget`, `fix/review-notifications-native`
and `fix/review-core-settings`. The items below are still open.

## Failing tests after the merge — fixed 2026-11-03 on `fix/review-followups`

Full suite 1354 green; debug APK builds; Kotlin unit tests pass.

The full `flutter test` run on `integrate/review-fixes` gave 1347 pass and 6 fail. The owner
asked to merge without more test runs.
- [x] `expense_screen_test.dart`: "re-dating an evening entry to today never lands after now".
  **New in this merge.** It passed on `fix/review-fasting-expenses`, so master's UI changes to
  the expense sheet (`fix/ui-features-*` / `fix/ux-*`) most likely changed the date-picker flow
  the test drives. Check the clamp in `expense_screen.dart` still runs, then fix the test.
- [x] The 5 already on master before this merge. They are listed in `REVIEW_FIX_PLAN.md`
  § "UX review follow-ups — 2026-11-02 (second pass)":
  - `age_screen_test` "as-of before birth"
  - `my_mosque_screen_test` "mode segments…"
  - `notification_settings_screen_test` "failed reschedule…"
  - `home_screen_test` "exact-alarm banner…"
  - `home_screen_test` "nearby mosques…"
- [x] `flutter build apk --debug` and `./gradlew :app:testDebugUnitTest` have not been run on the
  merged master. Both passed on `fix/review-notifications-native` and `fix/review-core-settings`
  separately.

## Merge resolutions to double-check

- `day_timeline_sheet.dart`: the two versions were combined. The sheet is now
  `showDayTimelineSheet(now: () => …, sheet: (minuteNow) => DayTimelineSheet(...))`. It keeps the
  live day (it rolls over at midnight) and master's floor-to-the-minute rebuild.
- `fasting_screen.dart`: master's month-calendar layout is kept. The heatmap label counts every
  logged day in the month, not `stats.thisMonth`, which is now nafl only.
- `quran_unavailable.dart` stays at `lib/features/quran/presentation/widgets/` (git suggested
  moving it to `lib/shared/reader/`).
- `ramadan_screen_test.dart` was added on both sides. Master's file is kept; the branch's test is
  now `ramadan_today_card_test.dart`.

## Not done — needs owner, scholar or more work

- [x] **Manual-city DST gap** — fixed on `fix/manual-city-dst` (2026-11-03, `integrate/followups-2`): wall times are floating `DateTime.utc` app-wide, `utcInstantOf` only for targets, countdown from the real instant; suite also green under `TZ=America/New_York`. (`settings/data/datasources/timezone_clock.dart`): device-local
  `DateTime`s shift by 1h inside the device's spring-forward hour. The fix agent was stopped
  before reporting on it. Carrying wall times as `DateTime.utc(...)` touches prayer_times and
  notifications callers.
- [x] **29-day Ramadan.** — `feat/ramadan-29-bangla-cal` (2026-11-03, `integrate/followups-2`): per-year "Eid announced after 29 days" override. In the tabular Hijri calendar, Ramadan is always 30 days. When people
  observe 29 days, Eid shows as "Roza 30" and fasting can be logged on Eid. Needs a scholar and
  owner decision, for example an "Eid announced" switch.
- [~] **iOS entitlements.** — `Runner.entitlements` wired into the build configs and the Debug team pinned (2026-11-03, `integrate/followups-2`). Still needed: App Group + Time Sensitive capability enabled for the App ID in the Apple developer portal. `CODE_SIGN_ENTITLEMENTS` is missing from `project.pbxproj`, so azan
  `timeSensitive` and the App Group are not active. Needs Xcode and an Apple account
  (App Group provisioning).
- [x] **Suspected Quran translation typos.** — both are in the upstream Tanzil Pickthall text; left unedited (religious-text rule). Owner decides whether to patch the build script. Verify these against the Pickthall source; don't
  edit them without the owner:
  - 3:1 "Alim. Lam. Mim" (should probably be "Alif").
  - 12:1 "These are verse…" (should probably be "verses").
- [x] **Duas without Bengali transliteration.** — done in content audit A3 (2026-11-03); 0 of 152 missing now. 63 of 156 duas have no `trBn` (e.g.
  `fd_bismillah`, `tv_safar`), so the Bengali UI mixes in Latin script. This is a content task.
- [ ] **Pickthall license** is still `UNVERIFIED`. The credits screen no longer claims a license.
- [ ] **Muhasaba, already-migrated users:**
  - Users already on schema v2/v3 keep the wrong `archived_on` for trackers that were archived in v1.
  - Trackers back-filled before v4 keep their lowered `created_on`. This can't be repaired
    without the true creation day.
- [x] **Muhasaba migration** (fixed `d1ef66e`, location wall clock) used `DateTime.now()` instead of the location wall clock (low).
- [x] **Old notification channel.** — retired on `fix/notif-native-followups` (2026-11-03, `integrate/followups-2`); its items moved to `productive_muslim_alerts` (custom user settings on the old channel are not carried over). `productive_muslim_reminders` (high importance) remains in
  system settings now that daily reminders use `productive_muslim_daily`. Delete it once
  installs have upgraded.
- [x] `focusEnd` notification: own default-importance channel `productive_muslim_focus_end`, iOS `active`. Was: decide whether it should also be calmer (non-time-sensitive).
- [x] **Nafs focus sessions** — now formatted in the app locale and the location zone (device format if the zone is unknown). Was: still format the end time with the device locale and zone; the
  native side sets the end time when the session starts.

## Decided

- Ramadan: an Isha jamaat that is still ahead (taraweeh) keeps the countdown. After it, the
  target is tomorrow's sahri end (owner, 2026-11-02).
- Widget legacy keys: the fallback is kept as it is. Showing an untimestamped `widget_prayer`
  could show a prayer that has already passed.
