import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../prayer_times/presentation/screens/home_formatting.dart';
import '../../../prayer_times/presentation/state/home_store.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../../../settings/presentation/widgets/setting_labels.dart';

/// Screen listing daily scheduled notifications and reminders.
/// Appbar settings icon routes to [NotificationSettingsScreen].
final class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

final class _NotificationsScreenState extends State<NotificationsScreen> {
  late final HomeStore? _homeStore =
      locator.isRegistered<HomeStore>() ? locator<HomeStore>() : null;
  late final SettingsStore _settings = locator<SettingsStore>();

  String _formatTime(BuildContext context, DateTime time) {
    return formatHomeTime(context, time);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          IconButton(
            tooltip: l10n.notifSettingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                unawaited(context.pushNamed(Routes.notificationSettings.name)),
          ),
        ],
      ),
      body: SignalBuilder(
        builder: (context) {
          final matrix = _settings.settings.value.notifications;
          final home = _homeStore;
          final day = home?.prayerDay.value;

          final items = <_NotificationViewItem>[];

          if (day != null) {
            final fajr = day.fajr;
            final dhuhr = day.dhuhr;
            final asr = day.asr;
            final maghrib = day.maghrib;
            final isha = day.isha;

            final fajrName = l10n.prayerLabel(Prayer.fajr);
            final dhuhrName = l10n.prayerLabel(Prayer.dhuhr);
            final asrName = l10n.prayerLabel(Prayer.asr);
            final maghribName = l10n.prayerLabel(Prayer.maghrib);
            final ishaName = l10n.prayerLabel(Prayer.isha);

            items.addAll([
              _NotificationViewItem(
                icon: Icons.mosque_outlined,
                title: l10n.notifAzanTitle(
                  fajrName,
                  _formatTime(context, fajr),
                ),
                subtitle: l10n.notifAzanBody(fajrName),
                time: _formatTime(context, fajr),
                route: '/home',
              ),
              _NotificationViewItem(
                icon: Icons.wb_sunny_outlined,
                title: l10n.notifAzanTitle(
                  dhuhrName,
                  _formatTime(context, dhuhr),
                ),
                subtitle: l10n.notifAzanBody(dhuhrName),
                time: _formatTime(context, dhuhr),
                route: '/home',
              ),
              _NotificationViewItem(
                icon: Icons.wb_twilight_outlined,
                title: l10n.notifAzanTitle(
                  asrName,
                  _formatTime(context, asr),
                ),
                subtitle: l10n.notifAzanBody(asrName),
                time: _formatTime(context, asr),
                route: '/home',
              ),
              _NotificationViewItem(
                icon: Icons.nightlight_round_outlined,
                title: l10n.notifAzanTitle(
                  maghribName,
                  _formatTime(context, maghrib),
                ),
                subtitle: l10n.notifAzanBody(maghribName),
                time: _formatTime(context, maghrib),
                route: '/home',
              ),
              _NotificationViewItem(
                icon: Icons.bedtime_outlined,
                title: l10n.notifAzanTitle(
                  ishaName,
                  _formatTime(context, isha),
                ),
                subtitle: l10n.notifAzanBody(ishaName),
                time: _formatTime(context, isha),
                route: '/home',
              ),
            ]);
          }

          if (matrix.dailyAyahReminder) {
            final now = DateTime.now();
            final t = DateTime(
              now.year,
              now.month,
              now.day,
              matrix.dailyAyahMinute ~/ 60,
              matrix.dailyAyahMinute % 60,
            );
            items.add(
              _NotificationViewItem(
                icon: Icons.menu_book_outlined,
                title: l10n.notifDailyAyahTitle,
                subtitle: l10n.notifDailyAyahBody,
                time: _formatTime(context, t),
                route: '/home',
              ),
            );
          }

          if (matrix.dailyHadithReminder) {
            final now = DateTime.now();
            final t = DateTime(
              now.year,
              now.month,
              now.day,
              matrix.dailyHadithMinute ~/ 60,
              matrix.dailyHadithMinute % 60,
            );
            items.add(
              _NotificationViewItem(
                icon: Icons.auto_stories_outlined,
                title: l10n.notifDailyHadithTitle,
                subtitle: l10n.notifDailyHadithBody,
                time: _formatTime(context, t),
                route: '/hadith',
              ),
            );
          }

          if (matrix.muhasabaEveningReminder) {
            final now = DateTime.now();
            final t = DateTime(now.year, now.month, now.day, 21, 30);
            items.add(
              _NotificationViewItem(
                icon: Icons.favorite_outline,
                title: l10n.notifMuhasabaTitle,
                subtitle: l10n.notifMuhasabaBody,
                time: _formatTime(context, t),
                route: '/muhasaba',
              ),
            );
          }

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(QSpace.s6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_outlined,
                      size: 64,
                      color: q.ink3,
                    ),
                    const SizedBox(height: QSpace.s4),
                    Text(
                      l10n.notificationsEmptyTitle,
                      style: QType.title,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: QSpace.s2),
                    Text(
                      l10n.notificationsEmptySub,
                      style: QType.caption.copyWith(color: q.ink2),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(QSpace.s5),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: QSpace.s3),
            itemBuilder: (context, index) {
              final item = items[index];
              return QCard(
                onTap: () => context.go(item.route),
                padding: const EdgeInsets.all(QSpace.s4),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: q.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: q.primary, size: 22),
                    ),
                    const SizedBox(width: QSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: QType.label.copyWith(
                              fontVariations: const [
                                FontVariation('wght', 600),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: QType.caption.copyWith(color: q.ink2),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: QSpace.s2),
                    Text(
                      item.time,
                      style: QType.caption.copyWith(
                        color: q.primary,
                        fontVariations: const [FontVariation('wght', 600)],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

final class _NotificationViewItem {
  const _NotificationViewItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final String route;
}
