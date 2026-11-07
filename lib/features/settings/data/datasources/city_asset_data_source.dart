import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart' show AssetBundle;

import '../../domain/entities/city.dart';

/// Loads the bundled city list — GeoNames (ordered largest-population
/// first) then OSM Bangladesh places, both built by `tool/city_db_build.dart`.
final class CityAssetDataSource {
  CityAssetDataSource(this._bundle);

  static const assetPath = 'assets/data/cities.json';

  /// OSM (ODbL) rows live apart from the GeoNames (CC BY) ones.
  static const osmAssetPath = 'assets/data/places_bd_osm.json';

  final AssetBundle _bundle;

  /// Shared in-flight load, so searches during the first load don't each
  /// decode the asset; cleared on failure so a later call can retry.
  Future<List<City>>? _cache;

  Future<List<City>> loadAll() async {
    try {
      return await (_cache ??= _load());
    } on Object {
      _cache = null;
      rethrow;
    }
  }

  Future<List<City>> _load() async {
    final raw = [
      await _bundle.loadString(assetPath),
      await _bundle.loadString(osmAssetPath),
    ];
    // ~1.9 MB of JSON: decode off the UI isolate so the first search
    // doesn't drop frames.
    return Isolate.run(() => [for (final r in raw) ..._parse(r)]);
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
        nameBn: entry.length > 5 ? entry[5] as String : null,
      ),
  ];
}
