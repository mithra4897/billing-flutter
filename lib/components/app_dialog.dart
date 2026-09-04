import '../screen.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.maxWidth = 920,
    this.maxHeightFactor = 0.88,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final double maxWidth;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    final compact = MediaQuery.sizeOf(context).width < 600;
    final padding = compact ? 16.0 : AppUiConstants.cardPadding;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 24,
        vertical: 20,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: appTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: appTheme.cardShadow.withValues(alpha: 0.9),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  padding / 1.25,
                  padding,
                  8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                      color: appTheme.mutedText,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    padding,
                    padding,
                    MediaQuery.viewInsetsOf(context).bottom + padding,
                  ),
                  child: child,
                ),
              ),
              if (actions != null) ...[
                Divider(
                  height: 1,
                  color: theme.dividerColor.withValues(alpha: 0.2),
                ),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: AppUiConstants.spacingSm,
                      runSpacing: AppUiConstants.spacingSm,
                      children: actions!,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
