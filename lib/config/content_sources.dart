/// Remote content sources, pinned to full commit SHAs so the online fallback
/// and `tool/hadith_db_build.dart` always read the exact revision the bundled
/// `assets/data/hadith.db` snapshot was built from — never a moving branch or
/// version range. Shared by the app and the tool. To pick up upstream
/// changes: bump the SHA, rebuild the DB, update docs/DEPENDENCIES.md.
abstract final class ContentSources {
  /// fawazahmed0/hadith-api (Unlicense) — HEAD of branch `1` (the `@1` the snapshot
  /// was built from), resolved 2026-10-29.
  static const hadithApiSha = 'df57907be35291c91ad6a6691180e22ca9920784';

  /// azharcse14/hadithbangla — HEAD of `main`, resolved 2026-10-29.
  static const hadithBanglaSha = '3de802c0bea9f0892ac47eb5903cb1498630b209';

  /// `{edition}/sections/{n}.min.json` lives under this base.
  static const hadithApiEditionsBase =
      'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@$hadithApiSha/editions';

  /// `{folder}/Chapter/{n}.json` lives under this base.
  static const hadithBanglaBase =
      'https://raw.githubusercontent.com/azharcse14/hadithbangla/$hadithBanglaSha';

  /// Cap for one downloaded section body. The largest upstream section is
  /// ~1.96 MB raw (hadithbangla Bukhari chapter 64; ~1.8 MB decompressed in
  /// hadith.db), so this is about twice that.
  static const maxSectionBytes = 4 * 1024 * 1024;
}
