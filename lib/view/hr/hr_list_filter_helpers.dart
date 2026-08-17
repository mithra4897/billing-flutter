import '../../screen.dart';

Widget hrListFilterBox({required Widget child}) {
  return SizedBox(width: 240, child: child);
}

class HrInlineFilterBar extends StatelessWidget {
  const HrInlineFilterBar({
    required this.filterFields,
    required this.onClear,
    this.wrapInCard = true,
    this.header,
    super.key,
  });

  final List<Widget> filterFields;
  final VoidCallback onClear;
  final bool wrapInCard;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) ...[
          header!,
          const SizedBox(height: AppUiConstants.spacingMd),
        ],
        Wrap(
          spacing: AppUiConstants.spacingMd,
          runSpacing: AppUiConstants.spacingMd,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            ...filterFields,
            hrListFilterBox(
              child: AppActionButton(
                icon: Icons.clear_outlined,
                label: 'Clear',
                filled: false,
                onPressed: onClear,
              ),
            ),
          ],
        ),
      ],
    );
    return wrapInCard ? AppSectionCard(child: content) : content;
  }
}

Widget hrListAppliedFiltersCard(BuildContext context, List<String> chips) {
  if (chips.isEmpty) {
    return const SizedBox.shrink();
  }
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
    child: Padding(
      padding: const EdgeInsets.all(AppUiConstants.cardPadding),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: chips
            .map((String chip) => Chip(label: Text(chip)))
            .toList(growable: false),
      ),
    ),
  );
}

String hrDropdownLabel<T>(List<AppDropdownItem<T>> items, T? value) {
  for (final AppDropdownItem<T> item in items) {
    if (item.value == value) {
      return item.label;
    }
  }
  return '';
}
