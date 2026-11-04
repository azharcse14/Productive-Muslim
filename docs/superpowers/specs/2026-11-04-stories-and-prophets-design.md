# Stories (Hadith + Quran) and Prophets Tree — Design

Date: 2026-11-04 · Status: approved by owner (approach A)

## Scope

Two new features, one branch each:

| Feature | Folder | Branch |
|---|---|---|
| Hadith stories + Quran stories (হাদিসের গল্প, কুরআনের গল্প) | `lib/features/stories/` | `feat/stories` |
| Prophets timeline-tree, Adam (AS) to Muhammad ﷺ (নবী-রাসূল) | `lib/features/prophets/` | `feat/prophets-tree` |

Both are offline, bundled-JSON features that follow the existing `tibb_nabawi.json` →
asset data source → list/detail screen pattern. No new packages.

## Content policy

- Every entry is bilingual (`…En` + `…Bn`). Bangla spells নামাজ.
- Every story and every prophet summary carries `refs` (Quran `surah:ayah[-ayah]` or
  hadith `Book number`). An entry without refs fails the test suite.
- Drafted in-repo by Claude. Each asset gets a `docs/DEPENDENCIES.md` row with status
  `UNVERIFIED — scholar review pending`, and a line in Settings → Credits. Release needs a
  scholar's review first.
- Coverage (owner, 2026-11-04): **every** story the Quran narrates and the well-known
  narrative hadith (Bukhari/Muslim first, then the other bundled books), and a full
  summary for **all** 25 prophets named in the Quran. Every ref is checked against the
  bundled `quran.db` / `hadith.db` before it ships.

## Data

`assets/data/quran_stories.json`, `assets/data/hadith_stories.json`:

```json
[{"id": "yusuf", "titleEn": "…", "titleBn": "…",
  "bodyEn": ["paragraph", "…"], "bodyBn": ["paragraph", "…"],
  "refs": ["Quran 12:4-101"]}]
```

`assets/data/prophets.json`:

```json
[{"id": "ibrahim", "order": 6,
  "nameAr": "إبراهيم", "nameEn": "Ibrahim", "nameBn": "ইব্রাহিম",
  "parent": "nuh",
  "summaryEn": ["…"], "summaryBn": ["…"],
  "quranMentions": ["2:124", "14:35-41"],
  "storyId": "ibrahim_idols"}]
```

- `parent`: set only for a lineage that is sahih/well-known (e.g. Ibrahim → Ismail,
  Ibrahim → Ishaq → Yaqub → Yusuf, Dawud → Sulaiman, Zakariya → Yahya). Disputed links
  are `null`; such prophets are placed by `order` alone. Muhammad ﷺ's parent is Ismail
  (descent via many generations; drawn as a dashed line).
- `storyId`: optional id of a Quran story; `summaryEn`/`summaryBn` may be empty arrays.

## Architecture

```
features/stories/
  domain/entities/story.dart            Story {id, title(en/bn), body(en/bn), refs}, StoryKind {quran, hadith}
  domain/repositories/story_repository.dart   Future<Result<List<Story>>> stories(StoryKind)
  data/story_asset_data_source.dart     rootBundle + fromMap
  data/story_repository_impl.dart
  presentation/state/stories_store.dart
  presentation/screens/stories_screen.dart      two tabs: Quran | Hadith
  presentation/screens/story_screen.dart        title, paragraphs, refs
features/prophets/
  domain/entities/prophet.dart
  domain/repositories/prophet_repository.dart
  data/prophet_asset_data_source.dart, prophet_repository_impl.dart
  presentation/state/prophets_store.dart
  presentation/screens/prophets_screen.dart     timeline tree
  presentation/screens/prophet_screen.dart      detail
  presentation/widgets/lineage_painter.dart     CustomPainter connectors
```

- Prophet detail links to a story by route (`Routes.story` with `kind=quran&id=…`). It
  does not import `features/stories/`, so the architecture test needs no change.
- Locale picks En/Bn fields; layouts use directional insets.
- DI: data sources and repos `lazySingleton`, stores `factory`, in `core/di/locator.dart`.
- Routes: `Routes.stories`, `Routes.story`, `Routes.prophets`, `Routes.prophet` under the
  top-level routes; two tiles on the More screen.
- Load failures show the existing error/empty widgets; there are no silent catches.

## Tree UI

A vertical list sorted by `order`. Each row has an indent column. A prophet whose
`parent` is the previous row stays in line; a branch (Ismail and Ishaq from Ibrahim)
indents one level, and `LineagePainter` draws the connector. Prophets with a `null`
parent get a plain timeline dot, without a connector. Tapping a row opens the detail
screen.

## Tests

- Unit: JSON parse; every entry has non-empty `refs`/`quranMentions`; ids unique;
  every `parent` and `storyId` resolves; `order` is 1..25 with no gaps.
- Unit: the tree layout function (order + parent → indent level / connectors) is pure
  Dart in `domain/` and tested.
- Widget: stories list → detail; prophets list → detail, including the
  empty-summary state.
- `test/docs/content_ledger_test.dart` passes with the new ledger rows.

## Out of scope

Search, bookmarks, audio, images, a full family tree with intermediate ancestors.
