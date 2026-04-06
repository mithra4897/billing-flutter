import 'package:flutter/material.dart';

import '../app/constants/app_ui_constants.dart';
import '../app/theme/app_theme_extension.dart';

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppUiConstants.cardPadding),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: appTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: appTheme.cardShadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
