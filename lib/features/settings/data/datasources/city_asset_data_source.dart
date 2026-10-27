import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart' show AssetBundle;

import '../../domain/entities/city.dart';

/// Loads the bundled GeoNames-derived city list
/// (built by `tool/city_db_build.dart`, ordered largest-population first).
final class CityAssetDataSource {
  CityAssetDataSource(this._bundle);

  static const assetPath = 'assets/data/cities.json';

  final AssetBundle _bundle;
  List<City>? _cache;

  Future<List<City>> loadAll() async {
    if (_cache case final cached?) {
      return cached;
    }
    final raw = await _bundle.loadString(assetPath);
    // ~1.7 MB of JSON: decode off the UI isolate so the first search
    // doesn't drop frames.
    final cities = await Isolate.run(() => _parse(raw));
    return _cache = cities;
  }

  static List<City> _parse(String raw) => [
        for (final entry
            in (jsonDecode(raw) as List<dynamic>).cast<List<dynamic>>())
          City(
            name: entry[0] as String,
            countryCode: entry[1] as String,
            latitude: (entry[2] as num).toDouble(),
            longitude: (entry[3] as num).toDouble(),
            timezone: entry[4] as String,
          ),
      ];
}
