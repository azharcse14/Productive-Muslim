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

### Stories content: DRAFTED (2026-11-05) — scholar sign-off pending
- `assets/data/quran_stories.json` (101), `assets/data/hadith_stories.json` (61): every planned
  story is written and web-reviewed against scholars' views (see the last sections). Nothing
  is left to write; what remains is a human scholar's review before release.

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
- **Lineage links from the "Salasilah Nabi/Rasul" chart (2026-11-05, `fix/prophets-lineage`).**
  The owner supplied the chart (an image; no author or source given, so UNVERIFIED). Its
  names come largely from the genealogies in Ibn Kathir's *Qisas al-Anbiya* and from
  Israelite reports. Only prophet → prophet links were taken; the names in between are not
  bundled. Every prophet except Adam now has a parent:
  - Solid (father → son): Ibrahim → Ismail, Ishaq; Ishaq → Yaqub → Yusuf; Dawud →
    Sulaiman; Zakariya → Yahya; **Ayyub → Dhul-Kifl** (the chart's view that Dhul-Kifl is
    Bishr son of Ayyub; this is a minority view and his identity is disputed).
  - Dashed (many generations): Adam → Idris → Nuh; Nuh → Hud, Salih, Ibrahim, Lut;
    Ibrahim → Shuayb (via Madyan); Ishaq → Ayyub (via Esau); Yaqub → Musa, Harun (via Levi),
    Yunus (via Binyamin), Dawud (via Yahuda); Harun → Ilyas, Al-Yasa; Sulaiman → Zakariya,
    'Isa (via Maryam); Ismail → Muhammad ﷺ (via Adnan).
  - **Changed from the chart:** the chart draws Lut descending from Hud (via Haran). Lut
    was the son of Haran, Ibrahim's brother, so he descends from Azar (Nuh → Lut, dashed),
    as the entry's own summary says.
  - A scholar should confirm these links, especially Dhul-Kifl, Yunus → Binyamin, the
    Harun → Ilyas/Al-Yasa chains, and Sulaiman → Zakariya/'Isa.
- **Muslim numbering: DECIDED 2026-11-05** (default chosen when the owner said "do all"; the
  owner may revisit). Every Muslim ref uses the bundled hadith.db numbering (sequential, e.g.
  Muslim 6162 = 2379 in the common numbering), since the app and the ref checker read that DB.
  `rasul_names.json` was converted: 2354 → 6105, 2355 → 6108, 2276 → 5938.
- Yaqub's title is now "Isra'il (another name of Yaqub)" / "ইসরাইল (ইয়াকুবের আরেক নাম)"
  (decided 2026-11-05, see "Content decisions" below).

## Story lists

### Hadith stories (`hadith_stories.json`)
Muslim refs use the bundled DB numbering (decided 2026-11-05).

