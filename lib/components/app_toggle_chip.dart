import 'package:flutter/material.dart';

enum AppToggleChipWidthMode { fitContent, fillParent }

class AppToggleChip extends StatelessWidget {
  const AppToggleChip({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.widthMode = AppToggleChipWidthMode.fitContent,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppToggleChipWidthMode widthMode;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8,
        right: widthMode == AppToggleChipWidthMode.fillParent ? 0 : 28,
      ),
      child: Row(
        mainAxisSize: widthMode == AppToggleChipWidthMode.fillParent
            ? MainAxisSize.max
            : MainAxisSize.min,
        children: [
          Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 8),
          if (widthMode == AppToggleChipWidthMode.fillParent)
            Expanded(child: Text(label))
          else
            Text(label),
        ],
      ),
    );

    return widthMode == AppToggleChipWidthMode.fillParent
        ? SizedBox(width: double.infinity, child: content)
        : content;
  }
}
