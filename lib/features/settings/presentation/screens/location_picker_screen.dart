import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_banner.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_list_row.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/location_config.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/search_cities.dart';
import '../state/settings_store.dart';

/// Two location paths side by side (design §4.2): GPS with priming text,
/// and a searchable manual city list. Every GPS failure routes to the
/// manual path — never a dead end.
final class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

final class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final SettingsStore _store = locator<SettingsStore>();
  final GetCurrentLocation _getLocation = locator<GetCurrentLocation>();
  final SearchCities _searchCities = locator<SearchCities>();

  final _results = signal(const <City>[]);
  final _searching = signal(false);
  final _gpsBusy = signal(false);

  /// Localized failure text shown above the manual list (the fallback).
  final _gpsNotice = signal<String?>(null);

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    unawaited(_runSearch(''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => unawaited(_runSearch(query)),
    );
  }

  Future<void> _runSearch(String query) async {
    _searching.value = true;
    final result = await _searchCities(query);
    _results.value = result.valueOrNull ?? const [];
    _searching.value = false;
  }

  Future<void> _useGps() async {
    final l10n = context.l10n;
    _gpsBusy.value = true;
    _gpsNotice.value = null;
    final result = await _getLocation();
    _gpsBusy.value = false;
    switch (result) {
      case Success<GpsLocation>(:final value):
        await _store.setLocation(value);
        if (mounted) {
          context.pop();
        }
      case FailureResult<GpsLocation>(:final failure):
        _gpsNotice.value = switch (failure) {
          LocationServiceDisabled() => l10n.locationServiceOff,
          _ => l10n.locationDeniedFallback,
        };
    }
  }

  Future<void> _selectCity(City city) async {
    await _store.setLocation(ManualCityLocation(city));
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.locationTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              QSpace.s5,
              QSpace.s2,
              QSpace.s5,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SignalBuilder(
                  builder: (context) => QCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: QSpace.s4,
                      vertical: QSpace.s2,
                    ),
                    child: QListRow(
                      icon: Icons.my_location_outlined,
                      title: l10n.locationUseGps,
                      subtitle: l10n.locationUseGpsSub,
                      trailing: _gpsBusy.value
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          : Icon(Icons.chevron_right, color: q.ink3),
                      onTap: _gpsBusy.value
                          ? null
                          : () => unawaited(_useGps()),
                    ),
                  ),
                ),
                const SizedBox(height: QSpace.s3),
                Text(
                  l10n.locationPrimingBody,
                  style: QType.caption.copyWith(color: q.ink2),
                ),
                SignalBuilder(builder: (context) {
                  final notice = _gpsNotice.value;
                  if (notice == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: QSpace.s3),
                    child: QBanner(
                      text: notice,
                      icon: Icons.explore_outlined,
                    ),
                  );
                }),
                const SizedBox(height: QSpace.s5),
                TextField(
                  onChanged: _onQueryChanged,
                  decoration: InputDecoration(
                    hintText: l10n.locationSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: q.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(QRadius.md),
                      borderSide: BorderSide(color: q.line, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(QRadius.md),
                      borderSide: BorderSide(color: q.line, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(QRadius.md),
                      borderSide: BorderSide(color: q.primary, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: QSpace.s2),
          Expanded(
            child: SignalBuilder(builder: (context) {
              if (_searching.value) {
                return ListView(
                  padding: const EdgeInsets.all(QSpace.s5),
                  children: [
                    for (var i = 0; i < 8; i++) ...[
                      const QSkeleton(height: 44, radius: QRadius.sm),
                      const SizedBox(height: QSpace.s2),
                    ],
                  ],
                );
              }
              final cities = _results.value;
              if (cities.isEmpty) {
                return Center(
                  child: Text(
                    l10n.searchNoResults,
                    style: QType.body.copyWith(color: q.ink2),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: QSpace.s5),
                itemCount: cities.length,
                itemBuilder: (context, index) {
                  final city = cities[index];
                  return QListRow(
                    title: city.name,
                    subtitle: city.countryCode,
                    trailing: Text(
                      city.timezone,
                      style: QType.caption.copyWith(color: q.ink3),
                    ),
                    onTap: () => unawaited(_selectCity(city)),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
