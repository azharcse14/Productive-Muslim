# Content audit — 2026-11-02

Read-only audit of all bundled content. Nothing was changed. Follow-up to
`docs/religious_content_review.md` (2026-10-29); items decided there are not repeated.

Rules for fixing (CLAUDE.md): religious text needs the task to say so explicitly — sections
B–D are **flagged for the owner/scholar**, not auto-fix. Bundled DB change → bump
`bundledVersion` + `PRAGMA user_version` together. Log each fix in PROGRESS.md.

Legend: ✅ verified by script against source · 🔎 agent-verified with source link (re-check
before fixing) · Sev = high / med / low.

## Status — 2026-11-03

Owner approved fixing everything ("sobgulo koro"). Each change set was re-checked against the
pinned hadith-api snapshot `@df57907` and reviewed by a separate agent.
- **Done (merged to `master`):** A3, A4, A5, all of B, C and D — branches
  `fix/content-audit-app-text`, `fix/content-audit-hadith40-asma`, `fix/content-audit-duas`.
  Corrections to this audit found while fixing: B6's Aisha hadith is Muslim **1176** (not 1175);
  A3 covered 61 duas (14 passages moved from ruqyah.json on 2026-10-25 also lacked trBn).
- **PENDING:** **A1** (section-0 hadith missing from hadith.db) and **A2** (decimal hadith
  numbers). State at end of 2026-11-03: implemented and committed on branch
  `fix/content-audit-hadith-db` — `07ed1e9` (pipeline fix + rebuilt hadith.db, build test,
  integrity test) and `4728ae5` (master merged in). **Not reviewed, not merged.** The agent's
  final full test run had not reported. Next session:
  1. `flutter gen-l10n`, `flutter analyze`, `flutter test -j 2` on that branch.
  2. Independent review: section-0 hadith recovered per book (Bukhari 832 / 5692 present),
     sub-numbers (e.g. 402 vs 402.x) in "go to hadith number", search and chapter views,
     `bundledVersion` and `PRAGMA user_version` bumped together, favourites / last-read
     survive the DB upgrade, DB size.
  3. Fix findings, merge into `master`, tick A1/A2 here and log it in PROGRESS.md.
- **For a scholar to re-check:** the 61 AI-written Bangla transliterations (A3), the madhab
  wording in B1/B5, and the Asma meanings changed in C11–C15.

---

## A. Data pipeline (not religious-text edits — safe to fix)

### A1. 🔴 hadith.db is missing hadith filed under upstream "section 0" ✅
`tool/hadith_db_build.dart` fetches sections 1..N only. fawazahmed0 hadith-api
(pinned `df57907`) files some hadith under `sections/0.min.json` (exists, HTTP 200), so
they never reach the DB or the reader.

| Book | Non-empty upstream hadith absent from DB | Examples |
|---|---|---|
| Bukhari | 332 | 299, 300, 329, 395, 408, 410, 435, 454, 478, 521, 533, 536 |
| Muslim | 148 | 3, 4, 15, 1220, 1350, 1354 (internal numbering) |
| Tirmidhi | 37 | decimals |
| Nasa'i | 7 | |
| Ibn Majah | 2 | |
| Abu Dawud, Malik | 0 | |

Content that cites a now-missing hadith: `duas.json` **audhu_ma'tham_maghram** (Bukhari 832),
`tibb_nabawi.json` **tibb_qust_hindi** (Bukhari 5692).

Fix: include section 0 hadith, placed into the section whose number range holds them
(info.json `section_details`), re-run `tool/hadith_ref_index.dart`, bump
`_userVersion` + `HadithDatabase.bundledVersion` to 3, extend
`test/tool/hadith_db_integrity_test.dart` with "every non-empty upstream number is present".

### A2. Decimal hadith numbers collapse to integers ✅ (low)
Upstream 402.2 ("Narrated Anas: as above") is stored as `n: 402`, so the Bukhari reader shows
#402 twice; ~25 such collisions in Bukhari, ~22 in Tirmidhi. Keep the sub-number (e.g. store
the display ref) or label it.

