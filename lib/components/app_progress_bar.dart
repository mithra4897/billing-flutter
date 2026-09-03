import '../screen.dart';

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.label,
    required this.progress,
    required this.color,
  });

  final String label;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    final progressPercent = (progress * 100).clamp(0, 100).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium,
              ),
            ),
            const SizedBox(width: AppUiConstants.spacingSm),
            Text(
              '${progressPercent.toStringAsFixed(progressPercent == progressPercent.roundToDouble() ? 0 : 1)}%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: appTheme.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(
            AppUiConstants.pillRadius,
          ),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress,
            color: color,
            backgroundColor: color.withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }
}
