import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/mosque_state.dart';
import '../models/mosque_state_model.dart';

/// shared_preferences-backed storage. One JSON blob keeps the mosque
/// profiles atomic — partial writes can't tear the state.
final class MosqueLocalDataSource {
  const MosqueLocalDataSource(this._prefs);

  static const _key = 'mosque_state_v1';

  final SharedPreferencesAsync _prefs;

  Future<MosqueState> read() async {
    final raw = await _prefs.getString(_key);
    if (raw == null) {
      return const MosqueState();
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return const MosqueState();
    }
    return MosqueStateModel.fromMap(decoded.cast<String, Object?>());
  }

  Future<void> write(MosqueState state) =>
      _prefs.setString(_key, jsonEncode(MosqueStateModel.toMap(state)));
}
