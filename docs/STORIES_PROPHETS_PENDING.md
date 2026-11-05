# Stories + Prophets — pending work (paused 2026-11-04)

Spec: `docs/superpowers/specs/2026-11-04-stories-and-prophets-design.md`

## Resume on any PC

Everything is merged into `master` (2026-11-04). Nothing lives only in a local worktree.

```sh
git clone https://github.com/azharcse14/productive_muslim.git   # or: git pull on master
cd productive_muslim
flutter pub get
git checkout -b feat/stories-content     # one branch per change set (CLAUDE.md)
```

Then work through the TODOs below in order. Gates come before every commit (CLAUDE.md):
`flutter gen-l10n` with the gen diff clean, `flutter analyze` at zero issues, and `flutter test`
all green.

How to ask Claude Code to continue: *"Read docs/STORIES_PROPHETS_PENDING.md and continue
the pending work."*

## Ref checker

`python3 -I tool/verify_refs.py quran 12 4 7` / `hadith bukhari 3470` / `grep bukhari "phrase"`
(run from the repo root). It reads `assets/data/quran.db` (`ayahs.translation_en/bn`) and the gzip/zlib JSON
blobs in `assets/data/hadith.db` (`hadith_section`, edition `eng-<book>`, items `{n,t}`).
Every ref must be read and matched before it ships.

## Status

### Stories code: DONE (in master)
- `lib/features/stories/`, routes `/stories` + `/stories/:kind/:id`, 2 More tiles, tests.

### Stories content: IN PROGRESS
- `assets/data/quran_stories.json`, `assets/data/hadith_stories.json`: see "Story lists"
  below for what is done and what is pending.

### Prophets code: IN PROGRESS (in master: it compiles, but it has NO tests)
- Done: entity, `layoutLineage` (pure Dart), repo, store, `LineagePainter`, list + detail
  screens, routes `/prophets` + `/prophets/:id`, More tile, DI, credits, 7 ARB keys,
  DEPENDENCIES row. analyze clean, and the existing 1660 tests pass.
- TODO:
  1. **Write the tests (CLAUDE.md requires them; they are missing):**
     - `test/features/prophets/domain/lineage_test.dart`: Ibrahim → Ismail + Ishaq branch,
       Ishaq → Yaqub → Yusuf continuing, null parent, unknown parent, a parent that comes
       later, the dashed Ismail → Muhammad link, and a root that must not land on a
       passing line.
     - A parse test, plus an integrity test that reads the real `assets/data/prophets.json`:
       25 entries, orders 1..25, unique ids, parents resolve to a lower order, Adam first
       and Muhammad last, `quranMentions` match `^\d+:\d+(-\d+)?$`. Add "summary non-empty
       in both languages" only once the summaries are written.
     - A widget test going from the list to the detail page, including the empty-summary
       state. Copy the router setup from `test/features/ruqyah/ruqyah_screens_test.dart`.
  2. Wire the story buttons on the prophet detail page (look for the `ponytail:` comment in
     `prophet_screen.dart`), use `Routes.story` from stories, and fill `storyIds` in
     `prophets.json` with ids from `quran_stories.json`. Go through routes only; never
     import `features/stories`.

### Prophets content `prophets.json`: PARTIAL
- Done: 25 entries (names Ar/En/Bn, order, parents, titles for 10, `quranMentions` for all,
  `hadithRefs` read in hadith.db).
- **PENDING: summaryEn/summaryBn for all 25.** Take care with these:
  - The son in 37:100-111 is not named in the Quran. The majority view is that it is Ismail.
  - Whether Dhul-Kifl was a prophet is a scholarly difference.
  - Idris's era is not stated in the Quran.
  - Lut being Ibrahim's nephew comes from scholars, not the Quran.
  - Whether the People of the Wood are the same as Madyan is a scholarly question.
- **Muslim numbering: DECIDED (owner, 2026-11-05).** Every Muslim ref uses the bundled
  hadith.db numbering (sequential, e.g. Muslim 6162 = 2379 in the common numbering), since
  the app and the ref checker read that DB. `rasul_names.json` was converted: 2354 → 6105,
  2355 → 6108, 2276 → 5938.
- "Isra'il" is set as Yaqub's title. It is really an alternate name; decide whether it
  stays.

## Story lists

### Hadith stories (`hadith_stories.json`)
Muslim refs use the bundled DB numbering (decided 2026-11-05).

