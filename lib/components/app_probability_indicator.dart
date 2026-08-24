import '../screen.dart';

class AppProbabilityIndicator extends StatelessWidget {
  const AppProbabilityIndicator({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100).toDouble();
    final rounded = clamped.round();
    final color = _colorForValue(context, clamped);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: 'Probability $rounded percent',
      child: SizedBox.square(
        dimension: 44,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            SizedBox.square(
              dimension: 40,
              child: CircularProgressIndicator(
                value: clamped / 100,
                strokeWidth: 4,
                backgroundColor: color.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '$rounded%',
              style: textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForValue(BuildContext context, double value) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>();
    if (value >= 75) {
      return appTheme?.success ?? const Color(0xFF1FA971);
    }
    if (value >= 35) {
      return appTheme?.warning ?? const Color(0xFFE67E22);
    }
    return appTheme?.mutedText ?? const Color(0xFF8A8F98);
  }
}
