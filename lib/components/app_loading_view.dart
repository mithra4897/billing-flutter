import 'package:flutter/material.dart';

import '../app/constants/app_ui_constants.dart';
import '../app/theme/app_theme_extension.dart';

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message = 'Loading...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(AppUiConstants.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: appTheme.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
