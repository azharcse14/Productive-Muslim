import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/hadith/data/hadith_asset_data_source.dart';
import 'package:productive_muslim/features/hadith/data/hadith_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('favorite ids round-trip through prefs', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    HadithRepositoryImpl repo() => HadithRepositoryImpl(
      HadithAssetDataSource(rootBundle),
      SharedPreferencesAsync(),
    );

    expect((await repo().favoriteIds()).valueOrNull, isEmpty);
    expect((await repo().setFavoriteIds({'h1', 'h2'})).isSuccess, isTrue);
    expect((await repo().favoriteIds()).valueOrNull, {'h1', 'h2'});
  });
}