**Done (61):** three_men_in_the_cave (Bukhari 2272) · man_who_killed_one_hundred (Bukhari 3470, Muslim 7008) · leper_bald_and_blind (Bukhari 3464) · juraij_the_worshipper (Bukhari 2482, Bukhari 3436) · baby_who_spoke_about_the_rider (Bukhari 3436) · man_who_watered_a_thirsty_dog (Bukhari 2363) · sinful_woman_and_the_dog (Bukhari 3467) · woman_and_the_cat (Bukhari 3482) · thousand_dinars_and_the_wood (Bukhari 2291) · man_who_ordered_his_body_burnt (Bukhari 3481) · boy_magician_monk_and_king (Muslim 7511) · cloud_that_watered_a_garden (Muslim 7473) · jar_of_gold (Bukhari 3472) · sulaiman_and_the_two_mothers (Bukhari 3427) · ibrahim_sarah_and_the_tyrant (Bukhari 2217) · hajar_ismail_and_zamzam (Bukhari 3364) · musa_and_the_angel_of_death (Bukhari 1339) · musa_and_the_stone (Bukhari 278) · prophet_and_the_ants (Bukhari 3019) · beginning_of_revelation (Bukhari 3) · isra_and_miraj (Bukhari 3887) · abu_hurairah_and_the_shaytan (Bukhari 2311) · kab_ibn_malik_and_tabuk (Bukhari 4418) · ansari_who_fed_his_guest (Bukhari 3798) · thumamah_ibn_uthal (Bukhari 4372) · abu_talhah_and_umm_sulaym (Bukhari 5470) · jabir_food_at_the_trench (Bukhari 4101) · last_man_to_enter_paradise (Bukhari 6571) · weeping_palm_trunk (Bukhari 3584) · debtors_funeral (Bukhari 2289) · earth_threw_out_the_apostate (Bukhari 3617) · tamim_ad_dari_and_al_jassasah (Muslim 7386) · musa_and_al_khidr (Bukhari 3401) · merchant_who_forgave_debtors (Bukhari 2078) · thorny_branch_on_the_road (Bukhari 652) · mother_who_shared_one_date (Bukhari 1418) · ayyub_and_the_golden_locusts (Bukhari 279) · adam_and_musa_argue (Bukhari 3409) · two_whose_third_is_allah (Bukhari 3653) · charity_given_to_a_thief (Bukhari 1421) · isa_and_the_thief (Bukhari 3444) · forgive_my_people (Bukhari 6929) · al_fatiha_as_ruqyah (Bukhari 2276) · hittah_the_changed_word (Bukhari 4479) · ibrahim_and_azar_on_judgement_day (Bukhari 3350) · the_jewish_boy_who_served_the_prophet (Bukhari 1356) · cow_and_wolf_that_spoke (Bukhari 3471) · sun_held_back (Bukhari 3124) · bedouin_in_the_mosque (Bukhari 220) · water_from_his_fingers (Bukhari 3576) · joy_over_the_lost_camel (Bukhari 6309, Bukhari 6308, Muslim 6960) · uwais_al_qarani (Muslim 6492) · allah_will_not_forgive_so_and_so (Muslim 6681) · abu_hurairah_and_his_mother (Muslim 6396) · abu_hurairah_and_the_bowl_of_milk (Bukhari 6452) · khubaib (Bukhari 3045) · hadith_of_jibril (Bukhari 50) · heraclius_and_abu_sufyan (Bukhari 7) · the_card_bitaqah (Tirmidhi 2639) · adam_gives_dawud_forty_years (Tirmidhi 3076) · camel_that_complained (Abu Dawud 2549)

**Fixed 2026-11-05:** `woman_and_the_cat` no longer ends with a moral line that is not in the
hadith. The two dog stories now say "চামড়ার মোজা" (khuff).

**Needs scholar review (all 58, plus these points from the 2026-11-05 batch):**
- Condensed long hadith: Ka'b ibn Malik (4418), Heraclius (7), Tamim ad-Dari (Muslim 7386),
  Hajar and Zamzam (3364), Isra and Mi'raj (3887). Nothing was added, but parts were left out.
- `musa_and_al_khidr`: Bukhari 3401 in the DB ends at the parting, so al-Khidr's explanations
  (Quran 18:79-82) are not included. al-Khidr now has "(AS)" in both story files (decided
  2026-11-05, majority view; see "Content decisions").
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

**Pending:** none. The three non-Bukhari/Muslim stories were graded by research and written
2026-11-05 (gradings and sources under "Content decisions"). Uwais al-Qarani turned out to be
in Muslim (6492) and is done.

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
- Bangla numerals in Bangla text (২৭:১৯, ১০০): checked 2026-11-05, this is the house style
  (see "Content decisions").

**Pending (planned ranges):**
- None: every planned range is written (parts 1 and 2, 2026-11-05).
- Left out on purpose: Sulaiman and the horses 38:30-33 (the tafsir is disputed), and 2:54.
- Not written in the Musa batch (outside the planned ranges): 7:137-141 (asking for an idol
  after the crossing), 2:63-64 (the mount raised over them).

## Content totals at pause

| File | Done | Pending |
|---|---|---|
| quran_stories.json | 101 | none planned (7:137-141, 2:63-64 noted as candidates) |
| hadith_stories.json | 61 | none |
| prophets.json | 25 entries, 25 summaries (review pending) | scholar review |

## Content decisions (2026-11-05, branch `fix/content-decisions`)

Settled by research at the owner's request (majority scholarly view as default). A scholar
should still review them with the rest of the content.

