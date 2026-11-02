import 'package:flutter/widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../config/app_config.dart';

/// App-scoped Arabic text size (design §4.5): the Quran reader's size, with
/// duas, hadith and ruqyah a step smaller. Independent of the system font
/// scale. Persistence is injected by the composition root, so this stays
/// free of storage plugins.
final class ReaderTextSize {
  ReaderTextSize({
    Future<double?> Function()? read,
    Future<void> Function(double size)? write,
  }) : _read = read,
       _write = write;

  static const defaultSize = 28.0;

  final Future<double?> Function()? _read;
  final Future<void> Function(double size)? _write;

  /// Quran reader Arabic size.
  late final size = signal(defaultSize);

  /// Arabic size for duas, hadith and ruqyah (24 at the default 28).
  late final bodySize = computed(() => size.value * 6 / 7);

  Future<void> load() async {
    size.value = _clamp(await _read?.call() ?? defaultSize);
  }

  /// [persist] false previews the size (slider drag) without a write.
  Future<void> set(double value, {bool persist = true}) async {
    final clamped = _clamp(value);
    size.value = clamped;
    if (persist) {
      await _write?.call(clamped);
    }
  }

  static double _clamp(double size) => size
      .clamp(AppConfig.quranFontSizeMin, AppConfig.quranFontSizeMax)
      .toDouble();
}

/// Provides the app's [ReaderTextSize] to every route (installed above the
/// navigator in `main.dart`).
final class ReaderTextSizeScope extends InheritedWidget {
  const ReaderTextSizeScope({
    required this.textSize,
    required super.child,
    super.key,
  });

  final ReaderTextSize textSize;

  /// Null outside the app root (isolated widget tests).
  static ReaderTextSize? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ReaderTextSizeScope>()
      ?.textSize;

  @override
  bool updateShouldNotify(ReaderTextSizeScope oldWidget) =>
      textSize != oldWidget.textSize;
}

/// Quran reader Arabic size; read inside a SignalBuilder/Watch to follow
/// changes. Defaults to [ReaderTextSize.defaultSize] without a scope.
double readerArabicSize(BuildContext context) =>
    ReaderTextSizeScope.maybeOf(context)?.size.value ??
    ReaderTextSize.defaultSize;

/// Arabic size for duas, hadith and ruqyah; read inside a
/// SignalBuilder/Watch to follow changes. Defaults to 24 without a scope.
double arabicBodySize(BuildContext context) =>
    ReaderTextSizeScope.maybeOf(context)?.bodySize.value ??
    ReaderTextSize.defaultSize * 6 / 7;
