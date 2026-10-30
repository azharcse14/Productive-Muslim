import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The JSON object stored at [key], or null when nothing is stored.
///
/// A payload that isn't a JSON object (truncated, wrong shape) is copied
/// verbatim to [unreadableKey] and read as null: retrying can't make it
/// parse, and the next save to [key] then can't destroy the original.
Future<Map<String, Object?>?> readJsonObject(
  SharedPreferencesAsync prefs,
  String key, {
  required String unreadableKey,
}) async {
  final raw = await prefs.getString(key);
  if (raw == null) {
    return null;
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return decoded.cast<String, Object?>();
    }
  } on FormatException {
    // fall through to quarantine
  }
  await prefs.setString(unreadableKey, raw);
  return null;
}
