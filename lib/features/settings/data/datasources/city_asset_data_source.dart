import 'dart:convert';

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
    final decoded = jsonDecode(raw) as List<dynamic>;
    return _cache = [
      for (final entry in decoded.cast<List<dynamic>>())
        City(
          name: entry[0] as String,
          countryCode: entry[1] as String,
          latitude: (entry[2] as num).toDouble(),
          longitude: (entry[3] as num).toDouble(),
          timezone: entry[4] as String,
        ),
    ];
  }
}
