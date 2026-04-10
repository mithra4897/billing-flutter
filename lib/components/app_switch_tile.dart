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
    return SwitchListTile(
      contentPadding: contentPadding,
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: value,
      onChanged: onChanged,
    );
  }
}