**Done (58):** three_men_in_the_cave (Bukhari 2272) · man_who_killed_one_hundred (Bukhari 3470, Muslim 7008) · leper_bald_and_blind (Bukhari 3464) · juraij_the_worshipper (Bukhari 2482, Bukhari 3436) · baby_who_spoke_about_the_rider (Bukhari 3436) · man_who_watered_a_thirsty_dog (Bukhari 2363) · sinful_woman_and_the_dog (Bukhari 3467) · woman_and_the_cat (Bukhari 3482) · thousand_dinars_and_the_wood (Bukhari 2291) · man_who_ordered_his_body_burnt (Bukhari 3481) · boy_magician_monk_and_king (Muslim 7511) · cloud_that_watered_a_garden (Muslim 7473) · jar_of_gold (Bukhari 3472) · sulaiman_and_the_two_mothers (Bukhari 3427) · ibrahim_sarah_and_the_tyrant (Bukhari 2217) · hajar_ismail_and_zamzam (Bukhari 3364) · musa_and_the_angel_of_death (Bukhari 1339) · musa_and_the_stone (Bukhari 278) · prophet_and_the_ants (Bukhari 3019) · beginning_of_revelation (Bukhari 3) · isra_and_miraj (Bukhari 3887) · abu_hurairah_and_the_shaytan (Bukhari 2311) · kab_ibn_malik_and_tabuk (Bukhari 4418) · ansari_who_fed_his_guest (Bukhari 3798) · thumamah_ibn_uthal (Bukhari 4372) · abu_talhah_and_umm_sulaym (Bukhari 5470) · jabir_food_at_the_trench (Bukhari 4101) · last_man_to_enter_paradise (Bukhari 6571) · weeping_palm_trunk (Bukhari 3584) · debtors_funeral (Bukhari 2289) · earth_threw_out_the_apostate (Bukhari 3617) · tamim_ad_dari_and_al_jassasah (Muslim 7386) · musa_and_al_khidr (Bukhari 3401) · merchant_who_forgave_debtors (Bukhari 2078) · thorny_branch_on_the_road (Bukhari 652) · mother_who_shared_one_date (Bukhari 1418) · ayyub_and_the_golden_locusts (Bukhari 279) · adam_and_musa_argue (Bukhari 3409) · two_whose_third_is_allah (Bukhari 3653) · charity_given_to_a_thief (Bukhari 1421) · isa_and_the_thief (Bukhari 3444) · forgive_my_people (Bukhari 6929) · al_fatiha_as_ruqyah (Bukhari 2276) · hittah_the_changed_word (Bukhari 4479) · ibrahim_and_azar_on_judgement_day (Bukhari 3350) · the_jewish_boy_who_served_the_prophet (Bukhari 1356) · cow_and_wolf_that_spoke (Bukhari 3471) · sun_held_back (Bukhari 3124) · bedouin_in_the_mosque (Bukhari 220) · water_from_his_fingers (Bukhari 3576) · joy_over_the_lost_camel (Bukhari 6309, Bukhari 6308, Muslim 6960) · uwais_al_qarani (Muslim 6492) · allah_will_not_forgive_so_and_so (Muslim 6681) · abu_hurairah_and_his_mother (Muslim 6396) · abu_hurairah_and_the_bowl_of_milk (Bukhari 6452) · khubaib (Bukhari 3045) · hadith_of_jibril (Bukhari 50) · heraclius_and_abu_sufyan (Bukhari 7)

**Fixed 2026-11-05:** `woman_and_the_cat` no longer ends with a moral line that is not in the
hadith. The two dog stories now say "চামড়ার মোজা" (khuff).

**Needs scholar review (all 58, plus these points from the 2026-11-05 batch):**
- Condensed long hadith: Ka'b ibn Malik (4418), Heraclius (7), Tamim ad-Dari (Muslim 7386),
  Hajar and Zamzam (3364), Isra and Mi'raj (3887). Nothing was added, but parts were left out.
- `musa_and_al_khidr`: Bukhari 3401 in the DB ends at the parting, so al-Khidr's explanations
  (Quran 18:79-82) are not included. al-Khidr has no "(AS)" (his prophethood is a difference).
- `isra_and_miraj`: Jibril's words on the milk read "the fitrah" (the Arabic); the DB English has
  "the Islamic religion". This narration has no Bayt al-Maqdis part.
- Unnamed prophets stay unnamed: the ants (3019), the sun held back (3124).
- `mother_who_shared_one_date`: Bukhari 1418 has one date split between two daughters (the
  three-dates version is in Muslim).
- `ibrahim_and_azar_on_judgement_day`: the DB's "Dhabh" is rendered "a blood-stained animal".
- `joy_over_the_lost_camel` also cites Bukhari 6308 and Muslim 6960 for the full scene.
- `hadith_of_jibril` follows Bukhari 50 (Abu Hurairah), not the 'Umar version in Muslim.
- `khubaib`: his verses are paraphrased from the DB English; his dua against his captors is
  summarised in one line.
- `thumamah_ibn_uthal`: "Sabi" wording; `abu_hurairah_and_the_shaytan`: the Bangla adds
  "(সদকাতুল ফিতর)" after the zakat of Ramadan.
- Narrators given only as "'Abdullah" in the DB (6571, 6929) are not expanded to Ibn Mas'ud.

**Pending (outside Bukhari/Muslim, check the grading with a scholar before writing):**
The card / Bitaqah (Tirmidhi 2639) · Adam gives Dawud 40 years (Tirmidhi 3076) · The camel
that complained (Abu Dawud 2549). Uwais al-Qarani turned out to be in Muslim (6492) and is done.

### Quran stories (`quran_stories.json`)

