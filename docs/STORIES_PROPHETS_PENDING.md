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

**Done, part 2 (48, branch `feat/quran-stories-2`, every ayah of every range read with
`tool/verify_refs.py`) — needs scholar review before release:** dawud_mountains_and_iron ·
dawud_two_litigants · dawud_sulaiman_judgment · sulaiman_and_the_ant ·
sulaiman_hoopoe_and_queen_of_saba · sulaiman_wind_and_jinn · sulaiman_death · harut_and_marut ·
ilyas_and_baal · alyasa_and_dhulkifl · yunus_and_the_whale · the_ruined_town · saba_and_the_dam
· three_messengers_of_the_town · luqman_advice_to_his_son · birth_of_maryam · zakariya_and_yahya
· birth_of_isa · miracles_of_isa · the_table_from_heaven · isa_raised_up · people_of_the_cave ·
owner_of_two_gardens · dhul_qarnayn · owners_of_the_garden · people_of_the_ditch ·
year_of_the_elephant · first_revelation · abu_lahab · abasa_the_blind_man · splitting_of_the_moon
· jinn_listen_to_quran · isra_and_miraj · the_hijrah · change_of_qibla · battle_of_badr ·
battle_of_uhud · banu_nadir · zayd_and_zaynab · battle_of_ahzab · the_slander_ifk ·
the_woman_who_pleaded · treaty_of_hudaybiyyah · conquest_of_makkah · battle_of_hunayn ·
tabuk_and_the_three · masjid_ad_dirar · the_mubahala

**Review before release (part 2):**
- Sensitive, written neutrally from the ayat only: harut_and_marut (no detail beyond 2:102;
  popular stories flagged as unreliable), the_slander_ifk ('A'ishah (RA) named from Bukhari),
  zayd_and_zaynab (Zaynab named from hadith/tafsir; "what he hid" given as the view of many
  scholars), isa_raised_up (how "it was made to appear so" and the meaning of 3:55 left to the
  scholars; no substitution story).
- dawud_two_litigants: the Quran does not say what the test was; the text says so and warns
  against unreliable stories.
- Names not in the Quran, marked as from hadith/sirah/tafsir: Bilqis (only as "later
  reports"), Ibn Umm Maktum (Tirmidhi 3331), Abu Bakr and Thawr, Khadijah and Hira (Bukhari 3),
  Khawlah bint Tha'labah, Banu an-Nadir, Banu Qurayzah, Najran, Ka'b ibn Malik, Tabuk, Abrahah
  not named. Not named on purpose: the ruined-town man, the town of 36:13, Dhul-Qarnayn's
  identity, the one "with knowledge of the Scripture" (27:40).
- battle_of_badr: 3:124-125 (3,000/5,000 angels) — the text says scholars differ on Badr vs Uhud.
- the_table_from_heaven: ref widened to 5:111-115 (5:111 introduces the disciples).
- birth_of_maryam includes 3:42-44; birth_of_isa uses 3:45-47 (not 3:42-44).
- alyasa_and_dhulkifl adds 21:85-86; dawud_mountains_and_iron adds 38:17-20.
- masjid_ad_dirar: the text says scholars differ on whether 9:108's mosque is Quba or the
  Prophet's mosque.
- Bangla numerals in Bangla text (২৭:১৯, ১০০) — check this matches the house style.

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
- Left out on purpose: Sulaiman and the horses 38:30-33 (the tafsir is disputed), and 2:54.

## Content totals at pause

| File | Done | Pending |
|---|---|---|
| quran_stories.json | 67 | Yusuf–Talut batch (part 1) |
| hadith_stories.json | 11 | 50 |
| prophets.json | 25 entries, 0 summaries | 25 summaries |
