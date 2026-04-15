import 'package:flutter/material.dart';

import '../app/constants/app_ui_constants.dart';

class AppSwitchTile extends StatelessWidget {
  const AppSwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: AppUiConstants.spacingSm,
    ),
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? subtitle;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.all(AppUiConstants.spacingXxs),
      padding: EdgeInsets.only(
        left: AppUiConstants.spacingSm,
        right: AppUiConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color:
              theme.inputDecorationTheme.fillColor ??
              theme.dividerColor.withValues(alpha: 0.24),
        ),
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
      ),
      child: SwitchListTile(
        contentPadding: contentPadding,
        title: Text(label, overflow: TextOverflow.ellipsis),
        subtitle: subtitle == null ? null : Text(subtitle!),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