1. **Three hadith graded, all written.** Gradings are kept here, not in the story bodies (no
   existing entry puts a grading in its text). The bundled DB numbering matches each ref, and
   each story was retold from the DB English (`tool/verify_refs.py`).
   - **Bitaqah, Tirmidhi 2639** (DB grade: Sahih). at-Tirmidhi: "hasan gharib"; al-Hakim:
     sahih on Muslim's condition; al-Albani: sahih; Zubair 'Ali Za'i: sahih. The same hadith
     is Ibn Majah 4300 (al-Albani: sahih). Story `the_card_bitaqah`.
   - **Adam gives Dawud forty years, Tirmidhi 3076** (DB grade: Hasan Sahih). at-Tirmidhi:
     "hasan sahih" (narrated by several routes from Abu Hurairah); al-Hakim: sahih on Muslim's
     condition; al-Albani: sahih; Zubair 'Ali Za'i: hasan. Story `adam_gives_dawud_forty_years`.
     The last line follows the Arabic (خطئ, "erred"); the DB English has "sinned". The other
     version at the end of Tirmidhi's Tafsir (different numbers) was not used.
   - **The camel that complained, Abu Dawud 2549** (DB grade: Sahih). al-Albani: sahih
     (Sahih Abi Dawud 2549; Sahih at-Targhib 2269); Shu'ayb al-Arna'ut: isnad sahih; al-Hakim:
     sahih al-isnad; Ibn Kathir (Irshad al-Faqih 2/247): its origin is in Muslim. Note: one
     al-Albani line on sunnah.com/tohed reads "sahih, in Muslim, only the sentence about the
     mound and the palm grove"; Muslim (342) has only that part, not the camel story. The
     camel story itself is graded sahih by al-Albani in Sahih Abi Dawud and Sahih at-Targhib
     and by al-Arna'ut, so it was written. Flag for the scholar. Story `camel_that_complained`.
     "Wiped the temple of its head" (ذفراه) is rendered "stroked the side of its head".
2. **al-Khidr gets "(AS)".** The majority of scholars hold that he was a prophet (Ibn 'Atiyyah
   via Ibn Hajar; al-Fakhr ar-Razi attributes it to many scholars; IslamQA 21793 concludes he
   was a prophet from the ayat, e.g. "I did it not of my own accord", 18:82). A minority (e.g.
   al-Qushayri) say he was a wali. Applied as an honorific only: hadith story title + first
   mention (EN/BN), Quran story first mention (EN/BN). The Quran story title "the Servant of
   Allah (al-Khidr)" was left as is to avoid nested brackets. Not changed (spelling only, out of
   scope): the hadith story spells him খিযির, the Quran story খিজির.
