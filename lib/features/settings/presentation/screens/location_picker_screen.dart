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
import '../../domain/usecases/regional_defaults.dart';
import '../../domain/usecases/search_cities.dart';
import '../state/settings_store.dart';
import '../widgets/setting_labels.dart';

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

  /// Last GPS failure, shown above the manual list (the fallback).
  final _gpsFailure = signal<Failure?>(null);

  /// The city search itself failed (vs. simply no match).
  final _searchFailed = signal(false);

  Timer? _debounce;

  /// Bumped per search; a response from an older query is dropped.
  var _searchGen = 0;

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    unawaited(_runSearch(''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _lifecycle.dispose();
    _results.dispose();
    _searching.dispose();
    _gpsBusy.dispose();
    _gpsFailure.dispose();
    _searchFailed.dispose();
    super.dispose();
  }

  /// Re-checks GPS on return from system settings, so fixing the problem
  /// there takes effect without another tap.
  void _onResume() {
    final failure = _gpsFailure.value;
    if (!_gpsBusy.value &&
        (failure is LocationServiceDisabled ||
            failure is LocationPermissionDeniedForever)) {
      unawaited(_useGps());
    }
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => unawaited(_runSearch(query)),
    );
  }

  Future<void> _runSearch(String query) async {
    final gen = ++_searchGen;
    _searching.value = true;
    final result = await _searchCities(query);
    if (gen != _searchGen || !mounted) {
      return;
    }
    _searchFailed.value = result.valueOrNull == null;
    _results.value = result.valueOrNull ?? const [];
    _searching.value = false;
  }

  Future<void> _useGps() async {
    _gpsBusy.value = true;
    _gpsFailure.value = null;
    final result = await _getLocation();
    if (!mounted) {
      return;
    }
    _gpsBusy.value = false;
    switch (result) {
      case Success<GpsLocation>(:final value):
        await _apply(value);
      case FailureResult<GpsLocation>(:final failure):
        _gpsFailure.value = failure;
    }
  }

  Future<void> _selectCity(City city) => _apply(ManualCityLocation(city));

  /// Saves [location] and closes. A later move to another country (not
  /// during first setup, whose own steps pre-select these) offers that
  /// region's method and Asr madhab.
  Future<void> _apply(LocationConfig location) async {
    final from = countryCodeOf(_store.location.value);
    await _store.setLocation(location);
    final to = countryCodeOf(location);
    if (mounted &&
        _store.settings.value.setupComplete &&
        to.isNotEmpty &&
        to != from) {
      await _offerRegionalDefaults(to);
    }
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _offerRegionalDefaults(String country) async {
    final params = _store.prayerParams.value;
    final method = suggestedMethodFor(country);
    final madhab = defaultMadhabFor(country);
    if (method == params.method &&
        asrMadhabOf(madhab) == asrMadhabOf(params.madhab)) {
      return;
    }
    final l10n = context.l10n;
    final use = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          l10n.locationRegionalTitle('${_flag(country)} $country'.trim()),
        ),
        content: Text(
          l10n.locationRegionalBody(
            l10n.methodLabel(method),
            l10n.madhabLabel(madhab),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.locationRegionalKeep),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.locationRegionalUse),
          ),
        ],
      ),
    );
    if (use ?? false) {
      await _store.setMethod(method);
      if (asrMadhabOf(madhab) != asrMadhabOf(params.madhab)) {
        await _store.setMadhab(madhab);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.locationTitle)),
      // Header scrolls with the results, so the keyboard, Bengali or large
      // text never overflow it.
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              QSpace.s5,
              QSpace.s2,
              QSpace.s5,
              QSpace.s2,
            ),
            sliver: SliverToBoxAdapter(
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
                  SignalBuilder(
                    builder: (context) {
                      final failure = _gpsFailure.value;
                      if (failure == null) {
                        return const SizedBox.shrink();
                      }
                      // Settings fixes services-off and "don't ask again";
                      // a plain denial or a missed fix just needs another try.
                      final needsSettings =
                          failure is LocationServiceDisabled ||
                          failure is LocationPermissionDeniedForever;
                      return Padding(
                        padding: const EdgeInsets.only(top: QSpace.s3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            QBanner(
                              text: switch (failure) {
                                LocationServiceDisabled() =>
                                  l10n.locationServiceOff,
                                LocationPermissionDeniedForever() =>
                                  l10n.locationDeniedForever,
                                LocationPermissionDenied() =>
                                  l10n.locationDeniedFallback,
                                _ => l10n.locationUnavailable,
                              },
                              icon: Icons.explore_outlined,
                            ),
                            TextButton(
                              onPressed: needsSettings
                                  ? () => unawaited(
                                      _getLocation.openSettings(
                                        locationService:
                                            failure is LocationServiceDisabled,
                                      ),
                                    )
                                  : () => unawaited(_useGps()),
                              child: Text(
                                needsSettings
                                    ? l10n.openSystemSettings
                                    : l10n.locationRetry,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: QSpace.s5),
                  TextField(
                    onChanged: _onQueryChanged,
                    decoration: InputDecoration(
                      hintText: l10n.locationSearchHint,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SignalBuilder(
            builder: (context) {
              if (_searching.value) {
                return SliverPadding(
                  padding: const EdgeInsets.all(QSpace.s5),
                  sliver: SliverList.list(
                    children: [
                      for (var i = 0; i < 8; i++) ...[
                        const QSkeleton(height: 44, radius: QRadius.sm),
                        const SizedBox(height: QSpace.s2),
                      ],
                    ],
                  ),
                );
              }
              final cities = _results.value;
              if (cities.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      _searchFailed.value
                          ? l10n.locationSearchError
                          : l10n.searchNoResults,
                      style: QType.body.copyWith(color: q.ink2),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: QSpace.s5),
                sliver: SliverList.builder(
                  itemCount: cities.length,
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    // Flag + country code reads better than a raw IANA zone.
                    return QListRow(
                      title: city.name,
                      subtitle: [
                        '${_flag(city.countryCode)} ${city.countryCode}',
                        ?city.nameBn,
                      ].join(' · '),
                      onTap: () => unawaited(_selectCity(city)),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Regional-indicator flag emoji for an ISO 3166-1 alpha-2 code.
String _flag(String countryCode) {
  if (countryCode.length != 2) {
    return '';
  }
  return String.fromCharCodes(
    countryCode.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 0x41),
  );
}
