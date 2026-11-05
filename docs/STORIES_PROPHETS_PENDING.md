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

### Prophets code: DONE (2026-11-05, `feat/prophets-tests`)
- Entity, `layoutLineage`, repo, store, `LineagePainter`, list + detail screens, routes, More
  tile, DI, credits, ARB keys, DEPENDENCIES row — all tested (`test/features/prophets/`).
- Detail page lists the prophet's Quran stories (`storyIds` → `Routes.story`). When you add a
  Quran story about a prophet, add its id to that prophet's `storyIds` in `prophets.json`
  (the integrity test checks the id exists).
- `prophet_data_test.dart` checks every prophet has non-empty `summaryEn` and `summaryBn`.

### Prophets content `prophets.json`: DRAFTED — scholar review needed before release
- Done: 25 entries (names Ar/En/Bn, order, parents, titles for 10, `quranMentions` for all,
  `hadithRefs` read in hadith.db).
- Done 2026-11-05 (`feat/prophets-summaries`): summaryEn/summaryBn for all 25 (2–3
  paragraphs each). Every claim was read in the entry's own `quranMentions`/`hadithRefs`
  (Bukhari/Muslim only; Nasai 693 and Tirmidhi 3505 were not used). **A scholar must review
  them before release.** Points marked in the text as scholarly views:
  - The son in 37:100-111 is not named in the Quran; the text gives Ismail as the view of
    the majority of scholars.
  - Dhul-Kifl's prophethood: the text says the scholars differ.
  - Idris: the Quran does not state his era; "between Adam and Nuh" is marked as the
    scholars' view.
  - Lut as Ibrahim's nephew: marked as from the scholars.
  - People of the Wood = Madyan: marked as a scholarly difference.
  - Isra'il = Ya'qub and Yahya's "word from Allah" = 'Isa: marked as scholars' explanations.
  - Muhammad ﷺ: "his greatest miracle is the revelation … the Quran" reads Bukhari 4981's
    "Divine Inspiration" as the Quran (standard, but an interpretation).
  - Left out on purpose: Ayyub's oath and branch (38:44), Lut's "daughters" (11:78),
    Ibrahim's "three lies", details of Ayyub's illness.
- **Muslim numbering: DECIDED 2026-11-05** (default chosen when the owner said "do all"; the
  owner may revisit). Every Muslim ref uses the bundled hadith.db numbering (sequential, e.g.
  Muslim 6162 = 2379 in the common numbering), since the app and the ref checker read that DB.
  `rasul_names.json` was converted: 2354 → 6105, 2355 → 6108, 2276 → 5938.
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
| hadith_stories.json | 58 | 3 |
| prophets.json | 25 entries, 25 summaries (review pending) | scholar review |