3. **Isra'il.** It is another name of Ya'qub, not an honorific (scholars' explanation of 3:93 and
   19:58; Yaqub's own summary already says so). Kept as the title, but labelled like the other
   "Name (meaning)" titles: "Isra'il (another name of Yaqub)" / "ইসরাইল (ইয়াকুবের আরেক নাম)".
4. **Bangla numerals: Bangla digits are the house style.** Every Bangla string in
   `assets/data/*.json` that has a digit uses Bangla digits (duas 21, tibb_nabawi 15,
   quran_stories 11, hadith_stories 5, hadith_books 2, ruqyah 3). The only ASCII digits in Bangla
   text are the verse markers "(1)", "(2)" inside one `ruqyah.json` passage translation (religious
   text, not changed; flag for review). Stories needed no change; the new stories have no digits.
   Refs chips (`Bukhari 50`) stay ASCII since they are shared across languages.

### Suspected translation errors — FIXED 2026-11-05 (owner approved, `fix/quran-31-14`; quran.db v3)

- **Quran 31:14, English (Pickthall, `quran.db`)** reads "And We have enjoined upon man
  concerning his **partners**". The Arabic is بِوَالِدَيْهِ ("his parents"), the same ayah later
  says "unto thy parents", and Sahih International has "his parents". The same "partners" text
  is on alquran.cloud, corpus.quran.com and quranpedia, so it comes from the shared Tanzil
  digital text; the 1930 print was not checked. Very likely a typo for "parents". Fixed in the
  build pipeline (`_corrections`), `bundledVersion` + `PRAGMA user_version` → 3.
- **Quran 31:14, Bangla (`quran.db`)**: "পিতা-মতার" in the second sentence looks like a typo for
  "পিতা-মাতার" (the first sentence has it right).

### Sources

- Gradings: hadithunlocked.com (tirmidhi:2639, tirmidhi:3076, abudawud:2549),
  en.tohed.com/hadith/abu-dawud/2549, surahquran.com/Hadith-120761.html (dorar.net mirror:
  al-Albani, Sahih Abi Dawud 2549; Ibn Kathir), dorar.net search results (Sahih at-Targhib 2269),
  alim.org (Ibn Majah 4300). sunnah.com and dorar.net blocked direct fetches (HTTP 403).
- al-Khidr: islamqa.info/en/answers/21793; islamqa.org (SeekersGuidance, "What do we know
  about Khidr"); dar-alifta.org fatwa 5837.
- 31:14: alquran.cloud/ayah/31:14, corpus.quran.com/translation.jsp?chapter=31&verse=14.

- 2026-11-05: al-Khidr's Bangla spelling unified to খিজির; ruqyah.json Bangla verse markers now in Bangla digits.

## Web review against scholars' views (2026-11-05, `fix/scholar-review`)

Six agents checked every summary and story against tafsir (Ibn Kathir, al-Tabari, al-Qurtubi,
al-Sa'di), hadith commentary (Fath al-Bari, Sharh Nawawi), gradings (sunnah.com, dorar.net) and
fatwa sites (islamqa, islamweb), plus the bundled DBs. This is not a scholar's sign-off.

**Fixed (26 patches):**
- Errors: Ka'b ibn Malik also missed Badr (Bukhari 4418); Bukhari 3350 ذيخ ملتطخ is a
  filth-smeared male hyena, not "a blood-stained animal" (Mishkat 5538, Ibn Kathir 6:77);
  12:9 "Kill Yusuf" is the brothers' plural speech, the single speaker is 12:10.
- Majority view marked: Ismail as the sacrificed son (`ismail_true_to_promise`), Dhul-Kifl
  (`alyasa_and_dhulkifl`), Iram as the tribe of 'Ad (Hud summary, Ibn Kathir 89:7-8), the
  Quran as his ﷺ greatest miracle is the scholars' explanation of Bukhari 4981.
- 7:143 Bangla: "কখনো" dropped (Ahl al-Sunnah: believers see Allah in the Hereafter).
- 18:21: the Quran only reports the plan to build a mosque over the cave; added that it was
  not praiseworthy (Ibn Kathir; Bukhari 1330).
- Smaller: honorific Bangla forms (Ismail, Thumamah, Abu Bakr/Umar), 34:12 future tense,
  "bribe" → payment (18:94-95), Qarun ref 28:76-83, "ধরতে পারেন" → "পাকড়াও করেন"
  (Bukhari 3481), Tamim's دير = মঠ (monastery), not গির্জা.

**Differences of opinion now written into the text (37 patches, second pass):** each point was
researched online (Ibn Kathir, al-Tabari, al-Qurtubi, al-Sa'di, al-Baghawi, Fath al-Bari,
Dalil al-Falihin, islamqa, islamweb, dorar.net); the majority/stronger view comes first, then
"Some scholars say …" / "কোনো কোনো আলেম বলেন, …".
- 12:24 hamm (passing inclination vs none) · 12:42 who forgot (Ibn Kathir: the freed man;
  al-Tabari: Yusuf) · 12:15 two readings (EN now "recognise you", matching BN) · 7:143 tajalla
  now literal "manifested Himself" (islamqa 353034), al-Baghawi's "light" view added.
- 21:87 Bangla "সংকটে ফেলবেন না" + both readings (constrict / decree); the rejected reading is
  excluded · first sin: pride, with Qatada's envy · magic: all kufr vs al-Nawawi (kufr only with
  disbelief, else a major sin) · `isa_raised_up` lesson reworded (some prophets were killed;
  40:51 = help/victory).
- Hadith: cradle speakers reconciled (Muslim 7511) · angel of death came in human form · Ka'b:
  Murarah/Hilal at Badr (Ibn Hajar vs Ibn al-Jawzi/al-Dimyati) · Sarah: EN "he sent her"
  (Arabic فأرسل بها) · Khubaib ibn 'Adi vs ibn Isaf (al-Dimyati vs Ibn Hajar) · sun held back:
  Yusha' ibn Nun (Musnad Ahmad 8315, chain sahih per al-Arna'ut) · Hittah: mockery (Ibn Kathir).
- Prophets: Lut's "powerful support" = Allah (Ibn Kathir 11:80) · Yahya سيّد "a noble leader" /
  "সম্মানিত নেতা" · 19:7 "no one named so before" vs "no one like him" (Ibn Abbas, Mujahid).

Unconfirmed in the bundled DB: Tirmidhi 3074 (7:143) rests on sunnah.com; Musnad Ahmad isn't
bundled. All of this is still a draft until a scholar signs off.
