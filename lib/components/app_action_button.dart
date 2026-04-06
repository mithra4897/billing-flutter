import 'package:flutter/material.dart';

import '../app/constants/app_ui_constants.dart';

class AppActionButton extends StatelessWidget {
  const AppActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final iconWidget = busy
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon);

    if (filled) {
      return FilledButton.icon(
        onPressed: busy ? null : onPressed,
        icon: iconWidget,
        label: Text(label),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: busy ? null : onPressed,
      icon: iconWidget,
      label: Text(label),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
        ),
      ),
    );
  }
}
