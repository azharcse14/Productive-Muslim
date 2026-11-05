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
| hadith_stories.json | 11 | 50 |
| prophets.json | 25 entries, 25 summaries (review pending) | scholar review |
