import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../daily_content/domain/usecases/pick_daily_content.dart';
import '../../../prayer_times/presentation/screens/home_formatting.dart';
import '../../../settings/domain/entities/notification_matrix.dart';
import '../../../settings/domain/repositories/zoned_clock.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../../../settings/presentation/widgets/setting_labels.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_scheduler.dart';
import '../state/notification_controller.dart';

/// The next 24 hours of the plan the OS actually holds (from
/// [NotificationController.plan]), so the inbox can never disagree with
/// what gets delivered. Appbar settings icon routes to the settings.
final class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

final class _NotificationsScreenState extends State<NotificationsScreen> {
  final SettingsStore _settings = locator<SettingsStore>();
  final NotificationController _controller = locator<NotificationController>();
  final NotificationScheduler _scheduler = locator<NotificationScheduler>();

  final _permission = signal<NotificationPermission?>(null);
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from system settings, where notifications may have been enabled.
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(_refreshPermission()),
    );
    unawaited(_refreshPermission());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refreshPermission() async {
    final status = await _scheduler.permissionStatus();
    if (mounted) {
      _permission.value = status;
    }
  }

  /// OS prompt first; system settings once the OS won't prompt again.
  Future<void> _enable() async {
    final wasDenied = _permission.value == NotificationPermission.denied;
    final result = await _scheduler.requestPermission();
    _permission.value = result;
    if (wasDenied && result == NotificationPermission.denied) {
      await _scheduler.openSystemSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
          final location = _settings.location.value;
          final permission = _permission.value;
          if (location == null) {
            return _Empty(
              sub: l10n.notificationsNoLocationSub,
              action: l10n.homeSetLocationCta,
              icon: Icons.location_on_outlined,
              onAction: () =>
                  unawaited(context.pushNamed(Routes.locationPicker.name)),
            );
          }
          if (permission != null &&
              permission != NotificationPermission.granted) {
            return _Empty(
              sub: l10n.notificationsOffSub,
              action: l10n.notifEnableCta,
              icon: Icons.notifications_active_outlined,
              onAction: () => unawaited(_enable()),
            );
          }
          final matrix = _settings.settings.value.notifications;
          final now = locator<ZonedClock>().nowAt(location);
          final until = now.add(const Duration(hours: 24));
          final items = [
            for (final item in _controller.plan.value)
              if (item.kind != NotificationKind.keepAlive &&
                  item.at.isAfter(now) &&
                  !item.at.isAfter(until))
                item,
          ];
          if (items.isEmpty) {
            return _Empty(
              sub: l10n.notificationsEmptySub,
              action: l10n.notifSettingsTitle,
              icon: Icons.tune,
              onAction: () => unawaited(
                context.pushNamed(Routes.notificationSettings.name),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(QSpace.s5),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: QSpace.s3),
            itemBuilder: (context, index) =>
                _Tile(item: items[index], matrix: matrix),
          );
        },
      ),
    );
  }
}

/// Tab roots are switched to (`go`); anything else is pushed so back
/// returns to the inbox.
const _tabRoots = {'/home', '/quran', '/muhasaba', '/dua', '/more'};

final class _Tile extends StatelessWidget {
  const _Tile({required this.item, required this.matrix});

  final NotificationItem item;
  final NotificationMatrix matrix;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    String time(DateTime at) => formatHomeTime(context, at);
    final prayer = item.prayer == null ? '' : l10n.prayerLabel(item.prayer!);
    final dua = matrix.dailyReminderKind == DailyContentKind.dua;
    // (icon, title, body, route) — routes mirror the notification payloads.
    final (icon, title, body, route) = switch (item.kind) {
      NotificationKind.azan => (
        item.silent ? Icons.notifications_off_outlined : Icons.mosque_outlined,
        l10n.notifAzanTitle(prayer, time(item.at)),
        l10n.notifAzanBody(prayer),
        // Muhasaba is where the prayer gets marked as prayed.
        Routes.muhasaba.path,
      ),
      NotificationKind.jamaat => (
        Icons.groups_outlined,
        l10n.notifJamaatTitle(prayer),
        l10n.notifJamaatBody(time(item.eventAt ?? item.at)),
        Routes.myMosque.path,
      ),
      NotificationKind.sahriWarning => (
        Icons.nightlight_outlined,
        l10n.notifSahriTitle,
        l10n.notifSahriBody(time(item.eventAt ?? item.at)),
        Routes.ramadan.path,
      ),
      NotificationKind.iftar => (
        Icons.wb_twilight_outlined,
        l10n.notifIftarTitle,
        l10n.notifIftarBody(time(item.at)),
        Routes.ramadan.path,
      ),
      NotificationKind.muhasabaEvening => (
        Icons.favorite_outline,
        l10n.notifMuhasabaTitle,
        l10n.notifMuhasabaBody,
        Routes.muhasaba.path,
      ),
      NotificationKind.dailyReminder => (
        Icons.today_outlined,
        dua ? l10n.notifDailyDuaTitle : l10n.notifDailyHadithTitle,
        dua ? l10n.notifDailyDuaBody : l10n.notifDailyHadithBody,
        dua ? Routes.dua.path : Routes.hadith.path,
      ),
      NotificationKind.dailyAyah => (
        Icons.menu_book_outlined,
        l10n.notifDailyAyahTitle,
        l10n.notifDailyAyahBody,
        Routes.home.path,
      ),
      NotificationKind.dailyHadith => (
        Icons.auto_stories_outlined,
        l10n.notifDailyHadithTitle,
        l10n.notifDailyHadithBody,
        Routes.hadith.path,
      ),
      NotificationKind.jamaatFocus => (
        Icons.do_not_disturb_on_outlined,
        l10n.notifFocusTitle(prayer),
        l10n.notifFocusBody,
        Routes.myMosque.path,
      ),
      NotificationKind.focusEnd => (
        Icons.check_circle_outline,
        l10n.notifFocusEndTitle(prayer),
        l10n.notifFocusEndBody,
        Routes.muhasaba.path,
      ),
      NotificationKind.keepAlive => (
        Icons.refresh,
        l10n.notifKeepAliveTitle,
        l10n.notifKeepAliveBody,
        Routes.home.path,
      ),
    };
    return QCard(
      onTap: () => _tabRoots.contains(route)
          ? context.go(route)
          : unawaited(context.push(route)),
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
            child: Icon(icon, color: q.primary, size: 22),
          ),
          const SizedBox(width: QSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: QType.label.copyWith(
                    fontVariations: const [FontVariation('wght', 600)],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: QType.caption.copyWith(color: q.ink2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: QSpace.s2),
          Text(
            time(item.at),
            style: QType.caption.copyWith(
              color: q.primary,
              fontVariations: const [FontVariation('wght', 600)],
            ),
          ),
        ],
      ),
    );
  }
}

final class _Empty extends StatelessWidget {
  const _Empty({
    required this.sub,
    required this.action,
    required this.icon,
    required this.onAction,
  });

  final String sub;
  final String action;
  final IconData icon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(QSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_outlined, size: 64, color: q.ink3),
            const SizedBox(height: QSpace.s4),
            Text(
              context.l10n.notificationsEmptyTitle,
              style: QType.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: QSpace.s2),
            Text(
              sub,
              style: QType.caption.copyWith(color: q.ink2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: QSpace.s5),
            QButton(
              label: action,
              kind: QButtonKind.tonal,
              icon: icon,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }
}
