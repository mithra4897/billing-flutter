import 'package:flutter/material.dart';

import '../app/constants/app_ui_constants.dart';
import '../app/theme/app_theme_extension.dart';

enum ReportHeaderActionStyle { filled, outlined }

class ReportHeaderActionItem {
  const ReportHeaderActionItem.button({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.style = ReportHeaderActionStyle.filled,
  }) : itemBuilder = null,
       onSelected = null;

  const ReportHeaderActionItem.menu({
    required this.icon,
    required this.label,
    required this.itemBuilder,
    required this.onSelected,
    this.style = ReportHeaderActionStyle.outlined,
  }) : onPressed = null;

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final PopupMenuItemBuilder<dynamic>? itemBuilder;
  final PopupMenuItemSelected<dynamic>? onSelected;
  final ReportHeaderActionStyle style;

  bool get isMenu => itemBuilder != null && onSelected != null;
}

class ReportHeaderActionBar extends StatelessWidget {
  const ReportHeaderActionBar({super.key, required this.actions});

  final List<ReportHeaderActionItem> actions;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions
          .map(
            (ReportHeaderActionItem action) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _ReportHeaderActionControl(
                action: action,
                compact: isMobile,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ReportHeaderActionControl extends StatelessWidget {
  const _ReportHeaderActionControl({
    required this.action,
    required this.compact,
  });

  final ReportHeaderActionItem action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appTheme = theme.extension<AppThemeExtension>()!;
    final isFilled = action.style == ReportHeaderActionStyle.filled;

    final child = Container(
      alignment: Alignment.center,
      constraints: BoxConstraints(
        minWidth: compact ? 44 : 124,
        minHeight: 44,
        maxHeight: 44,
      ),
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 16, vertical: 10),
      decoration: BoxDecoration(
        color: isFilled ? colorScheme.primary : colorScheme.surface,
        borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
        border: isFilled
            ? null
            : Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        boxShadow: isFilled || !compact
            ? [
                BoxShadow(
                  color: appTheme.cardShadow,
                  blurRadius: isFilled ? 10 : 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            action.icon,
            size: 20,
            color: isFilled ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
          if (!compact) ...[
            const SizedBox(width: 8),
            Text(
              action.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isFilled ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    if (action.isMenu) {
      return Tooltip(
        message: action.label,
        child: PopupMenuButton(
          tooltip: action.label,
          onSelected: (value) => action.onSelected?.call(value),
          itemBuilder: action.itemBuilder!,
          child: child,
        ),
      );
    }

    return Tooltip(
      message: action.label,
      child: InkWell(
        onTap: action.onPressed,
        borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
        child: child,
      ),
    );
  }
}
