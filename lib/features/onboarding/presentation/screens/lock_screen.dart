import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/painters/qalb_mark.dart';
import '../../../../shared/widgets/q_button.dart';
import '../state/app_lock_store.dart';

/// PIN (+ optional biometric) gate. Also reused as the PIN setup screen
/// and, via [LockScreenMode.verify], as the re-auth step before turning the
/// lock off (pops `true` once the PIN or biometric checks out).
enum LockScreenMode { unlock, setup, verify }

/// Keypad sentinel for the delete key (drawn as an icon).
const _backspace = 'del';

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

  /// "Forgot PIN?" verified via the device lock: collect a new PIN. Lives
  /// in the store so leaving the app ends it.
  late bool _resetting =
      widget.mode == LockScreenMode.unlock && _store.pinResetAuthorized.value;
  void Function()? _stopResetWatch;

  /// Repaints the cooldown countdown once a second while throttled.
  Timer? _cooldownTicker;

  bool get _settingPin => widget.mode == LockScreenMode.setup || _resetting;

  @override
  void initState() {
    super.initState();
    if (widget.mode == LockScreenMode.unlock) {
      _stopResetWatch = effect(() {
        final authorized = _store.pinResetAuthorized.value;
        if (authorized == _resetting || !mounted) {
          return;
        }
        setState(() {
          _resetting = authorized;
          _entered = '';
          _firstPin = null;
          _error = null;
        });
      });
    }
    if (widget.mode != LockScreenMode.setup) {
      _syncCooldownTicker();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_biometric());
        }
      });
    }
  }

  bool get _verifying => widget.mode == LockScreenMode.verify;

  /// Unlock: the store flips the gate. Verify: report success to the
  /// caller.
  void _verified() {
    if (_verifying && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _biometric() async {
    if (await _store.unlockWithBiometric(context.l10n.appLockBiometricReason)) {
      _verified();
    }
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    _stopResetWatch?.call();
    super.dispose();
  }

  /// Remaining cooldown, or null when PIN entry is allowed.
  Duration? get _cooldownLeft =>
      _settingPin ? null : _store.cooldownRemaining();

  void _syncCooldownTicker() {
    if (_cooldownLeft == null) {
      _cooldownTicker?.cancel();
      _cooldownTicker = null;
      return;
    }
    _cooldownTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      if (_cooldownLeft == null) {
        _cooldownTicker?.cancel();
        _cooldownTicker = null;
      }
    });
  }

  String _formatCooldown(BuildContext context, Duration left) {
    final seconds = (left.inMilliseconds / 1000).ceil();
    final text =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return LocaleDigits.localize(
      text,
      Localizations.localeOf(context).languageCode,
    );
  }

  Future<void> _forgotPin() async {
    final l10n = context.l10n;
    final result = await _store.authenticateForPinReset(
      l10n.appLockForgotReason,
    );
    if (!mounted) {
      return;
    }
    switch (result) {
      case PinResetAuth.verified:
        break; // _stopResetWatch switches to new-PIN entry.
      case PinResetAuth.noDeviceLock:
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.appLockNoDeviceLockTitle),
            content: Text(l10n.appLockNoDeviceLockBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(MaterialLocalizations.of(context).okButtonLabel),
              ),
            ],
          ),
        );
      case PinResetAuth.failed:
        break;
    }
  }

  Future<bool> _offerBiometric() async {
    final l10n = context.l10n;
    final use = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.appLockBiometricOfferTitle),
        content: Text(l10n.appLockBiometricOfferBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.appLockBiometricSkip),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.appLockBiometricUse),
          ),
        ],
      ),
    );
    return use ?? false;
  }

  Future<void> _onDigit(String digit) async {
    if (_entered.length >= 4 || _cooldownLeft != null) {
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
    switch (_settingPin) {
      case false:
        final ok = await _store.unlockWithPin(_entered);
        if (ok) {
          _verified();
        } else if (mounted) {
          Haptics.heavy();
          setState(() {
            _entered = '';
            _error = l10n.appLockWrongPin;
          });
          _syncCooldownTicker();
        }
      case true:
        if (_firstPin == null) {
          setState(() {
            _firstPin = _entered;
            _entered = '';
          });
        } else if (_firstPin == _entered) {
          if (_resetting) {
            // Unlocking flips the router gate; no navigation needed.
            await _store.resetPin(_entered);
          } else {
            // Biometrics are an explicit opt-in, never switched on silently.
            final biometric =
                await _store.canUseBiometric() &&
                mounted &&
                await _offerBiometric();
            await _store.enable(_entered, biometric: biometric);
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          }
        } else {
          Haptics.heavy();
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
    final title = switch ((_settingPin, _firstPin)) {
      (false, _) => l10n.appLockEnterPin,
      (true, null) => _resetting ? l10n.appLockNewPin : l10n.appLockSetPin,
      (true, _) => l10n.appLockConfirmPin,
    };
    final cooldown = _cooldownLeft;
    final message = cooldown != null
        ? l10n.appLockThrottled(_formatCooldown(context, cooldown))
        : _error;
    return Scaffold(
      // Setup is pushed from Settings: give it a visible way back out.
      appBar: widget.mode == LockScreenMode.unlock ? null : AppBar(),
      body: SafeArea(
        // Spacers spread the gate on tall screens; short ones scroll.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
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
                                  color: i < _entered.length
                                      ? q.primary
                                      : q.surface2,
                                  border: Border.all(color: q.line),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      child: message == null
                          ? null
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(
                                QSpace.s5,
                                QSpace.s2,
                                QSpace.s5,
                                0,
                              ),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  message,
                                  key: const ValueKey('lock-message'),
                                  textAlign: TextAlign.center,
                                  style: QType.caption.copyWith(
                                    color: q.urgent,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const Spacer(),
                    for (final row in const [
                      ['1', '2', '3'],
                      ['4', '5', '6'],
                      ['7', '8', '9'],
                      ['', '0', _backspace],
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
                                      enabled: cooldown == null,
                                      label: key == _backspace
                                          ? l10n.appLockDelete
                                          : context.digits(key),
                                      excludeSemantics: true,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          QRadius.full,
                                        ),
                                        onTap: cooldown != null
                                            ? null
                                            : () => key == _backspace
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
                                            child: key == _backspace
                                                ? Icon(
                                                    Icons.backspace_outlined,
                                                    color: q.ink,
                                                  )
                                                : Text(
                                                    context.digits(key),
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
                    if (!_settingPin)
                      // One row keeps the gate within short screens.
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: QSpace.s2,
                        children: [
                          SignalBuilder(
                            builder: (context) => _store.biometricEnabled.value
                                ? QButton(
                                    label: l10n.appLockUseBiometric,
                                    kind: QButtonKind.ghost,
                                    small: true,
                                    icon: Icons.fingerprint,
                                    onPressed: () => unawaited(_biometric()),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          // Re-auth must prove the PIN (or biometric); a reset
                          // here would bypass that.
                          if (!_verifying)
                            QButton(
                              label: l10n.appLockForgotPin,
                              kind: QButtonKind.ghost,
                              small: true,
                              onPressed: () => unawaited(_forgotPin()),
                            ),
                        ],
                      ),
                    const SizedBox(height: QSpace.s6),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
