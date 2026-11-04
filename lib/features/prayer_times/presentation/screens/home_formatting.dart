import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/settings/setting_labels.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/countdown_card.dart';
import '../../../settings/domain/entities/location_config.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../domain/entities/countdown_target.dart';
import '../../domain/entities/prayer_day.dart';
import '../state/home_store.dart';

// Pure presentation helpers for the Home screen (labels, formatting,
// state mapping), kept apart so the screen file is layout only.

/// Streak lengths worth a small on-card celebration (design §4.7 nudge).
bool isStreakMilestone(int streak) =>
    streak == 7 ||
    streak == 30 ||
    streak == 100 ||
    streak == 365 ||
    (streak > 0 && streak % 100 == 0);

String formatHomeTime(BuildContext context, DateTime time) =>
    context.clockTime(time);

String formatCountdown(BuildContext context, Duration d) {
  String two(int v) => v.toString().padLeft(2, '0');
  final text =
      '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  return LocaleDigits.localize(
    text,
    Localizations.localeOf(context).languageCode,
  );
}

(String eyebrow, String sub) countdownLabels(
  AppLocalizations l10n,
  BuildContext context,
  CountdownTarget target, {
  bool jumuah = false,
}) {
  final prayerName = l10n.prayerLabelOn(
    target.prayer,
    target.at,
    jumuah: jumuah,
  );
  final timeText = formatHomeTime(context, target.at);
  return switch (target.kind) {
    CountdownKind.waqtStart => (
      l10n.countdownStartsIn(prayerName),
      l10n.subAt(prayerName, timeText),
    ),
    CountdownKind.jamaat => (
      l10n.countdownJamaatIn,
      l10n.subAt(l10n.jamaatLabel, timeText),
    ),
    CountdownKind.waqtEnd => (
      l10n.countdownEndsIn(prayerName),
      l10n.subEndsAt(timeText),
    ),
    CountdownKind.sahriEnd => (
      l10n.countdownSahriEnds,
      // The sahri-end time sits before Fajr by the safety margin.
      l10n.subAt(l10n.sahriEndsLabel, timeText),
    ),
    CountdownKind.iftar => (
      l10n.countdownIftarIn,
      l10n.subAt(l10n.iftarLabel, timeText),
    ),
  };
}

/// A countdown for screen readers: "1 hour 24 minutes", not "01:24:36".
String spokenDuration(AppLocalizations l10n, Duration d) {
  final minutes = l10n.a11yMinutes(d.inMinutes % 60);
  return d.inHours > 0 ? '${l10n.a11yHours(d.inHours)} $minutes' : minutes;
}

/// Time-of-day greeting shown in the header, from the memoized [DayPart].
String greetingFor(AppLocalizations l10n, DayPart part) => switch (part) {
  DayPart.morning => l10n.greetingMorning,
  DayPart.afternoon => l10n.greetingAfternoon,
  DayPart.evening => l10n.greetingEvening,
  DayPart.night => l10n.greetingNight,
};

/// Maps the current moment within the day's sun events to a [SkyPhase] so the
/// calm hero card carries a subtle, on-brand time-of-day tint.
SkyPhase skyPhaseFor(DateTime now, PrayerDay day) {
  if (now.isBefore(day.sunrise)) {
    return SkyPhase.dawn;
  }
  if (now.isBefore(day.startOf(Prayer.dhuhr))) {
    return SkyPhase.morning;
  }
  if (now.isBefore(day.startOf(Prayer.asr))) {
    return SkyPhase.day;
  }
  if (now.isBefore(day.maghrib)) {
    return SkyPhase.evening;
  }
  return SkyPhase.night;
}

CountdownState countdownCardState(CountdownUrgency urgency) =>
    switch (urgency) {
      CountdownUrgency.calm => CountdownState.calm,
      CountdownUrgency.amber => CountdownState.amber,
      CountdownUrgency.urgent => CountdownState.urgent,
      CountdownUrgency.sahri => CountdownState.sahri,
      CountdownUrgency.iftar => CountdownState.iftar,
    };

/// Home's location name: [locationLabel], except a missing location reads
/// "Current location" (Home shows that while the first GPS fix resolves).
String formatLocationName(LocationConfig? location, AppLocalizations l10n) =>
    location == null ? l10n.locationCurrent : locationLabel(location, l10n);
