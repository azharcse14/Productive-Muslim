import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/settings/data/datasources/city_asset_data_source.dart';
import 'package:productive_muslim/features/settings/data/repositories/city_repository_impl.dart';

final class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.payload);

  final String payload;

  @override
  Future<ByteData> load(String key) async {
    final bytes = utf8.encode(payload);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

// Population-descending order, as produced by tool/city_db_build.dart.
const _sample = [
  ['Dhaka', 'BD', 23.7104, 90.4074, 'Asia/Dhaka'],
  ['São Paulo', 'BR', -23.5475, -46.6361, 'America/Sao_Paulo'],
  ['London', 'GB', 51.5085, -0.1257, 'Europe/London'],
  ['Mecca', 'SA', 21.4267, 39.8261, 'Asia/Riyadh'],
  ['New London', 'US', 41.3556, -72.0995, 'America/New_York'],
  ['Bāndarban', 'BD', 22.1953, 92.2184, 'Asia/Dhaka'],
];

CityRepositoryImpl _repo() => CityRepositoryImpl(
      CityAssetDataSource(_FakeBundle(jsonEncode(_sample))),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CityRepositoryImpl.search', () {
    test('empty query returns the largest cities in order', () async {
      final result = await _repo().search('', limit: 3);
      final names = result.valueOrNull!.map((c) => c.name).toList();
      expect(names, ['Dhaka', 'São Paulo', 'London']);
    });

    test('prefix matches rank before substring matches', () async {
      final result = await _repo().search('london');
      final names = result.valueOrNull!.map((c) => c.name).toList();
      expect(names, ['London', 'New London']);
    });

    test('search is diacritic-insensitive', () async {
      final result = await _repo().search('sao');
      expect(result.valueOrNull!.single.name, 'São Paulo');
    });

    test('search folds macrons used in GeoNames BD names', () async {
      final result = await _repo().search('bandarban');
      expect(result.valueOrNull!.single.name, 'Bāndarban');
    });

    test('search is case-insensitive', () async {
      final result = await _repo().search('MECCA');
      expect(result.valueOrNull!.single.name, 'Mecca');
    });

    test('no match returns an empty list (not a failure)', () async {
      final result = await _repo().search('atlantis');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('city carries its IANA timezone', () async {
      final result = await _repo().search('dhaka');
      expect(result.valueOrNull!.single.timezone, 'Asia/Dhaka');
    });

    test('respects the limit', () async {
      final result = await _repo().search('', limit: 2);
      expect(result.valueOrNull!.length, 2);
    });
  });
}
