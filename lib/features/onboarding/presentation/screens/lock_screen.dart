import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/painters/qalb_mark.dart';
import '../../../../shared/widgets/q_button.dart';
import '../state/app_lock_store.dart';

/// PIN (+ optional biometric) gate. Also reused as the PIN setup screen
/// via [LockScreenMode].
enum LockScreenMode { unlock, setup }

final class LockScreen extends StatefulWidget {
  const LockScreen({this.mode = LockScreenMode.unlock, super.key});

  final LockScreenMode mode;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

final class _LockScreenState extends State<LockScreen> {
  late final AppLockStore _store = locator<AppLockStore>();

  String _entered = '';
  String? _firstPin;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.mode == LockScreenMode.unlock) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_store.unlockWithBiometric(context.l10n.appLockEnterPin));
        }
      });
    }
  }

  Future<void> _onDigit(String digit) async {
    if (_entered.length >= 4) {
      return;
    }
    setState(() {
      _entered += digit;
      _error = null;
    });
    if (_entered.length < 4) {
      return;
    }
    final l10n = context.l10n;
    switch (widget.mode) {
      case LockScreenMode.unlock:
        final ok = await _store.unlockWithPin(_entered);
        if (!ok && mounted) {
          setState(() {
            _entered = '';
            _error = l10n.appLockWrongPin;
          });
        }
      case LockScreenMode.setup:
        if (_firstPin == null) {
          setState(() {
            _firstPin = _entered;
            _entered = '';
          });
        } else if (_firstPin == _entered) {
          await _store.enable(_entered, biometric: true);
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        } else {
          setState(() {
            _firstPin = null;
            _entered = '';
            _error = l10n.appLockPinMismatch;
          });
        }
    }
  }

  void _onBackspace() {
    if (_entered.isNotEmpty) {
      setState(() => _entered = _entered.substring(0, _entered.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final title = switch ((widget.mode, _firstPin)) {
      (LockScreenMode.unlock, _) => l10n.appLockEnterPin,
      (LockScreenMode.setup, null) => l10n.appLockSetPin,
      (LockScreenMode.setup, _) => l10n.appLockConfirmPin,
    };
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            QalbMark(size: 64, color: q.primary, accent: q.primary),
            const SizedBox(height: QSpace.s6),
            Text(title, style: QType.title.copyWith(color: q.ink)),
            const SizedBox(height: QSpace.s4),
            Semantics(
              liveRegion: true,
              label: l10n.appLockPinProgress(_entered.length),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.symmetric(
                          horizontal: QSpace.s2,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _entered.length ? q.primary : q.surface2,
                          border: Border.all(color: q.line),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 24,
              child: _error == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(top: QSpace.s2),
                      child: Text(
                        _error!,
                        style: QType.caption.copyWith(color: q.urgent),
                      ),
                    ),
            ),
            const Spacer(),
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['', '0', '⌫'],
            ])
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final key in row)
                    Padding(
                      padding: const EdgeInsets.all(QSpace.s2),
                      child: key.isEmpty
                          ? const SizedBox(width: 72, height: 72)
                          : Semantics(
                              button: true,
                              label: key == '⌫' ? l10n.appLockDelete : key,
                              excludeSemantics: true,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  QRadius.full,
                                ),
                                onTap: () => key == '⌫'
                                    ? _onBackspace()
                                    : unawaited(_onDigit(key)),
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: q.surface,
                                    border: Border.all(color: q.line),
                                  ),
                                  child: Center(
                                    child: Text(
                                      key,
                                      style: QType.num_(
                                        QType.title,
                                      ).copyWith(color: q.ink),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                ],
              ),
            const SizedBox(height: QSpace.s4),
            if (widget.mode == LockScreenMode.unlock)
              SignalBuilder(
                builder: (context) => _store.biometricEnabled.value
                    ? QButton(
                        label: l10n.appLockUseBiometric,
                        kind: QButtonKind.ghost,
                        small: true,
                        icon: Icons.fingerprint,
                        onPressed: () => unawaited(
                          _store.unlockWithBiometric(l10n.appLockEnterPin),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            const SizedBox(height: QSpace.s6),
          ],
        ),
      ),
    );
  }
}
