import 'package:shared_preferences/shared_preferences.dart';

/// Persists the "Eid announced — Ramadan ended after 29 days" choice, one
/// key per Hijri year (`ramadan_ended_29_<year>`, present = set).
final class EidAnnouncementLocalDataSource {
  EidAnnouncementLocalDataSource(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _prefix = 'ramadan_ended_29_';

  /// Hijri years whose Ramadan was marked as ending after 29 days.
  Future<Set<int>> load() async {
    final keys = await _prefs.getKeys();
    return {
      for (final key in keys)
        if (key.startsWith(_prefix))
          ?int.tryParse(key.substring(_prefix.length)),
    };
  }

  Future<void> save(int hijriYear, {required bool ended}) => ended
      ? _prefs.setBool('$_prefix$hijriYear', true)
      : _prefs.remove('$_prefix$hijriYear');
}
