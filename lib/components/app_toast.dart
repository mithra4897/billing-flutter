import 'package:flutter/scheduler.dart';

import '../screen.dart';

enum AppToastType { success, warning, error, info }

class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static int _generation = 0;

  static void show(
    String message, {
    BuildContext? context,
    AppToastType? type,
    Duration duration = const Duration(seconds: 3),
  }) {
    final text = message.trim();
    if (text.isEmpty) return;
    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        show(
          text,
          context: context,
          type: type,
          duration: duration,
        );
      });
      return;
    }

    final overlay =
        appNavigatorKey.currentState?.overlay ??
        (context == null
            ? null
            : Overlay.maybeOf(context, rootOverlay: true)) ??
        (Get.overlayContext == null
            ? null
            : Overlay.maybeOf(Get.overlayContext!, rootOverlay: true));
    if (overlay == null) return;
    dismiss();
    final generation = ++_generation;
    final toastType = type ?? _inferType(text);
    _entry = OverlayEntry(
      builder: (context) => _AppToastView(message: text, type: toastType),
    );
    overlay.insert(_entry!);
    Future<void>.delayed(duration, () {
      if (generation == _generation) dismiss();
    });
  }

  static void dismiss() {
    _generation++;
    _entry?.remove();
    _entry = null;
  }

  static AppToastType _inferType(String message) {
    final value = message.toLowerCase();
    if (RegExp(
      r'error|fail|invalid|unable|cannot|denied|required',
    ).hasMatch(value)) {
      return AppToastType.error;
    }
    if (RegExp(r'warning|pending|draft|attention|no active').hasMatch(value)) {
      return AppToastType.warning;
    }
    if (RegExp(
      r'success|saved|created|updated|deleted|completed|imported|exported',
    ).hasMatch(value)) {
      return AppToastType.success;
    }
    return AppToastType.info;
  }
}

class _AppToastView extends StatelessWidget {
  const _AppToastView({required this.message, required this.type});

  final String message;
  final AppToastType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<AppThemeExtension>()!;
    final color = switch (type) {
      AppToastType.success => extension.success,
      AppToastType.warning => extension.warning,
      AppToastType.error => theme.colorScheme.error,
      AppToastType.info => extension.info,
    };
    final icon = switch (type) {
      AppToastType.success => Icons.check_circle_outline,
      AppToastType.warning => Icons.warning_amber_rounded,
      AppToastType.error => Icons.error_outline,
      AppToastType.info => Icons.info_outline,
    };
    return IgnorePointer(
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            margin: const EdgeInsets.all(AppUiConstants.spacingLg),
            padding: const EdgeInsets.symmetric(
              horizontal: AppUiConstants.spacingMd,
              vertical: AppUiConstants.spacingSm,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 16),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: theme.colorScheme.onPrimary),
                const SizedBox(width: AppUiConstants.spacingSm),
                Flexible(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