**Done (19), with the first and last ayah of every range checked:** adam_creation ·
adam_in_the_garden · two_sons_of_adam · idris · nuh_and_the_flood · hud_and_ad ·
salih_and_the_she_camel · ibrahim_searches_for_his_lord · ibrahim_and_his_father ·
ibrahim_breaks_the_idols · ibrahim_in_the_fire · ibrahim_and_the_king ·
ibrahim_and_the_four_birds · ibrahim_honoured_guests · lut_and_his_people ·
ibrahim_family_in_the_valley · ibrahim_sacrifice · building_the_kabah · ismail_true_to_promise

**Review before release:**
- Habil/Qabil, Namrud and Sarah are not named in the Quran. The text marks those names as
  coming from the scholars.
- The Hajar and Zamzam part comes from hadith (Bukhari 3364); its only Quran ref is 2:158.
- The text says the sacrificed son was Ismail, which is the majority view.
- Left out on purpose: the "daughters" (11:78) and "I am sick" (37:88-89).
- Mid-range ayahs of long ranges were not read one by one; re-read them during review.

**Pending (planned ranges):**
- Yusuf, 7 parts: 12:4-6, 7-18, 19-29, 30-42, 43-57, 58-79, 80-101.
- Ya'qub's advice 2:132-133 · Ayyub 21:83-84, 38:41-44 · Shu'ayb 7:85-93, 11:84-95,
  26:176-191.
- Musa: birth 28:3-13, 20:38-40 · flight 28:14-21 · Madyan 28:22-28 · bush 28:29-35, 20:9-36,
  27:7-12 · Pharaoh 20:43-56, 26:16-33 · magicians 7:109-126, 20:57-73, 26:34-51 · plagues and
  Haman 7:130-136, 28:38, 40:36-37 · believer of Pharaoh's family 40:28-45 · Asiya 66:11, 28:9
  · sea 26:52-68, 20:77-79, 10:88-92 · manna/springs 2:57, 2:60, 7:160 · seeing Allah and the
  tablets 7:142-145 · calf/Samiri 20:83-98, 7:148-154 · the seventy 7:155-156, 2:55-56 · the
  cow 2:67-73 · the holy land 5:20-26 · Hittah 2:58-59 · Qarun 28:76-82 · Khidr 18:60-82 ·
  Harun.
- Sabbath 7:163-166, 2:65-66 · the man who threw off the signs 7:175-176 · those who fled death
  2:243 · Talut/Jalut 2:246-251.
- Dawud: 34:10-11, 21:79-80 · 38:21-26 · 21:78-79.
- Sulaiman: ants 27:15-19 · hoopoe/Saba 27:20-44 · wind/jinn 34:12-13, 21:81-82, 38:35-40 ·
  death 34:14.
- Harut and Marut 2:102 · Ilyas 37:123-132 · Al-Yasa/Dhul-Kifl 38:48, 6:86 · Yunus 37:139-148,
  21:87-88, 68:48-50, 10:98 · ruined town 2:259 · Saba's dam 34:15-19 · three messengers
  36:13-27 · Luqman 31:12-19.
- Zakariya/Yahya 3:37-41, 19:2-15, 21:89-90 · Maryam's birth 3:35-37 · 'Isa's birth 19:16-34,
  3:42-47 · miracles 3:48-51, 5:110, 61:6 · the table 5:112-115 · raised up 3:52-55, 4:157-158.
- Cave 18:9-26 · two gardens 18:32-44 · Dhul-Qarnayn 18:83-98 · owners of the garden 68:17-33
  · the Ditch 85:4-10 · the Elephant 105:1-5.
- Prophet ﷺ: first revelation 96:1-5, 74:1-5 · Abu Lahab 111, 26:214 · 'Abasa 80:1-10 · the
  moon 54:1-2 · the jinn 46:29-32, 72:1-2 · Isra/Mi'raj 17:1, 53:13-18 · Hijrah 8:30, 9:40 ·
  qibla 2:142-150 · Badr 8:5-19, 8:41-48, 3:123-127 · Uhud 3:121-122, 3:139-155, 3:172-174 ·
  Banu Nadir 59:2-4 · Zayd/Zaynab 33:36-40 · Ahzab 33:9-27 · Ifk 24:11-20 · Mujadilah 58:1-4 ·
  Hudaybiyyah 48:1, 48:18-27 · conquest 110, 17:81 · Hunayn 9:25-27 · Tabuk/the three 9:38-42,
  9:81-83, 9:92, 9:117-118 · Dirar 9:107-110 · Mubahala 3:59-61.
- Not checked yet: the Sulaiman/Dawud batch (38:17-20, 27:15-19, 27:20-44, 34:12-13, 21:81-82)
  and 8:14-19.
- Left out on purpose: Sulaiman and the horses 38:30-33 (the tafsir is disputed), and 2:54.

## Content totals at pause

| File | Done | Pending |
|---|---|---|
| quran_stories.json | 19 | about 80 |
| hadith_stories.json | 58 | 3 |
| prophets.json | 25 entries, 0 summaries | 25 summaries |
