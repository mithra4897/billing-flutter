import 'package:flutter/material.dart';

class AppToggleChip extends StatelessWidget {
  const AppToggleChip({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: value,
      onSelected: onChanged,
      label: Text(label),
    );
  }
}
