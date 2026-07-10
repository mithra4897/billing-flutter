import '../screen.dart';

Future<T?> showAppFilterPanel<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  double maxWidth = 920,
}) {
  final mediaQuery = MediaQuery.of(context);
  final horizontalPadding = mediaQuery.size.width < 600 ? 12.0 : 24.0;
  final contentPadding = mediaQuery.size.width < 600
      ? 16.0
      : AppUiConstants.cardPadding;

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close filters',
    barrierColor: Colors.black.withValues(alpha: 0.18),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final appTheme = Theme.of(dialogContext).extension<AppThemeExtension>()!;
      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              20,
              horizontalPadding,
              20,
            ),
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: mediaQuery.size.height * 0.88,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: appTheme.cardBackground,
                    borderRadius: BorderRadius.circular(
                      AppUiConstants.cardRadius,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: appTheme.cardShadow.withValues(alpha: 0.9),
                        blurRadius: 30,
                        offset: const Offset(0, 18),
                      ),
                    ],
                    border: Border.all(
                      color: Theme.of(
                        dialogContext,
                      ).dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      contentPadding,
                      contentPadding,
                      contentPadding,
                      mediaQuery.viewInsets.bottom + contentPadding,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(dialogContext)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              tooltip: 'Close',
                              icon: const Icon(Icons.close),
                              color: appTheme.mutedText,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppUiConstants.spacingMd),
                        builder(dialogContext),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.035),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            alignment: Alignment.topCenter,
            child: child,
          ),
        ),
      );
    },
  );
}
