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
- **Owner to decide: Muslim numbering.** The bundled hadith.db numbers Muslim hadith
  sequentially, e.g. Muslim 6162 = 2379 in the common numbering. `prophets.json` uses the
  DB numbers, but `rasul_names.json` cites the common ones (Muslim 2354). Pick one and
  make both files match.
- "Isra'il" is set as Yaqub's title. It is really an alternate name; decide whether it
  stays.

## Story lists

### Hadith stories (`hadith_stories.json`)
The Muslim refs use the bundled DB's numbering, which is the same open decision as above.

**Done (11):** three_men_in_the_cave (Bukhari 2272) · man_who_killed_one_hundred (Bukhari 3470,
Muslim 7008) · leper_bald_and_blind (Bukhari 3464) · juraij_the_worshipper (Bukhari 2482, 3436) ·
baby_who_spoke_about_the_rider (Bukhari 3436) · man_who_watered_a_thirsty_dog (Bukhari 2363) ·
sinful_woman_and_the_dog (Bukhari 3467) · woman_and_the_cat (Bukhari 3482) ·
thousand_dinars_and_the_wood (Bukhari 2291) · man_who_ordered_his_body_burnt (Bukhari 3481) ·
boy_magician_monk_and_king (Muslim 7511)

**Review before release:**
- `woman_and_the_cat`: the last moral line is not in the hadith. Remove it for strict fidelity.
- The two dog stories: the Bangla text says "মোজা (চামড়ার জুতা)" (মোজা is a sock, জুতা is a
  shoe). Check the word.

**Pending (refs already found and read in the DB, stories not written):**
Cloud watering a garden (Muslim 7473) · Jar of gold (Bukhari 3472) · Sulaiman and the two
mothers (Bukhari 3427) · Ibrahim, Sarah and the tyrant (Bukhari 2217) · Hajar, Ismail and
Zamzam (Bukhari 3364) · Musa and the angel of death (Bukhari 1339) · Musa and the stone
(Bukhari 278) · The prophet and the ants (Bukhari 3019) · Beginning of revelation (Bukhari 3) ·
Isra and Mi'raj (Bukhari 3887) · Abu Hurairah and the Shaytan (Bukhari 2311) · Ka'b ibn Malik
(Bukhari 4418) · The Ansari who fed his guest (Bukhari 3798) · Thumamah (Bukhari 4372) · Abu
Talhah and Umm Sulaym (Bukhari 5470) · Jabir's food at the Trench (Bukhari 4101) · Last man to
enter Paradise (Bukhari 6571) · Weeping palm trunk (Bukhari 3584) · The debtor's funeral
(Bukhari 2289) · Earth threw out the apostate (Bukhari 3617) · Tamim ad-Dari and al-Jassasah
(Muslim 7386) · Musa and al-Khidr (Bukhari 3401) · Merchant who forgave debtors (Bukhari 2078) ·
Thorny branch (Bukhari 652) · Mother who shared the dates (Bukhari 1418) · Ayyub's golden
locusts (Bukhari 279) · Adam and Musa argue (Bukhari 3409) · "Two whose third is Allah"
(Bukhari 3653) · Charity given to a thief (Bukhari 1421) · 'Isa and the thief (Bukhari 3444) ·
"Forgive my people" (Bukhari 6929) · Al-Fatiha as ruqyah (Bukhari 2276) · Hittah (Bukhari
4479) · Ibrahim and Azar (Bukhari 3350) · The Jewish boy (Bukhari 1356) · The cow and the wolf
that spoke (Bukhari 3471) · The sun held back (Bukhari 3124) · Bedouin in the mosque (Bukhari
220) · Water from his fingers (Bukhari 3576) · Joy over the lost camel (Bukhari 6309) · Uwais
al-Qarani (Muslim 6492) · "Allah will not forgive so-and-so" (Muslim 6681) · Abu Hurairah's
mother (Muslim 6396) · The card / Bitaqah (Tirmidhi 2639) · Adam gives Dawud 40 years
(Tirmidhi 3076) · Abu Hurairah and the bowl of milk (Bukhari 6452) · Khubaib (Bukhari 3045) ·
The camel that complained (Abu Dawud 2549) · Hadith of Jibril (Bukhari 50) · Heraclius and Abu
Sufyan (Bukhari 7)

