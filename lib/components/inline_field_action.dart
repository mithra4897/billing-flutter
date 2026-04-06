import 'package:flutter/material.dart';

class InlineFieldAction extends StatelessWidget {
  const InlineFieldAction({
    super.key,
    required this.field,
    this.onAddNew,
    this.actionIcon = Icons.add,
    this.actionTooltip,
    this.spacing = 8,
    this.actionSize = 44,
  });

  final Widget field;
  final VoidCallback? onAddNew;
  final IconData actionIcon;
  final String? actionTooltip;
  final double spacing;
  final double actionSize;

  @override
  Widget build(BuildContext context) {
    if (onAddNew == null) {
      return field;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: field),
        SizedBox(width: spacing),
        SizedBox(
          width: actionSize,
          height: actionSize,
          child: FilledButton.tonal(
            onPressed: onAddNew,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size(actionSize, actionSize),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Tooltip(
              message: actionTooltip ?? 'Add new',
              child: Icon(actionIcon, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}
