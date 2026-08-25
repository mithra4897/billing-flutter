import '../screen.dart';

class AppSwitchTile extends StatelessWidget {
  const AppSwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: AppUiConstants.spacingSm,
    ),
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? subtitle;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    final interactive = onChanged != null;

    return Container(
      constraints: BoxConstraints(minHeight: subtitle == null ? 64 : 80),
      margin: const EdgeInsets.only(
        top: AppUiConstants.spacingXxs,
        bottom: AppUiConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: appTheme.tableBorder),
        color: appTheme.subtleFill,
        borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppUiConstants.fieldRadius),
          onTap: interactive ? () => onChanged!(!value) : null,
          child: Padding(
            padding: contentPadding.add(
              const EdgeInsets.symmetric(vertical: AppUiConstants.spacingSm),
            ),
            child: Center(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, overflow: TextOverflow.ellipsis),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppUiConstants.spacingXxs),
                          Text(subtitle!, style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppUiConstants.spacingSm),
                  Switch(value: value, onChanged: onChanged),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
