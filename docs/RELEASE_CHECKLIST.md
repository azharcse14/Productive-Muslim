# Release checklist

Steps a store build needs that a dev build doesn't. Decisions behind them:
`docs/REVIEW_FIX_PLAN.md` → Owner decisions (decided 2026-11-04).

## Before building

1. **Bengali full-book hadith (hadithbangla) — no license.** Until the
   translator/publisher gives written permission (owner task), ship without it:
   ```sh
   dart run tool/strip_bengali_hadith.dart   # drops hadith_bn_section + sections_bn
   flutter build appbundle --dart-define=BENGALI_HADITH=false   # (and ipa)
   git checkout -- assets/data/hadith.db assets/data/hadith_books.json   # restore afterwards
   ```
   Strip and dart-define always go together. The dart-define also removes the
   hadithbangla credit and the online hadithbangla fallback, and tells the app
   the bundled hadith.db is stripped: an installed copy whose Bengali table
   doesn't match is replaced on first launch, so stripped <-> full releases
   need no version bump (a mismatched pair re-copies on every launch).
   English, Arabic and the fawazahmed0 Bengali editions (40 Hadith, Muwatta
   Malik) stay. Once permission arrives: skip this step and update
   `docs/DEPENDENCIES.md`; bump `HadithDatabase.bundledVersion` +
   `PRAGMA user_version` only if the DB content itself changes.
2. **`dua-ruqya-server` (90 `hm_*` duas) — no license.** Still `NO LICENSE —
   permission needed` in `docs/DEPENDENCIES.md`; get permission or replace the
   Bengali wording before a public release.
3. **Jamaat Focus / Nafs lock (`focusBlocking`, default on).** Play Console:
   Accessibility API declaration + demo video with the first upload; the
   in-app disclosure must say the session re-enables Do Not Disturb if it is
   turned off. If Play rejects it: rebuild with
   `ORG_GRADLE_PROJECT_focusBlocking=false` and a new versionCode.
4. **Tanzil translations** (Pickthall, Muhiuddin Khan) are licensed for
   non-commercial use only — the app must stay free, with no ads or purchases,
   unless the translator/publisher gives permission.
5. **CI**: the android job has never run on GitHub — push and let it pass.

## Device QA (no automated substitute)

- 360dp screen at 1.0×, 1.5×, 2.0× text; light + dark; Bangla + English;
  TalkBack / VoiceOver.
- Jamaat Focus + Nafs lock on Samsung, Xiaomi, Realme, Vivo/Oppo: the 5 s
  cancel screen appears from the background, Settings → Accessibility stays
  reachable, an alarm stays visible, API 36 back gesture keeps the cover.
- Reboot without unlocking (FBE device): azan / sahri due before the first
  unlock still arrive (`DirectBoot.kt`), tapping one after unlock opens the
  right screen, and nothing repeats after unlock. Known gaps until unlock:
  no Jamaat Focus session (its state is credential-encrypted) and no "mark
  as prayed" action on the azan.
- Home widget: stale state after +8 days; the iOS widget target
  (`ios/ProductiveMuslimWidget/SETUP.md`) still has to be added in Xcode.
- UI audit screenshots: `flutter drive … -d DEVICE_ID` (see
  `integration_test/ui_audit_test.dart`).