### A3. Missing Bangla transliteration ✅ (low)
3 duas have empty `trBn` (sa_tasbih_alhamdulillah, sa_tasbih_allahu_akbar,
sa_tasbih_tahlil_100); 46 have no `trBn` key (waking, food, travel, salah, distress, wudu,
weather, istighfar, gratitude, sneezing, knowledge, family …). The UI falls back to the
Latin `tr`, so nothing is blank — content gap only.

### A4. Whitespace ✅ (low)
`hm_6_14_120` trBn has a double space; `hm_10_21_165` tr has double/stray spaces;
`hm_5_13_111` en has a literal newline in "good\nhealth"; `hm_5_12_83` ar has a stray
colon «اللَّيْلَةِ :فَتْحَهَا».

### A5. Same-category duplicate duas ✅ (low — owner decision)
Same Arabic twice in one category: food (fd_bismillah / bismillah_food), home
(hm_8_17_154 / bismillah_tawakkaltu), travel (tv_safar / dua_safar), marketplace
(mk_entering_market / hm_5_13_112 — and their grade notes disagree). Cross-category repeats
are intentional.

---

## B. App text / fiqh in code & ARB (owner decision)

| # | Where | Issue | Sev |
|---|---|---|---|
| B1 | `app_en.arb:226` / `app_bn.arb:127` `forbiddenTimesSubtitle` | Says a missed fard "may still be prayed" in forbidden times; the corrected intro (en:230) says not valid in Hanafi. Contradiction. ✅ | med |
| B2 | `lib/core/utils/islamic_dates.dart:62-63` israMiraj, nisfShaban | Night observances marked on the hijri day; Shab-e-Barat begins at sunset of 14 Sha'ban. laylatulQadr already shifted (26 Ramadan) for this reason. ✅ | med |
| B3 | `app_bn.arb:521` islamicDayName.mawlid | EN "Mawlid", BN "ঈদে মিলাদুন্নবী" (calls it an Eid) — meaning differs, contentious. Isra-Mi'raj / Shab-e-Barat shown with no "date/observance disputed" note. 🔎 | med |
| B4 | `app_en.arb:967` / bn:521 laylatulQadr | "Night of the 27th" stated as fact; conflicts with `laylatulQadrOddNights` (en:905). 🔎 | low |
| B5 | `app_en.arb:920` zakatNeedSilverPrice; `zakat_calculator.dart:107` | Silver nisab for cash presented as the only rule; it's the Hanafi view. Label as madhab choice like the fitra calculator. 🔎 | low |
| B6 | `app_en.arb:733` fastingKindNote.dhulHijjah | "More beloved" wording is Abu Dawud 2438 / Tirmidhi 757, not Bukhari 969; hadith is about deeds generally (Muslim 1175: Aisha never saw him fast the ten). 🔎 | low |
| B7 | `app_en.arb:233` specialDetailIshraq | Hajj+Umrah reward stated without grade (Tirmidhi 586: Hasan per al-Albani, weak per others). 🔎 | low |
| B8 | `prayer_detail_sheet.dart:12-21` | Rakaat table is Hanafi (Dhuhr sunnah 6, Witr 3, Jumu'ah 4+4) without saying so. 🔎 | low |
| B9 | Hijri month names | Missing apostrophes ("Shaban", "Dhul-Qadah"). 🔎 | low |

---

## C. hadith.json & asmaul_husna.json (scholar)

| # | id | Field | Issue | Sev |
|---|---|---|---|---|
| C1 | h021 | ar/ref | Bukhari 69 (Anas) reads «يَسِّرُوا وَلَا تُعَسِّرُوا، وَبَشِّرُوا وَلَا تُنَفِّرُوا»; app has the halves swapped (that order is Muslim 1732, Abu Musa). Re-order or change ref+narrator. ✅ | med |
| C2 | h020 | ar/bn | Bukhari 450 has no «لله» («من بنى مسجدا… يبتغي به وجه الله»); app wording looks like Muslim 533. bn «ঘর» for «مثله». 🔎 | low |
| C3 | h034 | ar/en/bn | «لِلَّهِ» dropped: source «مَنْ حَجَّ لِلَّهِ فَلَمْ يَرْفُثْ». ✅ | low |
| C4 | h037 | ar | Source order «أَحَبَّ الأَعْمَالِ أَدْوَمُهَا إِلَى اللَّهِ وَإِنْ قَلَّ» (Bukhari 6464). 🔎 | low |
| C5 | h029 | en | «مَنْ كَانَ فِي حَاجَةِ أَخِيهِ» = "whoever is engaged in his brother's need", not "fulfils". bn fine. 🔎 | low |
| C6 | h030 | bn | «আত্মতৃপ্তি» for «الغنى» → «অমুখাপেক্ষিতা / সচ্ছলতা». 🔎 | low |
| C7 | h040 | bn | «غريب» = stranger/foreigner; «অপরিচিত পথিক অথবা মুসাফির» blurs the two images. 🔎 | low |
| C8 | h014 | grade | "Hasan" (Tirmidhi's own ruling) while h017 uses al-Albani; al-Albani/Shakir: Sahih. Pick one grading policy. 🔎 | low |
| C9 | asmaul_husna n67 | list | Tirmidhi 3507 has 98 names (no «الأحد»; goes الواحد الصمد). App uses the popular list — say so in credits/UI. 🔎 | med |
| C10 | asmaul_husna (source) | note | Tirmidhi 3507 is gharib, graded Da'if (al-Albani, Shakir, Zubair Ali Zai); many hold the list is a narrator's addition. Don't imply a sahih text. 🔎 | med |
| C11 | n45 الواسع | bn | «সর্বব্যাপী» implies essence everywhere — theologically off. → «অসীম প্রশস্ত / জ্ঞান ও রহমতে সর্বব্যাপী». 🔎 | med |
| C12 | n70 المقتدر | en | "All-Determining" (qadar) → "The Omnipotent". 🔎 | low |
| C13 | n64 الواجد | en/bn | "The Finder" → "The Perceiver / Self-Sufficient"; bn «অভাবমুক্ত প্রাপক» awkward. 🔎 | low |
| C14 | n90 المانع | en | "Withholder of Harm" too narrow → "The Preventer". 🔎 | low |
| C15 | n18 الفتاح | bn | «মহাবিজয়দাতা» too narrow → «উন্মোচনকারী ও ফয়সালাকারী». 🔎 | low |
| C16 | n48 / n65 | tr | Both "Al-Majid" → Al-Majeed vs Al-Maajid (identical in quiz). 🔎 | low |

---

## D. duas.json, ruqyah.json, tibb_nabawi.json (scholar)

Every Qur'anic portion in these three files matches quran.db/Tanzil ✅.

### duas.json 🔎
| id | Field | Issue | Sev |
|---|---|---|---|
| wk_la_ilaha_night | ref | "Bukhari 3/39" (=1154) wording differs (الحمد لله before سبحان الله, no العلي العظيم, ends اللهم اغفر لي). Entry text = Ibn Majah 3878. | med |
| hm_6_14_131 | en | «فَاغْفِرْ» request rendered as a statement ("You forgive"); «وَضَعْتُ جَنْبِي» = "I lay down my side". | med |
| hm_10_21_165 | tr / trBn | tr "haadhi-hid-da watit-taammah" → "haadhihid-da'watit-taammah"; trBn «মু‘হাম্মাদান আল-ওয়াসীলাতা» → «মু‘হাম্মাদানিল ওয়াসীলাতা». | med |
| hm_10_21_164, hm_5_12_88 | trBn | «আলী মু‘হাম্মাদিন» reads as the name Ali → «আ-লি». | low-med |
| hm_6_15_139 | ref | Abu Dawud 5060 lacks «العلي العظيم»; add Ibn Majah 3878. | low |
| hm_6_14_125 | ar | Extra «إِنَّكَ» vs Muslim 2712 (Hisnul Muslim prints it). | low |
| hm_5_12_110 | ar/tr | Extra «وَ» before 2nd سبحان الله (Bukhari 6682). | low |
| fd_hamdan_kathiran | ar/tr/ref | Extra «حَمْدًا» (Bukhari 5458: «الحمد لله كثيرا طيبا»); ref → Bukhari 5458. | low |
| hm_5_12_101 | ref | Tirmidhi 3529 has different order and no «أشهد»; entry merges with Tirmidhi 3392. | low |
| hm_6_14_123 | ref | Muslim 2711 wording is «اللهم باسمك أحيا وباسمك أموت»; only Bukhari 6324 fits. | low |
| hm_10_21_164 | ref | Muslim 384 is only the instruction; wording from Bukhari 3370 / Muslim 406. | low |
| hm_6_14_134 | tr | "Sharhri", "Fitanillali" (→ fitanil-layli), "Minhha". | low |
| hm_10_23_168 | tr/trBn | "wagfir lilmua-ddhinin" → "waghfir lil-mu'adhdhineen"; trBn «আল্ল-হুম্মা», stray hasant «আরশিদি্‌ল». | low |
| hm_9_19_161, hm_5_12_866 | tr | g for غ ("Gufraanak", "Gasiq"); z for ذ ("Haazal"). | low |
| hm_6_14_136 | tr | "maalja'" → "malja'". | low |
| hm_6_14_124/125/134 | trBn | «সাক্কা-নী», «খালাক্কতা», «ত্বা-রিক্কিন» → ক্ব (no doubling). | low |
| hm_6_14_122, hm_9_19_160, hm_10_23_168 | bn | তুমি/তোমার for Allah; rest of file uses আপনি. | low |

### ruqyah.json 🔎
| id | Field | Issue | Sev |
|---|---|---|---|
| adhhibil_bas | ar/en | «اشْفِ أَنْتَ الشَّافِي» matches neither Muslim 2191 («وَاشْفِ») nor Bukhari 5743 («اشْفِهِ وَأَنْتَ»). | low |
| uidhukuma_children | ref, en/bn | «أُعِيذُكُمَا» is Abu Dawud 4737 / Tirmidhi 2060, not Bukhari 3371 (which has «أَعُوذُ»). «عَيْنٍ لَامَّةٍ» = afflicting eye, not "envious". | low |
| bismika_rabbi | ar | Bukhari 6320: «بِاسْمِكَ رَبِّ … إِنْ أَمْسَكْتَ»; app «رَبِّي … فَإِنْ». | low |
| la_ilaha_wahdah | ref | Virtue limit missing: «يَوْمَهُ ذَلِكَ حَتَّى يُمْسِيَ». | low |
| sayyidul_istighfar | ref | Only daytime half of the virtue in a morning_evening item. | low |
| kalimat_tammat | category | Under evil_eye; cited hadith are about stopping places / scorpion sting. | low |
| audhu_kalimat_ghadab_sleep | category/title | Ahmad (Ibn Khanbash) is about devils at night, not sleep. | low |

### tibb_nabawi.json 🔎 (all 27 refs + Arabic verified; notes only)
| id | Issue |
|---|---|
| tibb_dont_force_sick | al-Albani: Sahih for Tirmidhi 2040 (Hasan only at Ibn Majah 3444). |
| tibb_olive_oil | Exact wording is Tirmidhi 1852 (Abu Usayd, Sahih); cite "1851, 1852". |
| tibb_black_seed | "a few seeds or a little oil daily" is custom, not prophetic — label it. |
| tibb_zamzam | Etiquette list's usual source (Ibn Majah 3061) is weak — unconfirmed. |
| tibb_fly_drink | Hadith commands dipping (فليغمسه); "permission" undersells it. |
| tibb_sick_healthy | "Flee from the leper" in Bukhari 5707 is mu'allaq — citation precision. |
| tibb_ithmid | Faithful excerpt of a longer Abu Dawud 3878 — no change. |

---

## Verified OK
- quran.db: 6236 ayahs identical to Tanzil `ara-quransimple` except one identical Bismillah
  prefix stripped from 112 surahs (not 1, 9); EN/BN 100% match; versions 2/2. ✅
- cities.json: 34,740 rows, valid tz/coords, no dups. ✅
- ARB: en/bn keys match, no "নামায". ✅
- Zakat nisab 87.48 g / 612.36 g, 2.5%, hawl; sunnah & forbidden fast days; tasbih 33/33/34. 🔎
- tibb: 20 items clean; hadith40: 26 clean; asmaul_husna: 92 meanings clean. 🔎

Source snapshots used: fawazahmed0 quran-api `@1`, hadith-api `@df57907`.
