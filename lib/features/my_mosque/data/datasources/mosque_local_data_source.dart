import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/storage/json_prefs.dart';
import '../../domain/entities/mosque_state.dart';
import '../models/mosque_state_model.dart';

/// shared_preferences-backed storage. One JSON blob keeps the mosque
/// profiles atomic — partial writes can't tear the state.
final class MosqueLocalDataSource {
  const MosqueLocalDataSource(this._prefs);

  static const _key = 'mosque_state_v1';

  /// Last blob that failed to parse, kept verbatim so the next save (which
  /// overwrites [_key]) can't destroy the user's mosques.
  static const unreadableKey = 'mosque_state_v1_unreadable';

  final SharedPreferencesAsync _prefs;

  Future<MosqueState> read() async {
    final map = await readJsonObject(
      _prefs,
      _key,
      unreadableKey: unreadableKey,
    );
    return map == null ? const MosqueState() : MosqueStateModel.fromMap(map);
  }

  Future<void> write(MosqueState state) =>
      _prefs.setString(_key, jsonEncode(MosqueStateModel.toMap(state)));
}