Uwais al-Qarani, the card (Bitaqah) and the camel that complained come from collections
outside Bukhari and Muslim. Check their grading with a scholar before writing them.

### Quran stories (`quran_stories.json`)

**Done (19 + 34 = 53). First 19, with the first and last ayah of every range checked:** adam_creation ·
adam_in_the_garden · two_sons_of_adam · idris · nuh_and_the_flood · hud_and_ad ·
salih_and_the_she_camel · ibrahim_searches_for_his_lord · ibrahim_and_his_father ·
ibrahim_breaks_the_idols · ibrahim_in_the_fire · ibrahim_and_the_king ·
ibrahim_and_the_four_birds · ibrahim_honoured_guests · lut_and_his_people ·
ibrahim_family_in_the_valley · ibrahim_sacrifice · building_the_kabah · ismail_true_to_promise

**Done (34), 2026-11-05, branch `feat/quran-stories-1`, every ayah of every range read with
the ref checker (scholar review still pending):** yusuf_1_the_dream · yusuf_2_the_well ·
yusuf_3_the_house_of_al_aziz · yusuf_4_the_prison · yusuf_5_the_kings_dream ·
yusuf_6_the_brothers_come_to_egypt · yusuf_7_the_family_reunited · yaqub_advice_to_his_sons ·
ayyub_patience · shuayb_and_madyan · musa_birth_and_the_river · musa_flees_egypt ·
musa_in_madyan · musa_and_the_burning_bush · musa_and_harun_before_pharaoh ·
musa_and_the_magicians · pharaoh_the_signs_and_the_tower · believer_of_pharaohs_family ·
wife_of_pharaoh · musa_crossing_the_sea · manna_quails_and_twelve_springs ·
musa_asks_to_see_allah · the_golden_calf · the_seventy_chosen_men · the_cow_of_bani_israel ·
the_holy_land_and_forty_years · the_word_hittah · qarun_and_his_treasure · musa_and_al_khidr ·
harun_brother_of_musa · people_of_the_sabbath · man_who_threw_off_the_signs ·
those_who_fled_death · talut_and_jalut

**Review before release (2026-11-05 batch):**
- Marked in the text as from the scholars/hadith, not the Quran: Binyamin's name; the
  prostration in 12:100 as a greeting allowed in their law; Asiya's name (Bukhari 3769);
  al-Khidr and Yusha' ibn Nun (Bukhari 3401); the "messenger" of 20:96 as Jibril; the
  seventy (7:155) linked to 2:55-56.
- Stated as a difference of opinion: who speaks 12:52-53; which man speaks 28:19; whether
  the old man of Madyan is Shu'ayb; whether the People of the Wood are Madyan; the fate of
  the silent group in 7:164-165; who the man in 7:175 and the people in 2:243 were; the
  town of Hittah.
- Left out: Zulaikha's name; the content of Ayyub's oath (38:44); 27:8 "whoever is in the
  fire"; the changed word in 2:59 (comes from hadith, Bukhari 4479); the dead man naming
  his killer (2:73, tafsir); the prophet of 2:246's name; 19:28 "sister of Harun".
- `harun_brother_of_musa` is a summary of the Harun ayat in `prophets.json`, plus 23:45-48
  and 7:150-151.
- `talut_and_jalut` mentions Dawud (AS); link it from Dawud too if wanted.
- 2:243 and 7:175-176 are very short, so those two stories are short as well.

**Review before release (first 19):**
- Habil/Qabil, Namrud and Sarah are not named in the Quran. The text marks those names as
  coming from the scholars.
- The Hajar and Zamzam part comes from hadith (Bukhari 3364); its only Quran ref is 2:158.
- The text says the sacrificed son was Ismail, which is the majority view.
- Left out on purpose: the "daughters" (11:78) and "I am sick" (37:88-89).
- Mid-range ayahs of long ranges were not read one by one; re-read them during review.

**Pending (planned ranges):**
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
- Not written in the Musa batch (outside the planned ranges): 7:137-141 (asking for an idol
  after the crossing), 2:63-64 (the mount raised over them).

## Content totals at pause

| File | Done | Pending |
|---|---|---|
| quran_stories.json | 53 | about 46 |
| hadith_stories.json | 11 | 50 |
| prophets.json | 25 entries, 0 summaries | 25 summaries |
